import 'package:get/get.dart';

import '../controllers/create_group_controller.dart';

class CreateGroupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateGroupController>(
      () => CreateGroupController(),
    );
  }
}
