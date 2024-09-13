import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/notifications/controllers/notifications_controller.dart';

final globalBindings = [
  Bind.put<GlobalController>(GlobalController(), permanent: true),
  Bind.put<GroupsController>(GroupsController(), permanent: true),
  Bind.put<UsersController>(UsersController(), permanent: true),
  Bind.put<GroupCallController>(GroupCallController(), permanent: true),
  Bind.put<NotificationsController>(NotificationsController(), permanent: true)
];

class GlobalBindings extends Binding {
  @override
  List<Bind> dependencies() => globalBindings;
}
