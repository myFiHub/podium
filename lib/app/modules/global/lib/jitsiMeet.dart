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
import 'package:podium/services/websocket/outgoingMessage.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';

final jitsiMeet = JitsiMeet();
const MethodChannel jitsiMethodChannel = MethodChannel('jitsi_meet_wrapper');
final joinOrLeftDebounce = Debouncing(duration: const Duration(seconds: 1));

JitsiMeetEventListener jitsiListeners({required OutpostModel outpost}) {
  Get.put<OngoingOutpostCallController>(OngoingOutpostCallController());
  final outpostCallController = Get.find<OutpostCallController>();
  return JitsiMeetEventListener(
    conferenceJoined: (url) async {
      joinOrLeftDebounce.debounce(() {
        outpostCallController.fetchLiveData();
      });
      if (Platform.isIOS) {
        // jitsiMeet.enterPiP();
      }
      Navigate.to(
        route: Routes.ONGOING_OUTPOST_CALL,
        type: NavigationTypes.toNamed,
      );
      final myUserId = myId;
      final outpostCreator = outpost.creator_user_uuid;
      final iAmCreator = outpostCreator == myUserId;
      if (outpost.creator_joined != true && iAmCreator) {
        await HttpApis.podium.setCreatorJoinedToTrue(outpost.uuid);
      }
      outpostCallController.haveOngoingCall.value = true;

      await Future.delayed(const Duration(seconds: 3));
      sendOutpostEvent(
          outpostId: outpost.uuid, eventType: OutgoingMessageTypeEnums.join);

      l.d("conferenceJoined: url: $url");
    },
    participantJoined: (email, name, role, participantId) {
      joinOrLeftDebounce.debounce(() {
        outpostCallController.fetchLiveData();
      });
      l.d(
        "participantJoined: email: $email, name: $name, role: $role, "
        "participantId: $participantId",
      );
    },
    participantLeft: (p) {
      joinOrLeftDebounce.debounce(() {
        outpostCallController.fetchLiveData();
      });
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
      sendOutpostEvent(
          outpostId: outpost.uuid, eventType: OutgoingMessageTypeEnums.leave);
      outpostCallController.cleanupAfterCall();
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
