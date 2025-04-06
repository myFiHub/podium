import 'package:get/get.dart';

import '../controllers/create_outpost_controller.dart';

class CreateGroupBinding extends Binding {
  @override
  dependencies() => [
        Bind.lazyPut<CreateOutpostController>(
          () => CreateOutpostController(),
        )
      ];
}
