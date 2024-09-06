import 'package:get/get.dart';

import '../controllers/playground_controller.dart';

class PlaygroundBinding extends Binding {
  @override
  dependencies() => [
        Bind.lazyPut<PlaygroundController>(
          () => PlaygroundController(),
        )
      ];
}
