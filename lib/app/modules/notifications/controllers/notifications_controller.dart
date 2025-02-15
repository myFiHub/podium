import 'dart:async';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';

import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/notifications/notificationModel.dart';
import 'package:podium/providers/api/podium/models/outposts/rejectInvitationRequest.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

class NotificationsController extends GetxController {
  final GlobalController globalController = Get.find<GlobalController>();
  final notifications = <NotificationModel>[].obs;
  final numberOfUnreadNotifications = 0.obs;

  @override
  void onInit() {
    super.onInit();
    globalController.loggedIn.listen((loggedIn) async {
      if (loggedIn) {
        final notifs = await HttpApis.podium.getNotifications();

        int numberOfUnread = 0;
        for (final notif in notifs) {
          if (!notif.is_read) {
            numberOfUnread++;
          }
        }
        numberOfUnreadNotifications.value = numberOfUnread;
        notifications.assignAll(notifs);
      } else {
        notifications.clear();
        numberOfUnreadNotifications.value = 0;
      }
    });
  }

  @override
  void onReady() async {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  getNotifications() async {
    try {
      final notifs = await HttpApis.podium.getNotifications();
      notifications.assignAll(notifs);
    } catch (e) {
      l.e(e);
    }
  }

  deleteMyNotification(NotificationModel notif) {
    try {} catch (e) {
      l.e(e);
    }
  }

  acceptOutpostInvitation({
    required NotificationModel notif,
  }) async {
    try {} catch (e) {
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
