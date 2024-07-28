import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/models/notification_model.dart';
import 'package:podium/utils/logger.dart';
import 'package:uuid/uuid.dart';

class NotificationsController extends GetxController with FireBaseUtils {
  final GlobalController globalController = Get.find<GlobalController>();
  final notifications = <FirebaseNotificationModel>[].obs;
  final numberOfUnreadNotifications = 0.obs;
  @override
  void onInit() {
    super.onInit();
    globalController.loggedIn.listen((loggedIn) {
      if (loggedIn) {
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
      final notifs = await getMyNotifications();
      log.d(notifs);
      notifications.assignAll(notifs);
    } catch (e) {
      log.e(e);
    }
  }

  deleteMyNotification(String id) {
    try {
      deleteNotification(notificationId: id);
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
