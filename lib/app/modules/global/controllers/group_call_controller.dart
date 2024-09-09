import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/mixins/permissions.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/constants/meeting.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/jitsi_member.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';

class GroupCallController extends GetxController
    with FireBaseUtils, PermissionUtils {
  // group session id is group id
  final groupsController = Get.find<GroupsController>();
  final globalController = Get.find<GlobalController>();
  final group = Rxn<FirebaseGroup>();
  final members = Rx<List<UserInfoModel>>([]);
  final haveOngoingCall = false.obs;
  final jitsiMembers = Rx<List<JitsiMember>>([]);

  StreamSubscription<DatabaseEvent>? sessionSubscription = null;

  @override
  void onInit() {
    super.onInit();
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

  cleanupAfterCall() {
    sessionSubscription?.cancel();
    sessionSubscription = null;
    haveOngoingCall.value = false;
    jitsiMembers.value = [];
    jitsiMeet.hangUp();
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
    members.value = await getUsersByIds(groupToJoin.members);
    var options = MeetingConstants.buildMeetOptions(
      group: groupToJoin,
      myUser: myUser,
      allowedToSpeak: iAmAllowedToSpeak,
    );
    try {
      await jitsiMeet.join(options, jitsiListeners());
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

  bool canISpeak({required FirebaseGroup group}) {
    final globalController = Get.find<GlobalController>();
    final myId = globalController.currentUserInfo.value!.id;
    final iAmTheCreator = group.creator.id == myId;
    final iAmAllowedToSpeak = group.speakerType == null ||
        iAmTheCreator ||
        group.speakerType == RoomSpeakerTypes.everyone ||
        group.speakerType == RoomSpeakerTypes.invitees;
    return iAmAllowedToSpeak;
  }
}
