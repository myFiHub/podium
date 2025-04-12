import 'package:get/get.dart';

import '../controllers/profile_controller.dart';

class ProfileBinding extends Binding {
  @override
  dependencies() => [Bind.put<ProfileController>(ProfileController())];
}
