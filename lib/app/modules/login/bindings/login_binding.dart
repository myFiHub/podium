import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class LoginBinding extends Binding {
  @override
  dependencies() => [
        Bind.put<LoginController>(
          LoginController(),
        )
      ];
}
