import 'package:get/get.dart';

import '../controllers/ongoing_group_call_controller.dart';

class OngoingGroupCallBinding extends Binding {
  @override
  dependencies() => [
        Bind.lazyPut<OngoingGroupCallController>(
          () => OngoingGroupCallController(),
        )
      ];
}
