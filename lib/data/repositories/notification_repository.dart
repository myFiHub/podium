import 'package:podium/providers/api/podium/models/notifications/notificationModel.dart';
import 'package:podium/providers/api/podium/podium.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final PodiumApi _api;

  Future<List<NotificationModel>> getNotifications() => _api.getNotifications();

  Future<bool> markNotificationAsRead({required String id}) =>
      _api.markNotificationAsRead(id: id);

  Future<bool> deleteNotification(String id) => _api.deleteNotification(id);
}
