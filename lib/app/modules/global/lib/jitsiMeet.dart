import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';

final jitsiMeet = JitsiMeet();
const MethodChannel jitsiMethodChannel = MethodChannel('jitsi_meet_wrapper');

JitsiMeetEventListener jitsiListeners({required OutpostModel outpost}) {
  Get.put<OngoingOutpostCallController>(OngoingOutpostCallController());
  final groupCallController = Get.find<OutpostCallController>();
  return JitsiMeetEventListener(
    conferenceJoined: (url) async {
      if (Platform.isIOS) {
        // jitsiMeet.enterPiP();
      }
      Navigate.to(
        route: Routes.ONGOING_OUTPOST_CALL,
        type: NavigationTypes.toNamed,
      );
      final myUserId = myId;
      final groupCreator = outpost.creator_user_uuid;
      final iAmCreator = groupCreator == myUserId;
      if (outpost.creator_joined != true && iAmCreator) {
        await HttpApis.podium.setCreatorJoinedToTrue(outpost.uuid);
      }
      groupCallController.haveOngoingCall.value = true;

      await Future.delayed(const Duration(seconds: 3));
      sendGroupPeresenceEvent(
          groupId: outpost.uuid, eventName: eventNames.enter);

      l.d("conferenceJoined: url: $url");
    },
    participantJoined: (email, name, role, participantId) {
      l.d(
        "participantJoined: email: $email, name: $name, role: $role, "
        "participantId: $participantId",
      );
    },
    participantLeft: (p) {
      l.d("participantLeft: $p");
    },
    audioMutedChanged: (muted) {
      if (Get.isRegistered<OngoingOutpostCallController>()) {
        Get.find<OngoingOutpostCallController>().audioMuteChanged(
          muted: muted,
        );
      }
    },
    videoMutedChanged: (muted) {
      l.d("videoMutedChanged: $muted");
    },
    conferenceTerminated: (url, error) {
      l.f("conferenceTerminated: url: $url, error: $error");
    },
    participantsInfoRetrieved: (participantsInfo) {
      try {} catch (e) {
        l.e("participantsInfoRetrieved: $e");
      }
    },
    readyToClose: () {
      Navigate.to(
        route: Routes.HOME,
        type: NavigationTypes.offNamed,
      );
      sendGroupPeresenceEvent(
          groupId: outpost.uuid, eventName: eventNames.leave);
      groupCallController.cleanupAfterCall();
      if (Get.isRegistered<OngoingOutpostCallController>()) {
        Get.delete<OngoingOutpostCallController>();
      }
    },
    // like: (idWithAddedAtSign, participantId) async {
    //   final OngoingGroupCallController ongoingGroupCallController =
    //       Get.find<OngoingGroupCallController>();
    //   final id = transformEmailLikeToId(idWithAddedAtSign!);
    //   ongoingGroupCallController.onLikeClicked(id);
    // },
    // dislike: (idWithAddedAtSign, participantId) async {
    //   final OngoingGroupCallController ongoingGroupCallController =
    //       Get.find<OngoingGroupCallController>();
    //   final id = transformEmailLikeToId(idWithAddedAtSign!);
    //   ongoingGroupCallController.onDislikeClicked(id);
    // },
    // cheer: (idWithAddedAtSign, participantId) async {
    //   final OngoingGroupCallController ongoingGroupCallController =
    //       Get.find<OngoingGroupCallController>();
    //   final id = transformEmailLikeToId(idWithAddedAtSign!);
    //   log.f(id);
    //   ongoingGroupCallController.cheerBoo(
    //     userId: id,
    //     cheer: true,
    //     fromMeetPage: true,
    //   );
    // },
    // boo: (idWithAddedAtSign, participantId) async {
    //   final OngoingGroupCallController ongoingGroupCallController =
    //       Get.find<OngoingGroupCallController>();
    //   final id = transformEmailLikeToId(idWithAddedAtSign!);
    //   ongoingGroupCallController.cheerBoo(
    //     userId: id,
    //     cheer: false,
    //     fromMeetPage: true,
    //   );
    // },
  );
}
