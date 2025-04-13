import 'dart:async';

import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/permissions.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/constants/meeting.dart';
import 'package:podium/models/jitsi_member.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/services/websocket/incomingMessage.dart';
import 'package:podium/services/websocket/outgoingMessage.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/storage.dart';

class SortTypes {
  static const String recentlyTalked = 'recentlyTalked';
  static const String timeJoined = 'timeJoined';
}

class OutpostCallController extends GetxController {
  final storage = GetStorage();
  // group session id is group id
  final outpostsController = Get.find<OutpostsController>();
  final globalController = Get.find<GlobalController>();
  final outpost = Rxn<OutpostModel>();
  final members = Rx<List<LiveMember>>([]);
  final sortedMembers = Rx<List<LiveMember>>([]);
  final talkingUsers = Rx<List<LiveMember>>([]);
  final reactionsMap = Rx<Map<String, Map<OutgoingMessageTypeEnums, int>>>({
    // "0x673f34ad366c81bc5cd0e6bc2a5a1afe932dbf35": {
    //   OutgoingMessageTypeEnums.cheer: 2,
    //   OutgoingMessageTypeEnums.boo: 1,
    //   OutgoingMessageTypeEnums.like: 1,
    //   OutgoingMessageTypeEnums.dislike: 1,
    // },
  });
  final haveOngoingCall = false.obs;
  final jitsiMembers = Rx<List<JitsiMember>>([]);
  final searchedValueInMeet = Rx<String>('');
  final sortType = Rx<String>(SortTypes.recentlyTalked);
  final canTalk = false.obs;
  final keysMap = Rx<Map<String, GlobalKey>>({});

  StreamSubscription<bool>? triggerLiveDataFetchListener;
  StreamSubscription<List<LiveMember>>? sortedMembersListener;
  StreamSubscription<List<LiveMember>>? membersListener;
  StreamSubscription<OutpostModel?>? outpostListener;
  StreamSubscription<int>? tickerListener;

  bool gotMembersOnce = false;
  @override
  void onInit() {
    super.onInit();
    sortType.value = storage.read(StorageKeys.ongoingCallSortType) ??
        SortTypes.recentlyTalked;

    tickerListener = globalController.ticker.listen((d) {
      handleTimerTick();
    });
    sortedMembersListener = sortedMembers.listen((listOfSortedUsers) {
      final talking = listOfSortedUsers
          .where((member) => member.is_speaking == true)
          .toList();
      talkingUsers.value = talking;
    });
    membersListener = members.listen((listOfUsers) {
      final sorted = sortMembers(members: listOfUsers);
      if (!gotMembersOnce) {
        _updateReactionsMap(listOfUsers);
        gotMembersOnce = true;
      }
      sortedMembers.value = sorted;
    });
    outpostListener = outpost.listen((activeOutpost) async {
      members.value = [];
      if (activeOutpost != null) {
        // NOTE: this should be the only place where this is used to join the outpost when the user is in the outpost call screen
        // NOTE: otherwise there will be multiple join requests, and websocket server only reacts to the first one
        sendOutpostEvent(
          outpostId: activeOutpost.uuid,
          eventType: OutgoingMessageTypeEnums.join,
        );
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
    gotMembersOnce = false;
    reactionsMap.value = {};
    membersListener?.cancel();
    sortedMembersListener?.cancel();
    outpostListener?.cancel();
    tickerListener?.cancel();
    triggerLiveDataFetchListener?.cancel();
  }

  /////////////////////////////////////////////////////////////

  @override
  void dispose() {
    super.dispose();
  }

  ///////////////////////////////////////////////////////////////

  void updateReactionsMapByWsEvent(IncomingMessage incomingMessage) {
    final reactionTypes = {
      IncomingMessageType.userLiked: OutgoingMessageTypeEnums.like,
      IncomingMessageType.userDisliked: OutgoingMessageTypeEnums.dislike,
      IncomingMessageType.userCheered: OutgoingMessageTypeEnums.cheer,
      IncomingMessageType.userBooed: OutgoingMessageTypeEnums.boo,
    };

    final reactionType = reactionTypes[incomingMessage.name];
    if (reactionType == null) return;

    final userAddress = incomingMessage.data.react_to_user_address;
    if (userAddress == null) return;
    if (reactionsMap.value[userAddress] == null) {
      reactionsMap.value[userAddress] = {};
    }
    reactionsMap.value[userAddress]![reactionType] =
        (reactionsMap.value[userAddress]![reactionType] ?? 0) + 1;

    reactionsMap.refresh();
  }

  void _updateReactionsMap(List<LiveMember> listOfUsers) {
    final Map<String, Map<OutgoingMessageTypeEnums, int>> tmp = {};

    final feedbackTypes = {
      OutgoingMessageTypeEnums.like: OutgoingMessageTypeEnums.like,
      OutgoingMessageTypeEnums.dislike: OutgoingMessageTypeEnums.dislike,
    };

    final reactionTypes = {
      OutgoingMessageTypeEnums.cheer: OutgoingMessageTypeEnums.cheer,
      OutgoingMessageTypeEnums.boo: OutgoingMessageTypeEnums.boo,
    };

    for (final user in listOfUsers) {
      for (final FeedbackModel feedback in user.feedbacks) {
        final reactionType = feedbackTypes[feedback.feedback_type];
        if (reactionType != null) {
          _updateReactionCount(tmp, feedback.user_address, reactionType);
        }
      }

      // Process reactions (cheers and boos)
      for (final UserReaction reaction in user.reactions) {
        final reactionType = reactionTypes[reaction.reaction_type];
        if (reactionType != null) {
          _updateReactionCount(tmp, reaction.user_address, reactionType);
        }
      }
    }
    reactionsMap.value = tmp;
  }

  void _updateReactionCount(
    Map<String, Map<OutgoingMessageTypeEnums, int>> reactions,
    String userAddress,
    OutgoingMessageTypeEnums type,
  ) {
    if (reactions[userAddress] == null) {
      reactions[userAddress] = {};
    }
    reactions[userAddress]![type] = (reactions[userAddress]![type] ?? 0) + 1;
  }

  void handleTimerTick() {
    final talkingMembers =
        members.value.where((member) => member.is_speaking == true);
    talkingMembers.forEach((member) {
      final userIndex = members.value.indexWhere((m) => m.uuid == member.uuid);
      if (member.remaining_time > 0) {
        members.value[userIndex].remaining_time--;
        members.refresh();
      }
    });
  }

  void fetchLiveData() async {
    if (outpost.value == null) return;

    final liveData =
        await HttpApis.podium.getLatestLiveData(outpostId: outpost.value!.uuid);
    if (liveData != null) {
      final tmp = liveData.members;
      tmp.asMap().forEach((index, element) {
        if (element.last_speaked_at_timestamp == null) {
          element.last_speaked_at_timestamp = -1 * (index);
        }
      });
      members.value = tmp.where((member) => member.is_present == true).toList();
    }
  }

  void updateUserIsTalking({required String address, required bool isTalking}) {
    final membersList = [...members.value];
    final memberIndex = membersList.indexWhere((m) => m.address == address);
    if (memberIndex != -1) {
      membersList[memberIndex].last_speaked_at_timestamp =
          DateTime.now().millisecondsSinceEpoch ~/ 1000;
      membersList[memberIndex].is_speaking = isTalking;
      members.value = membersList;
    }
  }

  void updateUserTime({required String address, required int newTime}) {
    final membersList = [...members.value];
    final memberIndex = membersList.indexWhere((m) => m.address == address);
    if (memberIndex != -1) {
      membersList[memberIndex].remaining_time = newTime;
      members.value = membersList;
    }
  }

  List<LiveMember> sortMembers({required List<LiveMember> members}) {
    final sorted = [...members];
    if (sortType.value == SortTypes.recentlyTalked) {
      sorted.sortedByDescending((a) => a.last_speaked_at_timestamp ?? 0);
    } else if (sortType.value == SortTypes.timeJoined) {
      sorted.sortedByDescending((a) => a.last_speaked_at_timestamp ?? 0);
    }
    return sorted;
  }

  cleanupAfterCall() {
    haveOngoingCall.value = false;
    jitsiMembers.value = [];
    jitsiMeet.hangUp();
    members.value = [];
    searchedValueInMeet.value = '';
    final outpostId = outpost.value?.uuid;
    reactionsMap.value = {};
    if (outpostId != null) {
      sendOutpostEvent(
        outpostId: outpostId,
        eventType: OutgoingMessageTypeEnums.leave,
      );
    }
  }

  Future<void> startCall(
      {required OutpostModel outpostToJoin,
      GroupAccesses? accessOverRides}) async {
    final globalController = Get.find<GlobalController>();
    final iAmAllowedToSpeak = accessOverRides != null
        ? accessOverRides.canSpeak
        : canISpeakWithoutTicket(outpost: outpostToJoin);
    canTalk.value = iAmAllowedToSpeak;
    bool hasMicAccess = false;
    if (iAmAllowedToSpeak) {
      hasMicAccess = await getPermission(Permission.microphone);
      if (!hasMicAccess) {
        Toast.warning(
          title: 'Microphone access required',
          message: 'Please allow microphone access to speak',
        );
        canTalk.value = false;
      }
    }
    final hasNotificationPermission =
        await getPermission(Permission.notification);
    l.d("notifications allowed: $hasNotificationPermission");

    final myUser = globalController.myUserInfo.value!;

    if ((myUser.external_wallet_address == '' ||
            globalController.connectedWalletAddress == '') &&
        myUser.defaultWalletAddress == '') {
      Toast.warning(
        title: 'Wallet required',
        message: 'Please connect a wallet to join',
      );
      globalController.connectToWallet(
        afterConnection: () {
          startCall(
              outpostToJoin: outpostToJoin, accessOverRides: accessOverRides);
        },
      );
      return;
    }
    outpost.value = outpostToJoin;
    var options = MeetingConstants.buildMeetOptions(
      outpost: outpostToJoin,
      myUser: myUser,
      allowedToSpeak: iAmAllowedToSpeak,
    );
    try {
      await jitsiMeet.join(
        options,
        jitsiListeners(
          outpost: outpostToJoin,
        ),
      );
      // sendOutpostEvent(
      //   outpostId: outpost.value!.uuid,
      //   eventType: OutgoingMessageTypeEnums.join,
      // );

      analytics.logEvent(
        name: 'joined_group_call',
        parameters: {
          'outpost_id': outpostToJoin.uuid,
          'outpost_name': outpostToJoin.name,
          'user_id': myUser.uuid,
        },
      );
    } catch (e) {
      l.f(e.toString());
    }
  }

  runHome() async {
    await Navigate.to(
      route: Routes.HOME,
      type: NavigationTypes.offAllNamed,
    );
    cleanupAfterCall();
  }
}

bool canISpeakWithoutTicket({required OutpostModel outpost}) {
  final iAmTheCreator = outpost.creator_user_uuid == myId;
  if (iAmTheCreator) return true;
  if (outpost.speak_type == FreeOutpostSpeakerTypes.invitees) {
    // check if I am invited and am invited to speak
    final invitedMember = (outpost.invites ?? [])
        .firstWhereOrNull((element) => element.invitee_uuid == myId);
    if (invitedMember != null && invitedMember.can_speak == true) return true;
    return false;
  }

  final iAmAllowedToSpeak =
      outpost.speak_type == FreeOutpostSpeakerTypes.everyone;

  return iAmAllowedToSpeak;
}
