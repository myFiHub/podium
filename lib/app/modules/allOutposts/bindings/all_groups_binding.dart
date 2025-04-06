import 'package:get/get.dart';

import '../controllers/all_outposts_controller.dart';

class AllGroupsBinding extends Binding {
  @override
  dependencies() => [
        Bind.lazyPut<AllOutpostsController>(
          () => AllOutpostsController(),
        )
      ];
}
