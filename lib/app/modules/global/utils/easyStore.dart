import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';
import 'package:reown_appkit/reown_appkit.dart';

UserInfoModel get myUser {
  final GlobalController globalController = Get.find();
  return globalController.currentUserInfo.value!;
}

String get myId {
  if (myUser == null) {
    log.f('****************************myUser is null************************');
    return '';
  }
  if (myUser!.id == '') {
    log.f('****************************myId is empty************************');
  }
  return myUser.id;
}

ReownAppKitModal get web3ModalService {
  final globalController = Get.find<GlobalController>();
  return globalController.web3ModalService;
}

String? get externalWalletAddress {
  final GlobalController globalController = Get.find();
  final address = globalController.connectedWalletAddress.value;
  if (address.isEmpty) {
    return null;
  }
  return address;
}

String get externalWalletChianId {
  final GlobalController globalController = Get.find();
  return globalController.externalWalletChainId.value;
}
