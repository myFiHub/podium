import 'package:get/get.dart';

import '../controllers/notifications_controller.dart';

class NotificationsBinding extends Binding {
  @override
  dependencies() => [
        Bind.lazyPut<NotificationsController>(
          () => NotificationsController(),
        )
      ];
}
