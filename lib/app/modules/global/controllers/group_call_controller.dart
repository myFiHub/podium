import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
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

  startCall(FirebaseGroup g) async {
    final hasMicAccess = await getPermission(Permission.microphone);
    final hasNotificationPermission =
        await getPermission(Permission.notification);
    if (!hasMicAccess) {
      Get.snackbar(
        "warning",
        "mic permission is required in order to join the call",
        colorText: ColorName.white,
      );
    }
    if (!hasNotificationPermission) {
      Get.snackbar(
        "warning",
        "notification permission is required in order to join the call",
        colorText: ColorName.white,
      );
    }
    final globalController = Get.find<GlobalController>();
    final myUser = globalController.currentUserInfo.value!;
    if (myUser.localWalletAddress == '' ||
        globalController.connectedWalletAddress == '') {
      Get.snackbar(
        "Wallet connection required",
        "Please connect your wallet first",
        colorText: ColorName.white,
      );
      globalController.connectToWallet(
        afterConnection: () {
          startCall(g);
        },
      );
      return;
    }
    group.value = g;
    members.value = await getUsersByIds(g.members);
    var options = MeetingConstants.buildMeetOptions(
      group: g,
      myUser: myUser,
    );
    try {
      await jitsiMeet.join(options, jitsiListeners);
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
