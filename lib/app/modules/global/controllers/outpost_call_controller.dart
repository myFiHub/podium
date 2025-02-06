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
import 'package:podium/models/firebase_session_model.dart';
import 'package:podium/models/jitsi_member.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/services/toast/toast.dart';
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
  final members = Rx<List<FirebaseSessionMember>>([]);
  final sortedMembers = Rx<List<FirebaseSessionMember>>([]);
  final haveOngoingCall = false.obs;
  final jitsiMembers = Rx<List<JitsiMember>>([]);
  final talkingMembers = Rx<List<FirebaseSessionMember>>([]);
  final searchedValueInMeet = Rx<String>('');
  final sortType = Rx<String>(SortTypes.recentlyTalked);
  final canTalk = false.obs;
  final keysMap = Rx<Map<String, GlobalKey>>({});
  StreamSubscription<DatabaseEvent>? membersListener;

  // presence channel
  ably.RealtimeChannel? presenceChannel = null;

  @override
  void onInit() {
    super.onInit();
    sortType.value = storage.read(StorageKeys.ongoingCallSortType) ??
        SortTypes.recentlyTalked;
    // TODO: add taking users in outposts map
    // groupsController.takingUsersInGroupsMap.listen((takingUsersInGroupsMap) {
    //   if (group.value != null) {
    //     final groupId = group.value!.id;
    //     final takingUsers = takingUsersInGroupsMap[groupId];
    //     if (takingUsers != null) {
    //       final takingUserIds = takingUsers.map((e) => e).toList();
    //       updateTalkingMembers(ids: takingUserIds);
    //     }
    //   }
    // });

    outpost.listen((activeOutpost) async {
      members.value = [];
      if (activeOutpost != null) {
        // TODO: add present users in outposts map
        // final currentPresentMembers =
        //     groupsController.presentUsersInGroupsMap.value[activeGroup.id];
        // if (currentPresentMembers != null) {
        //   await _updateByPresentMembers(
        //     groupId: activeGroup.id,
        //     presentMembers: currentPresentMembers,
        //   );
        // }
        // groupsController.presentUsersInGroupsMap.listen(
        //   (data) async {
        //     final presentMembers = data[activeGroup.id];
        //     if (presentMembers != null) {
        //       await _updateByPresentMembers(
        //         groupId: activeGroup.id,
        //         presentMembers: presentMembers,
        //       );
        //     }
        //   },
        // );
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
  }

  /////////////////////////////////////////////////////////////

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _updateByPresentMembers(
      {required String groupId, required List<String> presentMembers}) async {
    if (presentMembers.length != members.value.length) {
      final remoteMembers = await getSessionMembers(
        sessionId: groupId,
      );
      final List<FirebaseSessionMember> tmp = [];
      final membersList = remoteMembers.values.toList();
      membersList.forEach((member) {
        if (presentMembers.contains(member.id)) {
          tmp.add(FirebaseSessionMember(
            id: member.id,
            name: member.name,
            avatar: member.avatar,
            remainingTalkTime: member.remainingTalkTime,
            initialTalkTime: member.initialTalkTime,
            isMuted: member.isMuted,
            present: member.present,
            isTalking: member.isTalking,
            startedToTalkAt: member.startedToTalkAt,
            timeJoined: member.timeJoined,
          ));
        }
      });
      final sorted = sortMembers(members: tmp);
      sortedMembers.value = sorted;
    }
  }
  ///////////////////////////////////////////////////////////////

  addMemberToListIfItDoesntAlreadyExist({required String id}) async {
    // TODO: add member to list if it doesnt already exist
    // final newMember =
    //     await getSessionMember(groupId: outpost.value!.uuid, userId: id);
    // if (newMember != null) {
    //   final member = FirebaseSessionMember(
    //     id: newMember.id,
    //     name: newMember.name,
    //     avatar: newMember.avatar,
    //     remainingTalkTime: newMember.remainingTalkTime,
    //     initialTalkTime: newMember.initialTalkTime,
    //     isMuted: newMember.isMuted,
    //     present: newMember.present,
    //     isTalking: newMember.isTalking,
    //     startedToTalkAt: newMember.startedToTalkAt,
    //     timeJoined: newMember.timeJoined,
    //   );
    //   //  add if it doesnt already exist and sort
    //   if (!members.value.any((element) => element.id == newMember.id)) {
    //     members.value.add(member);
    //     final sorted = sortMembers(members: members.value);
    //     sortedMembers.value = sorted;
    //   }
    // }
  }

  removeMemberFromListIfItExists({required String id}) {
    members.value.removeWhere((element) => element.id == id);
    final sorted = sortMembers(members: members.value);
    sortedMembers.value = sorted;
  }

  setSortedMembers({required List<FirebaseSessionMember> members}) {
    final sorted = sortMembers(members: members);
    sortedMembers.value = sorted;
  }

  updateTalkingMembers({required List<String> ids}) {
    final talkingMembersList = members.value.where((element) {
      return ids.contains(element.id);
    }).toList();

    // put talking talkingMembersList at start of the sortedMembers
    // forEach talking member, remove from sortedMembers and add to the start
    // of the list
    final sorted = [...sortedMembers.value];
    talkingMembersList.forEach((talkingMember) {
      sorted.removeWhere((element) => element.id == talkingMember.id);
      sorted.insert(0, talkingMember);
    });
    talkingMembers.value = talkingMembersList;
    // log.d("talking members: ${talkingMembersList.map((e) => e.id).toList()}");
    // final sortedIds = sorted.map((e) => e.id).toList();
    // log.d("sorted members: $sortedIds");
    sortedMembers.value = sorted;
  }

  List<FirebaseSessionMember> sortMembers(
      {required List<FirebaseSessionMember> members}) {
    final sorted = [...members];
    if (sortType.value == SortTypes.recentlyTalked) {
      sorted.sort((a, b) {
        return b.startedToTalkAt.compareTo(a.startedToTalkAt);
      });
    } else if (sortType.value == SortTypes.timeJoined) {
      sorted.sort((a, b) {
        return b.timeJoined.compareTo(a.timeJoined);
      });
    }
    return sorted;
  }

  cleanupAfterCall() {
    haveOngoingCall.value = false;
    jitsiMembers.value = [];
    jitsiMeet.hangUp();
    members.value = [];
    talkingMembers.value = [];
    searchedValueInMeet.value = '';
    final outpostId = outpost.value?.uuid;
    if (outpostId != null) {
      sendGroupPeresenceEvent(groupId: outpostId, eventName: eventNames.leave);
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
