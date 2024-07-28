import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';

class GlobalBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<GlobalController>(GlobalController(), permanent: true);
    Get.put<GroupsController>(GroupsController(), permanent: true);
    Get.put<UsersController>(UsersController(), permanent: true);
    Get.put<GroupCallController>(GroupCallController(), permanent: true);
  }
}
