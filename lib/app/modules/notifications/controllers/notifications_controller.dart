import 'dart:async';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/podium/models/notifications/notificationModel.dart';
import 'package:podium/providers/api/podium/models/outposts/rejectInvitationRequest.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

class NotificationsController extends GetxController {
  final _notificationRepository = Get.find<NotificationRepository>();
  final _outpostRepository = Get.find<OutpostRepository>();
  final GlobalController globalController = Get.find<GlobalController>();
  final OutpostsController outpostsController = Get.find<OutpostsController>();
  final notifications = <NotificationModel>[].obs;
  final numberOfUnreadNotifications = 0.obs;
  final loadingUserId = ''.obs;
  final loadingInviteId = ''.obs;
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
  void onClose() {
    loggedInListener?.cancel();
    super.onClose();
  }

  Future<void> getNotifications() async {
    final notifs = await _notificationRepository.getNotifications();
    int numberOfUnread = 0;
    for (final notif in notifs) {
      if (!notif.is_read) {
        numberOfUnread++;
      }
    }
    numberOfUnreadNotifications.value = numberOfUnread;
    notifications.assignAll(notifs);
  }

  Future<void> markNotificationAsRead({required String id}) async {
    loadingInviteId.value = '${id}read';
    final success =
        await _notificationRepository.markNotificationAsRead(id: id);
    if (success) {
      await getNotifications();
    }
    loadingInviteId.value = '';
  }

  Future<void> openUserProfile(
      {required String id, required String notifId}) async {
    loadingUserId.value = id + notifId;
    final usersController = Get.find<UsersController>();
    await usersController.openUserProfile(id);
    loadingUserId.value = '';
  }

  Future<void> acceptOutpostInvitation({
    required NotificationModel notif,
  }) async {
    try {
      loadingInviteId.value = '${notif.uuid}accept';
      final outpostId = notif.invite_metadata!.outpost_uuid;
      await outpostsController.joinOutpostAndOpenOutpostDetailPage(
        outpostId: outpostId,
      );
      await markNotificationAsRead(id: notif.uuid);
      final success =
          await _notificationRepository.deleteNotification(notif.uuid);
      if (success) {
        await getNotifications();
      }
    } catch (e) {
      l.e(e);
    } finally {
      loadingInviteId.value = '';
    }
  }

  Future<void> rejectOutpostInvitation({
    required NotificationModel notif,
  }) async {
    try {
      loadingInviteId.value = '${notif.uuid}reject';
      final success = await _outpostRepository.rejectInvitation(
        RejectInvitationRequest(
          inviter_uuid: notif.invite_metadata!.inviter_uuid,
          outpost_uuid: notif.invite_metadata!.outpost_uuid,
        ),
      );
      if (success) {
        Toast.success(message: 'Invitation rejected');
        final success =
            await _notificationRepository.deleteNotification(notif.uuid);
        if (success) {
          await getNotifications();
        }
      } else {
        Toast.error(message: 'Failed to reject invitation');
      }
    } catch (e) {
      l.e(e);
    } finally {
      loadingInviteId.value = '';
    }
  }
}
