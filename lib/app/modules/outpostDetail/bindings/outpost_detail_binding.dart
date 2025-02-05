import 'package:get/get.dart';

import '../controllers/outpost_detail_controller.dart';

class GroupDetailBinding extends Binding {
  @override
  dependencies() => <Bind>[
        Bind.lazyPut<OutpostDetailController>(
          () => OutpostDetailController(),
        )
      ];
}
