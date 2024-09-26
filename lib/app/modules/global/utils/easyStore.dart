import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/models/user_info_model.dart';

UserInfoModel get myUser {
  final GlobalController globalController = Get.find();
  return globalController.currentUserInfo.value!;
}

String get myId {
  return myUser.id;
}
