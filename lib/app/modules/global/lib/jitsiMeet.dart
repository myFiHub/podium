import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/ongoingGroupCall/controllers/ongoing_group_call_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/jitsi_member.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';

final jitsiMeet = JitsiMeet();
const MethodChannel jitsiMethodChannel = MethodChannel('jitsi_meet_wrapper');

JitsiMeetEventListener jitsiListeners({required FirebaseGroup group}) {
  Get.put<OngoingGroupCallController>(OngoingGroupCallController());
  final groupCallController = Get.find<GroupCallController>();
  final globalController = Get.find<GlobalController>();
  return JitsiMeetEventListener(
    conferenceJoined: (url) async {
      Navigate.to(
        route: Routes.ONGOING_GROUP_CALL,
        type: NavigationTypes.toNamed,
      );
      final myUserId = globalController.currentUserInfo.value!.id;
      final groupCreator = groupCallController.group.value!.creator.id;
      final iAmCreator = groupCreator == myUserId;
      if (group.creatorJoined != true && iAmCreator) {
        await groupCallController.setCreatorJoinedToTrue(groupId: group.id);
      }
      groupCallController.haveOngoingCall.value = true;
      groupCallController.setIsUserPresentInSession(
        groupId: groupCallController.group.value!.id,
        userId: globalController.currentUserInfo.value!.id,
        isPresent: true,
      );
      groupCallController.handleGroupJoined(group);

      await Future.delayed(Duration(seconds: 3));
      await jitsiMeet.retrieveParticipantsInfo();

      log.d("conferenceJoined: url: $url");
    },
    participantJoined: (email, name, role, participantId) {
      log.d(
        "participantJoined: email: $email, name: $name, role: $role, "
        "participantId: $participantId",
      );
    },
    participantLeft: (p) {
      log.d("participantLeft: $p");
    },
    audioMutedChanged: (muted) {
      if (Get.isRegistered<OngoingGroupCallController>()) {
        Get.find<OngoingGroupCallController>().audioMuteChanged(
          muted: muted,
        );
      }
    },
    videoMutedChanged: (muted) {
      log.d("videoMutedChanged: $muted");
    },
    conferenceTerminated: (url, error) {
      log.f("conferenceTerminated: url: $url, error: $error");
      Navigate.to(
        route: Routes.HOME,
        type: NavigationTypes.offNamed,
      );

      groupCallController.setIsUserPresentInSession(
        groupId: groupCallController.group.value!.id,
        userId: globalController.currentUserInfo.value!.id,
        isPresent: false,
      );
      groupCallController.cleanupAfterCall();
      if (Get.isRegistered<OngoingGroupCallController>()) {
        Get.delete<OngoingGroupCallController>();
      }
    },
    participantsInfoRetrieved: (participantsInfo) {
      try {
        final members =
            convertJitsiMembersResponseToReadableJson(participantsInfo);
        final OngoingGroupCallController ongoingGroupCallController =
            Get.find<OngoingGroupCallController>();
        groupCallController.jitsiMembers.value = members;
        ongoingGroupCallController.jitsiMembers.value = members;
      } catch (e) {
        log.e("participantsInfoRetrieved: $e");
      }
    },
    readyToClose: () {
      log.d("readyToClose");
    },
    like: (email, participantId) async {
      final OngoingGroupCallController ongoingGroupCallController =
          Get.find<OngoingGroupCallController>();
      final user = await ongoingGroupCallController.getUserByEmail(email!);
      if (user != null) {
        ongoingGroupCallController.onLikeClicked(user.id);
      }
    },
    dislike: (email, participantId) async {
      final OngoingGroupCallController ongoingGroupCallController =
          Get.find<OngoingGroupCallController>();
      final user = await ongoingGroupCallController.getUserByEmail(email!);
      if (user != null) {
        ongoingGroupCallController.onDislikeClicked(user.id);
      }
    },
    cheer: (email, participantId) async {
      final OngoingGroupCallController ongoingGroupCallController =
          Get.find<OngoingGroupCallController>();
      final user = await ongoingGroupCallController.getUserByEmail(email!);
      if (user != null) {
        ongoingGroupCallController.cheerBoo(
          userId: user.id,
          cheer: true,
          fromMeetPage: true,
        );
      }
    },
    boo: (email, participantId) async {
      final OngoingGroupCallController ongoingGroupCallController =
          Get.find<OngoingGroupCallController>();
      final user = await ongoingGroupCallController.getUserByEmail(email!);
      if (user != null) {
        ongoingGroupCallController.cheerBoo(
          userId: user.id,
          cheer: false,
          fromMeetPage: true,
        );
      }
    },
  );
}
