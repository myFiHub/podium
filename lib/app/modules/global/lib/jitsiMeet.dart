import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingGroupCall/controllers/ongoing_group_call_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';

final jitsiMeet = JitsiMeet();
const MethodChannel jitsiMethodChannel = MethodChannel('jitsi_meet_wrapper');

JitsiMeetEventListener jitsiListeners({required OutpostModel group}) {
  Get.put<OngoingGroupCallController>(OngoingGroupCallController());
  final groupCallController = Get.find<GroupCallController>();
  return JitsiMeetEventListener(
    conferenceJoined: (url) async {
      if (Platform.isIOS) {
        // jitsiMeet.enterPiP();
      }
      Navigate.to(
        route: Routes.ONGOING_GROUP_CALL,
        type: NavigationTypes.toNamed,
      );
      final myUserId = myId;
      final groupCreator = groupCallController.group.value!.creator.id;
      final iAmCreator = groupCreator == myUserId;
      if (group.creatorJoined != true && iAmCreator) {
        await setCreatorJoinedToTrue(groupId: group.id);
      }
      groupCallController.haveOngoingCall.value = true;
      // groupCallController.setIsUserPresentInSession(
      //   groupId: groupCallController.group.value!.id,
      //   userId: myId,
      //   isPresent: true,
      // );
      await updateGroupLastActiveAt(
        groupId: group.id,
        lastActiveAt: DateTime.now().millisecondsSinceEpoch,
      );

      await Future.delayed(const Duration(seconds: 3));
      sendGroupPeresenceEvent(groupId: group.id, eventName: eventNames.enter);
      await jitsiMeet.retrieveParticipantsInfo();

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
      if (Get.isRegistered<OngoingGroupCallController>()) {
        Get.find<OngoingGroupCallController>().audioMuteChanged(
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
      try {
        // final members =
        //     convertJitsiMembersResponseToReadableJson(participantsInfo);
        // final OngoingGroupCallController ongoingGroupCallController =
        //     Get.find<OngoingGroupCallController>();
        // groupCallController.jitsiMembers.value = members;
        // ongoingGroupCallController.jitsiMembers.value = members;
      } catch (e) {
        l.e("participantsInfoRetrieved: $e");
      }
    },
    readyToClose: () {
      Navigate.to(
        route: Routes.HOME,
        type: NavigationTypes.offNamed,
      );
      sendGroupPeresenceEvent(groupId: group.id, eventName: eventNames.leave);
      groupCallController.cleanupAfterCall();
      if (Get.isRegistered<OngoingGroupCallController>()) {
        Get.delete<OngoingGroupCallController>();
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
