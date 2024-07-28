import 'package:get/get.dart';

import '../controllers/all_groups_controller.dart';

class AllGroupsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AllGroupsController>(
      () => AllGroupsController(),
    );
  }
}
