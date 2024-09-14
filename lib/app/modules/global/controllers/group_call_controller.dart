import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/mixins/permissions.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/constants/meeting.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/firebase_session_model.dart';
import 'package:podium/models/jitsi_member.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/storage.dart';

class SortTypes {
  static const String recentlyTalked = 'recentlyTalked';
  static const String timeJoined = 'timeJoined';
}

class GroupCallController extends GetxController
    with FireBaseUtils, PermissionUtils {
  final storage = GetStorage();
  // group session id is group id
  final groupsController = Get.find<GroupsController>();
  final globalController = Get.find<GlobalController>();
  final group = Rxn<FirebaseGroup>();
  final members = Rx<List<FirebaseSessionMember>>([]);
  final sortedMembers = Rx<List<FirebaseSessionMember>>([]);
  final haveOngoingCall = false.obs;
  final jitsiMembers = Rx<List<JitsiMember>>([]);
  final talkingMembers = Rx<List<FirebaseSessionMember>>([]);
  final sortType = Rx<String>(SortTypes.recentlyTalked);

  @override
  void onInit() {
    sortType.value = storage.read(StorageKeys.ongoingCallSortType) ??
        SortTypes.recentlyTalked;
    super.onInit();
    group.listen((activeGroup) {
      members.value = [];
      if (activeGroup != null) {
        listenToGroupMembers(
          groupId: activeGroup.id,
          onData: (data) async {
            if (data.snapshot.value != null) {
              final membersListFromStream =
                  (data.snapshot.value as List<dynamic>).cast<String>();
              final previousUniqueMembers = members.value.map((e) => e.id);
              final newUniqueMembers = membersListFromStream.map((e) => e);
              if (previousUniqueMembers.length != newUniqueMembers.length) {
                await refetchSessionMembers();
              }
            }
          },
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
  }

  /////////////////////////////////////////////////////////////

  @override
  void dispose() {
    super.dispose();
  }

  ///////////////////////////////////////////////////////////////

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
    log.d("talking members: ${talkingMembersList.map((e) => e.id).toList()}");
    final sortedIds = sorted.map((e) => e.id).toList();
    log.d("sorted members: $sortedIds");
    sortedMembers.value = sorted;
  }

  refetchSessionMembers() async {
    if (group.value == null) return;
    final databaseRef = FirebaseDatabase.instance.ref(
        FireBaseConstants.sessionsRef +
            group.value!.id +
            '/${FirebaseSession.membersKey}');
    final snapshot = await databaseRef.get();
    final snapshotMembers = snapshot.value as dynamic;
    final membersList = <FirebaseSessionMember>[];
    if (snapshotMembers != null) {
      snapshotMembers.forEach((key, value) {
        final member = FirebaseSessionMember(
          id: key,
          name: value[FirebaseSessionMember.nameKey],
          avatar: value[FirebaseSessionMember.avatarKey],
          isMuted: value[FirebaseSessionMember.isMutedKey],
          initialTalkTime: value[FirebaseSessionMember.initialTalkTimeKey],
          present: value[FirebaseSessionMember.presentKey],
          remainingTalkTime: value[FirebaseSessionMember.remainingTalkTimeKey],
          isTalking: value[FirebaseSessionMember.isTalkingKey] ?? false,
          startedToTalkAt: value[FirebaseSessionMember.startedToTalkAtKey] ?? 0,
          timeJoined: value[FirebaseSessionMember.timeJoinedKey] ?? 0,
        );
        membersList.add(member);
      });
    }

    members.value = membersList;
// sort the members based on selected sort type
    final sorted = sortMembers(
      members: membersList,
    );
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
    final groupId = group.value?.id;
    if (groupId != null) {
      final userId = globalController.currentUserInfo.value!.id;
      setIsUserPresentInSession(
        groupId: groupId,
        userId: globalController.currentUserInfo.value!.id,
        isPresent: false,
      );
      setIsTalkingInSession(
        sessionId: groupId,
        userId: userId,
        isTalking: false,
      );
    }
  }

  startCall({required FirebaseGroup groupToJoin}) async {
    final globalController = Get.find<GlobalController>();
    final iAmAllowedToSpeak = canISpeak(group: groupToJoin);
    bool hasMicAccess = false;
    if (iAmAllowedToSpeak) {
      hasMicAccess = await getPermission(Permission.microphone);
      if (!hasMicAccess) {
        Get.snackbar(
          "warning",
          "mic permission is required in order to join the call",
          colorText: Colors.orange,
        );
      }
    }
    final hasNotificationPermission =
        await getPermission(Permission.notification);
    log.d("notifications allowed: $hasNotificationPermission");

    String? particleWalletAddress;
    final myUser = globalController.currentUserInfo.value!;
    if (globalController.particleAuthUserInfo.value != null) {
      final particleUser = globalController.particleAuthUserInfo.value;
      if (particleUser != null) {
        particleWalletAddress = particleUser.wallets?[0]?.publicAddress;
      }
    }

    if ((myUser.localWalletAddress == '' ||
            globalController.connectedWalletAddress == '') &&
        particleWalletAddress == null) {
      Get.snackbar(
        "Wallet connection required",
        "Please connect your wallet first",
        colorText: ColorName.white,
      );
      globalController.connectToWallet(
        afterConnection: () {
          startCall(groupToJoin: groupToJoin);
        },
      );
      return;
    }
    group.value = groupToJoin;
    var options = MeetingConstants.buildMeetOptions(
      group: groupToJoin,
      myUser: myUser,
      allowedToSpeak: iAmAllowedToSpeak,
    );
    try {
      await jitsiMeet.join(
          options,
          jitsiListeners(
            group: groupToJoin,
          ));
    } catch (e) {
      log.f(e.toString());
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

bool canISpeak({required FirebaseGroup group}) {
  final globalController = Get.find<GlobalController>();
  final myId = globalController.currentUserInfo.value!.id;
  final iAmTheCreator = group.creator.id == myId;
  if (iAmTheCreator) return true;
  if (group.speakerType == RoomSpeakerTypes.invitees) {
    // check if I am invited and am invited to speak
    final invitedMember = group.invitedMembers[myId];
    if (invitedMember != null && invitedMember.invitedToSpeak) return true;
    return false;
  }

  final iAmAllowedToSpeak = group.speakerType == null ||
      group.speakerType == RoomSpeakerTypes.everyone;
  return iAmAllowedToSpeak;
}
