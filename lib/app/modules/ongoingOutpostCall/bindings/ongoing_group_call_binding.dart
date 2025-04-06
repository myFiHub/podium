import 'package:get/get.dart';

import '../controllers/ongoing_outpost_call_controller.dart';

class OngoingGroupCallBinding extends Binding {
  @override
  dependencies() => [
        Bind.lazyPut<OngoingOutpostCallController>(
          () => OngoingOutpostCallController(),
        )
      ];
}
