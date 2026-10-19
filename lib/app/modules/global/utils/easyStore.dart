import 'package:aptos/aptos.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/websocket/websocket_service.dart';
import 'package:podium/utils/logger.dart';
import 'package:reown_appkit/reown_appkit.dart';

GlobalController get _global => Get.find<GlobalController>();

UserModel get myUser => _global.myUserInfo.value!;

String get myId {
  final id = myUser.uuid;
  if (id == '') {
    l.f('****************************myId is empty************************');
  }
  return id;
}

WebSocketService get wsClient => _global.ws_client!;

ReownAppKitModal get web3ModalService => _global.web3ModalService;

AptosAccount get aptosAccount => _global.aptosAccount!;

String? get externalWalletAddress {
  final address = _global.connectedWalletAddress.value;
  return address.isEmpty ? null : address;
}

String get externalWalletChianId => _global.externalWalletChainId.value;

ReownAppKitModalNetworkInfo get movementAptosNetwork =>
    _global.movementAptosNetwork;

String get movementAptosPodiumProtocolAddress =>
    _global.movementAptosPodiumProtocolAddress;

String get movementAptosCheerBooAddress => _global.movementAptosCheerBooAddress;
