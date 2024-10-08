import 'package:get/get.dart';

import '../controllers/my_profile_controller.dart';

class MyProfileBinding extends Binding {
  @override
  dependencies() => [
        Bind.lazyPut<MyProfileController>(
          () => MyProfileController(),
        )
      ];
}
