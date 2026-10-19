import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';

final jitsiMeet = JitsiMeet();
const MethodChannel jitsiMethodChannel = MethodChannel('jitsi_meet_wrapper');
final joinOrLeftDebounce = Debouncing(
  duration: const Duration(seconds: 1),
  maxWait: const Duration(seconds: 3),
);

CallRoomController? get _room => findCallRoom();

void openCallPage() {
  if (Get.isRegistered<OngoingOutpostCallController>()) {
    Get.find<OngoingOutpostCallController>().callPageOpened = true;
  }
  Navigate.to(
    route: Routes.ONGOING_OUTPOST_CALL,
    type: NavigationTypes.toNamed,
  );
}

JitsiMeetEventListener jitsiListeners({required OutpostModel outpost}) {
  for (var i = 0;
      i < 3 && Get.isRegistered<OngoingOutpostCallController>();
      i++) {
    Get.delete<OngoingOutpostCallController>(force: true);
  }
  // Permanent so route disposal (sheets, dialogs, page swaps) never tears
  // down a live call; only cleanupAfterCall deletes it.
  Get.put<OngoingOutpostCallController>(
    OngoingOutpostCallController(),
    permanent: true,
  );
  if (Get.isRegistered<CallRoomController>()) {
    Get.delete<CallRoomController>(force: true);
  }
  Get.put<CallRoomController>(CallRoomController(), permanent: true);
  final outpostCallController = Get.find<OutpostCallController>();
  outpostCallController.markCallStarted();
  return JitsiMeetEventListener(
    conferenceJoined: (url) async {
      outpostCallController.fetchLiveData(withJoin: true);

      if (Platform.isIOS) {
        // jitsiMeet.enterPiP();
      }
      if (Get.isRegistered<OngoingOutpostCallController>()) {
        final ongoing = Get.find<OngoingOutpostCallController>();
        ongoing.isConferenceJoined.value = true;
        if (!ongoing.callPageOpened) openCallPage();
      }
      final myUserId = myId;
      final outpostCreator = outpost.creator_user_uuid;
      final iAmCreator = outpostCreator == myUserId;
      if (outpost.creator_joined != true && iAmCreator) {
        await HttpApis.podium.setCreatorJoinedToTrue(outpost.uuid);
      }
      outpostCallController.haveOngoingCall.value = true;
    },
    participantJoined: (email, name, role, participantId) {
      _room?.onParticipantJoined(
        email: email,
        name: name,
        role: role,
        participantId: participantId,
      );
      joinOrLeftDebounce.debounce(() {
        outpostCallController.fetchLiveData();
      });
      l.d(
        "participantJoined: email: $email, name: $name, role: $role, "
        "participantId: $participantId",
      );
    },
    participantLeft: (p) {
      _room?.onParticipantLeft(p);
      joinOrLeftDebounce.debounce(() {
        outpostCallController.fetchLiveData();
      });
      l.d("participantLeft: $p");
    },
    audioMutedChanged: (muted) {
      // Jitsi resets to unmuted while tearing down after hangUp.
      if (outpostCallController.callCleanedUp) return;
      if (Get.isRegistered<OngoingOutpostCallController>()) {
        Get.find<OngoingOutpostCallController>().audioMuteChanged(
          muted: muted,
        );
      }
    },
    videoMutedChanged: (muted) {
      l.d("videoMutedChanged: $muted");
    },
    podiumEvent: (name, data) {
      _room?.onPodiumEvent(name, data);
    },
    endpointTextMessageReceived: (senderId, message) {
      _room?.onEndpointMessage(senderId, message);
    },
    chatMessageReceived: (senderId, message, isPrivate, timestamp) {
      _room?.onChatMessage(senderId, message, isPrivate);
    },

    conferenceTerminated: (url, error) async {
      l.f("conferenceTerminated: url: $url, error: $error");
      final joined = Get.isRegistered<OngoingOutpostCallController>() &&
          Get.find<OngoingOutpostCallController>().isConferenceJoined.value;
      if (error != null && !joined) {
        Toast.error(
          title: "Couldn't connect",
          message: 'Failed to join the outpost, please try again',
        );
      }
    },
    participantsInfoRetrieved: (participantsInfo) {
      try {} catch (e) {
        l.e("participantsInfoRetrieved: $e");
      }
    },
    readyToClose: () {
      if (outpostCallController.callCleanedUp) return;
      Navigate.to(
        route: Routes.HOME,
        type: NavigationTypes.offNamed,
      );
      outpostCallController.cleanupAfterCall();
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
