import 'package:get/get.dart';

import '../controllers/all_groups_controller.dart';

class AllGroupsBinding extends Binding {
  @override
  dependencies() => [
        Bind.lazyPut<AllGroupsController>(
          () => AllGroupsController(),
        )
      ];
}
