import 'dart:async';

import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/permissions.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/constants/meeting.dart';
import 'package:podium/models/jitsi_member.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/services/toast/toast.dart';
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
  final groupsController = Get.find<OutpostsController>();
  final globalController = Get.find<GlobalController>();
  final outpost = Rxn<OutpostModel>();
  final members = Rx<List<LiveMember>>([]);
  final sortedMembers = Rx<List<LiveMember>>([]);
  final talkingUsers = Rx<List<LiveMember>>([]);
  final haveOngoingCall = false.obs;
  final jitsiMembers = Rx<List<JitsiMember>>([]);
  final searchedValueInMeet = Rx<String>('');
  final sortType = Rx<String>(SortTypes.recentlyTalked);
  final canTalk = false.obs;
  final keysMap = Rx<Map<String, GlobalKey>>({});

  // presence channel
  ably.RealtimeChannel? presenceChannel = null;

  StreamSubscription<List<LiveMember>>? sortedMembersListener;
  StreamSubscription<List<LiveMember>>? membersListener;
  StreamSubscription<OutpostModel?>? outpostListener;
  StreamSubscription<int>? tickerListener;

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
      sortedMembers.value = sorted;
    });
    outpostListener = outpost.listen((activeOutpost) async {
      members.value = [];
      if (activeOutpost != null) {
        fetchLiveData(alsoJoin: true);
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
    membersListener?.cancel();
    sortedMembersListener?.cancel();
    outpostListener?.cancel();
    tickerListener?.cancel();
  }

  /////////////////////////////////////////////////////////////

  @override
  void dispose() {
    super.dispose();
  }

  ///////////////////////////////////////////////////////////////

  handleTimerTick() {
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

  fetchLiveData({bool? alsoJoin}) async {
    if (outpost.value == null) return;
    final liveData = await HttpApis.podium
        .getLatestLiveData(outpostId: outpost.value!.uuid, alsoJoin: alsoJoin);
    if (liveData != null) {
      members.value = liveData.members
          .where((member) => member.is_present == true)
          .toList();
    }
  }

  updateUserIsTalking({required String address, required bool isTalking}) {
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
      membersList[memberIndex].last_speaked_at_timestamp =
          DateTime.now().millisecondsSinceEpoch ~/ 1000;
      membersList[memberIndex].remaining_time = newTime;
      members.value = membersList;
    }
  }

  List<LiveMember> sortMembers({required List<LiveMember> members}) {
    final sorted = [...members];
    if (sortType.value == SortTypes.recentlyTalked) {
      sorted.sort((a, b) {
        return (b.last_speaked_at_timestamp ?? (-1 * b.remaining_time))
            .compareTo(a.last_speaked_at_timestamp ?? (-1 * a.remaining_time));
      });
    } else if (sortType.value == SortTypes.timeJoined) {
      sorted.sort((a, b) {
        return (b.last_speaked_at_timestamp ?? (-1 * b.remaining_time))
            .compareTo(a.last_speaked_at_timestamp ?? (-1 * a.remaining_time));
      });
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
    if (outpostId != null) {
      sendOutpostEvent(
        outpostId: outpostId,
        eventType: OutgoingMessageTypeEnums.leave,
      );
      final userId = myId;
      setIsUserPresentInSession(
        groupId: outpostId,
        userId: myId,
        isPresent: false,
      );
      setIsTalkingInSession(
        sessionId: outpostId,
        userId: userId,
        isTalking: false,
      );
    }
  }

  startCall(
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
