import 'package:get/get.dart';
import 'package:podium/app/modules/replay/controllers/replay_controller.dart';

class ReplayBinding extends Binding {
  @override
  List<Bind> dependencies() => [
        Bind.lazyPut<ReplayController>(
          () => ReplayController(Get.arguments as String),
        ),
      ];
}
