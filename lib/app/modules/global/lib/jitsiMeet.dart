import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/ongoingGroupCall/controllers/ongoing_group_call_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/models/jitsi_member.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';

final jitsiMeet = JitsiMeet();
const MethodChannel jitsiMethodChannel = MethodChannel('jitsi_meet_wrapper');

final jitsiListeners = JitsiMeetEventListener(
  conferenceJoined: (url) async {
    Get.put<OngoingGroupCallController>(OngoingGroupCallController());
    final groupCallController = Get.find<GroupCallController>();
    final globalController = Get.find<GlobalController>();
    Navigate.to(
      route: Routes.ONGOING_GROUP_CALL,
      type: NavigationTypes.toNamed,
    );

    groupCallController.haveOngoingCall.value = true;
    groupCallController.setIsUserPresentInSession(
      groupId: groupCallController.group.value!.id,
      userId: globalController.currentUserInfo.value!.id,
      isPresent: true,
    );

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
    if (muted) {
      if (Get.isRegistered<OngoingGroupCallController>()) {
        final ongoingGroupCallController =
            Get.find<OngoingGroupCallController>();
        ongoingGroupCallController.stopTheTimer();
        ongoingGroupCallController.amIMuted.value = true;
      }
    } else {
      if (Get.isRegistered<OngoingGroupCallController>()) {
        final ongoingGroupCallController =
            Get.find<OngoingGroupCallController>();
        final myUserId = Get.find<GlobalController>().currentUserInfo.value!.id;
        final groupCreator =
            Get.find<GroupCallController>().group.value!.creator.id;
        final remainingTime = ongoingGroupCallController.remainingTimeTimer;
        if (remainingTime <= 0 && myUserId != groupCreator) {
          Get.snackbar(
            "You have run out of time",
            "",
            colorText: Colors.red,
          );
          jitsiMeet.setAudioMuted(true);
          return;
        }
        ongoingGroupCallController.amIMuted.value = false;
        ongoingGroupCallController.startTheTimer();
      }
    }
    log.d("audioMutedChanged: $muted");
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

    final groupCallController = Get.find<GroupCallController>();
    final globalController = Get.find<GlobalController>();
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
      final groupCallController = Get.find<GroupCallController>();
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
  like: (email, participantId) {
    log.d("like: email: $email, participantId: $participantId");
  },
  dislike: (email, participantId) {
    log.d("dislike: email: $email, participantId: $participantId");
  },
  cheer: (email, participantId) {
    log.d("cheer: email: $email, participantId: $participantId");
  },
  boo: (email, participantId) {
    log.d("boo: email: $email, participantId: $participantId");
  },
);
