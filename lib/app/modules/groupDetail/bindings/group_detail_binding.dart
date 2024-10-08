import 'package:get/get.dart';

import '../controllers/group_detail_controller.dart';

class GroupDetailBinding extends Binding {
  @override
  dependencies() => <Bind>[
        Bind.lazyPut<GroupDetailController>(
          () => GroupDetailController(),
        )
      ];
}
