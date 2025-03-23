import 'dart:async';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/notifications/notificationModel.dart';
import 'package:podium/providers/api/podium/models/outposts/rejectInvitationRequest.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

class NotificationsController extends GetxController {
  final GlobalController globalController = Get.find<GlobalController>();
  final OutpostsController outpostsController = Get.find<OutpostsController>();
  final notifications = <NotificationModel>[].obs;
  final numberOfUnreadNotifications = 0.obs;
  StreamSubscription<bool>? loggedInListener;
  @override
  void onInit() {
    super.onInit();
    loggedInListener = globalController.loggedIn.listen((loggedIn) async {
      if (loggedIn) {
        getNotifications();
      } else {
        notifications.clear();
        numberOfUnreadNotifications.value = 0;
      }
    });
  }

  @override
  void onReady() async {
    loggedInListener?.cancel();
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  getNotifications() async {
    final notifs = await HttpApis.podium.getNotifications();
    int numberOfUnread = 0;
    for (final notif in notifs) {
      if (!notif.is_read) {
        numberOfUnread++;
      }
    }
    numberOfUnreadNotifications.value = numberOfUnread;
    notifications.assignAll(notifs);
  }

  markNotificationAsRead({required String id}) async {
    final success = await HttpApis.podium.markNotificationAsRead(id: id);
    if (success) {
      getNotifications();
    }
  }

  acceptOutpostInvitation({
    required NotificationModel notif,
  }) async {
    try {
      final outpostId = notif.inviteMetadata!.outpost_uuid;
      await outpostsController.joinOutpostAndOpenOutpostDetailPage(
        outpostId: outpostId,
      );
      await markNotificationAsRead(id: notif.uuid);
      await getNotifications();
    } catch (e) {
      l.e(e);
    }
  }

  rejectOutpostInvitation({
    required NotificationModel notif,
  }) async {
    try {
      final success = await HttpApis.podium.rejectInvitation(
        RejectInvitationRequest(
          inviter_uuid: notif.inviteMetadata!.inviter_uuid,
          outpost_uuid: notif.inviteMetadata!.outpost_uuid,
        ),
      );
      if (success) {
        Toast.success(message: 'Invitation rejected');
      } else {
        Toast.error(message: 'Failed to reject invitation');
      }
    } catch (e) {
      l.e(e);
    }
  }
}
