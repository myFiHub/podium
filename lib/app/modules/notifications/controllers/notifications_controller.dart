import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/models/notification_model.dart';
import 'package:podium/utils/logger.dart';
import 'package:uuid/uuid.dart';

class NotificationsController extends GetxController {
  final GlobalController globalController = Get.find<GlobalController>();
  final notifications = <FirebaseNotificationModel>[].obs;
  final numberOfUnreadNotifications = 0.obs;
  StreamSubscription<DatabaseEvent>? notificationsSubscription = null;

  @override
  void onInit() {
    super.onInit();
    globalController.loggedIn.listen((loggedIn) {
      if (loggedIn) {
        notificationsSubscription =
            startListeningToMyNotifications((notificationList) {
          final sortedNotifs = notificationList
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          int numberOfUnread = 0;
          for (final notif in sortedNotifs) {
            if (!notif.isRead) {
              numberOfUnread++;
            }
          }
          numberOfUnreadNotifications.value = numberOfUnread;
          notifications.assignAll(sortedNotifs);
        });
      } else {
        notifications.clear();
        numberOfUnreadNotifications.value = 0;
        notificationsSubscription?.cancel();
        notificationsSubscription = null;
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

  stopNotificationsListener() {
    notificationsSubscription?.cancel();
    notificationsSubscription = null;
  }

  getNotifications() async {
    try {
      final notifs = await getMyNotifications();
      notifications.assignAll(notifs);
    } catch (e) {
      l.e(e);
    }
  }

  deleteMyNotification(FirebaseNotificationModel notif) {
    try {
      deleteNotification(notificationId: notif.id);
    } catch (e) {
      l.e(e);
    }
  }

  acceptGroupInvitation({
    required FirebaseNotificationModel notif,
  }) async {
    final groupId = notif.actionId;
    if (groupId == null) return;
    final OutpostsController groupsController = Get.find<OutpostsController>();
    await groupsController.joinGroupAndOpenGroupDetailPage(
      groupId: groupId,
    );
    try {
      await deleteNotification(notificationId: notif.id);
    } catch (e) {
      l.e(e);
    }
  }

  rejectGroupInvitation({
    required FirebaseNotificationModel notif,
  }) async {
    final groupId = notif.actionId;
    if (groupId == null) return;
    try {
      await deleteNotification(notificationId: notif.id);
    } catch (e) {
      l.e(e);
    }
  }

  sendTestNotif() async {
    try {
      await sendNotification(
        notification: FirebaseNotificationModel(
            id: const Uuid().v4(),
            title: 'title',
            body:
                'bsodssssdddddddddddddddddddddddddddddssssdfsdddddddddddddddddddf sdf dsf dsssssssssssssssssssssssssssssssssssssssssssy',
            type: 'type',
            targetUserId: myId,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            isRead: false),
      );
    } catch (e) {
      l.e(e);
    }
  }
}
