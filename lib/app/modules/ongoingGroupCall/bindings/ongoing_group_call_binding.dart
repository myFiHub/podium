import 'package:get/get.dart';

import '../controllers/ongoing_group_call_controller.dart';

class OngoingGroupCallBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OngoingGroupCallController>(
      () => OngoingGroupCallController(),
    );
  }
}
