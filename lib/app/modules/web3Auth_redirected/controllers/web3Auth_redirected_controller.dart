import 'package:get/get.dart';
import 'package:podium/utils/logger.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3dart/credentials.dart';

class Web3AuthRedirectedController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() async {
    super.onReady();
    final userInfo = await Web3AuthFlutter.getUserInfo();
    final privateKey = await Web3AuthFlutter.getPrivKey();
    final ethereumKeyPair = EthPrivateKey.fromHex(privateKey);
    final publicAddress = ethereumKeyPair.address.hex;
    log.d(publicAddress);
    log.d(userInfo);
  }

  @override
  void onClose() {
    super.onClose();
  }
}
