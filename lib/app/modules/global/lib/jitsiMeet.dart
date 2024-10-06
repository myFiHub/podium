import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingGroupCall/controllers/ongoing_group_call_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/constants/meeting.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';

final jitsiMeet = JitsiMeet();
const MethodChannel jitsiMethodChannel = MethodChannel('jitsi_meet_wrapper');

JitsiMeetEventListener jitsiListeners({required FirebaseGroup group}) {
  Get.put<OngoingGroupCallController>(OngoingGroupCallController());
  final groupCallController = Get.find<GroupCallController>();
  return JitsiMeetEventListener(
    conferenceJoined: (url) async {
      Navigate.to(
        route: Routes.ONGOING_GROUP_CALL,
        type: NavigationTypes.toNamed,
      );
      final myUserId = myId;
      final groupCreator = groupCallController.group.value!.creator.id;
      final iAmCreator = groupCreator == myUserId;
      if (group.creatorJoined != true && iAmCreator) {
        await groupCallController.setCreatorJoinedToTrue(groupId: group.id);
      }
      groupCallController.haveOngoingCall.value = true;
      groupCallController.setIsUserPresentInSession(
        groupId: groupCallController.group.value!.id,
        userId: myId,
        isPresent: true,
      );
      await groupCallController.updateGroupLastActiveAt(
        groupId: group.id,
        lastActiveAt: DateTime.now().millisecondsSinceEpoch,
      );

      await Future.delayed(Duration(seconds: 3));
      final channel = realtimeInstance.channels.get(group.id);
      channel.presence.leave(group.id);
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
      final channel = realtimeInstance.channels.get(group.id);
      channel.presence.leave(group.id);

      groupCallController.setIsUserPresentInSession(
        groupId: groupCallController.group.value!.id,
        userId: myId,
        isPresent: false,
      );
      groupCallController.cleanupAfterCall();
      if (Get.isRegistered<OngoingGroupCallController>()) {
        Get.delete<OngoingGroupCallController>();
      }
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
        log.e("participantsInfoRetrieved: $e");
      }
    },
    readyToClose: () {
      log.d("readyToClose");
    },
    like: (idWithAddedAtSign, participantId) async {
      final OngoingGroupCallController ongoingGroupCallController =
          Get.find<OngoingGroupCallController>();
      final id = transformEmailLikeToId(idWithAddedAtSign!);
      ongoingGroupCallController.onLikeClicked(id);
    },
    dislike: (idWithAddedAtSign, participantId) async {
      final OngoingGroupCallController ongoingGroupCallController =
          Get.find<OngoingGroupCallController>();
      final id = transformEmailLikeToId(idWithAddedAtSign!);
      ongoingGroupCallController.onDislikeClicked(id);
    },
    cheer: (idWithAddedAtSign, participantId) async {
      final OngoingGroupCallController ongoingGroupCallController =
          Get.find<OngoingGroupCallController>();
      final id = transformEmailLikeToId(idWithAddedAtSign!);
      log.f(id);
      ongoingGroupCallController.cheerBoo(
        userId: id,
        cheer: true,
        fromMeetPage: true,
      );
    },
    boo: (idWithAddedAtSign, participantId) async {
      final OngoingGroupCallController ongoingGroupCallController =
          Get.find<OngoingGroupCallController>();
      final id = transformEmailLikeToId(idWithAddedAtSign!);
      ongoingGroupCallController.cheerBoo(
        userId: id,
        cheer: false,
        fromMeetPage: true,
      );
    },
  );
}
