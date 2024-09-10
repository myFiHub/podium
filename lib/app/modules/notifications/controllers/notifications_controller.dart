import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/models/notification_model.dart';
import 'package:podium/utils/logger.dart';
import 'package:uuid/uuid.dart';

class NotificationsController extends GetxController with FireBaseUtils {
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
      log.e(e);
    }
  }

  deleteMyNotification(FirebaseNotificationModel notif) {
    try {
      deleteNotification(notificationId: notif.id);
    } catch (e) {
      log.e(e);
    }
  }

  acceptGroupInvitation({
    required FirebaseNotificationModel notif,
  }) async {
    final groupId = notif.actionId;
    if (groupId == null) return;
    final GroupsController groupsController = Get.find<GroupsController>();
    await groupsController.joinGroupAndOpenGroupDetailPage(
      groupId: groupId,
    );
    try {
      await deleteNotification(notificationId: notif.id);
    } catch (e) {
      log.e(e);
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
      log.e(e);
    }
  }

  sendTestNotif() async {
    final GlobalController globalController = Get.find<GlobalController>();
    try {
      await sendNotification(
        notification: FirebaseNotificationModel(
            id: Uuid().v4(),
            title: 'title',
            body:
                'bsodssssdddddddddddddddddddddddddddddssssdfsdddddddddddddddddddf sdf dsf dsssssssssssssssssssssssssssssssssssssssssssy',
            type: 'type',
            targetUserId: globalController.currentUserInfo.value!.id,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            isRead: false),
      );
    } catch (e) {
      log.e(e);
    }
  }
}
