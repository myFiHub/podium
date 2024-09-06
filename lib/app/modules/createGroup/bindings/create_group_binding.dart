import 'package:get/get.dart';

import '../controllers/create_group_controller.dart';

class CreateGroupBinding extends Binding {
  @override
  dependencies() => [
        Bind.lazyPut<CreateGroupController>(
          () => CreateGroupController(),
        )
      ];
}
