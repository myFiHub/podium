import 'package:get/get.dart';

import '../controllers/edit_group_controller.dart';

class EditGroupBinding extends Binding {
  @override
  dependencies() => [
        Bind.lazyPut<EditGroupController>(
          () => EditGroupController(),
        )
      ];
}
