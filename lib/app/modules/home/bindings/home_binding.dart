import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeBinding extends Binding {
  @override
  dependencies() => [
        Bind.put<HomeController>(
          HomeController(),
        )
      ];
}
