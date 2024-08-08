import 'package:get/get.dart';

import '../controllers/playground_controller.dart';

class PlaygroundBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlaygroundController>(
      () => PlaygroundController(),
    );
  }
}
