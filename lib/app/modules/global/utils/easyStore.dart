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

String? get externalWalletAddress {
  final GlobalController globalController = Get.find();
  final address = globalController.connectedWalletAddress.value;
  if (address.isEmpty) {
    return null;
  }
  return address;
}

get externalWalletChianId {
  final GlobalController globalController = Get.find();
  return globalController.externalWalletChainId.value;
}

get particleChianId {
  final GlobalController globalController = Get.find();
  return globalController.particleWalletChainId.value;
}
