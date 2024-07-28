import 'package:get/get.dart';

import '../controllers/group_detail_controller.dart';

class GroupDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GroupDetailController>(
      () => GroupDetailController(),
    );
  }
}
