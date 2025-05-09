import 'package:aptos/aptos.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/websocket/client.dart';
import 'package:podium/utils/logger.dart';
import 'package:reown_appkit/reown_appkit.dart';

UserModel get myUser {
  final GlobalController globalController = Get.find();
  return globalController.myUserInfo.value!;
}

String get myId {
  if (myUser.uuid == '') {
    l.f('****************************myId is empty************************');
  }
  return myUser.uuid;
}

WebSocketService get wsClient {
  final globalController = Get.find<GlobalController>();
  return globalController.ws_client!;
}

ReownAppKitModal get web3ModalService {
  final globalController = Get.find<GlobalController>();
  return globalController.web3ModalService;
}

AptosAccount get aptosAccount {
  final globalController = Get.find<GlobalController>();
  return globalController.aptosAccount!;
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

ReownAppKitModalNetworkInfo get movementAptosNetwork {
  final GlobalController globalController = Get.find();
  return globalController.movementAptosNetwork;
}

String get movementAptosPodiumProtocolAddress {
  final GlobalController globalController = Get.find();
  return globalController.movementAptosPodiumProtocolAddress;
}

String get movementAptosCheerBooAddress {
  final GlobalController globalController = Get.find();
  return globalController.movementAptosCheerBooAddress;
}
