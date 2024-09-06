import 'package:get/get.dart';

import '../controllers/signup_controller.dart';

class SignupBinding extends Binding {
  @override
  dependencies() => [
        Bind.lazyPut<SignUpController>(
          () => SignUpController(),
        )
      ];
}
