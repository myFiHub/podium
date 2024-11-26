import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3dart/web3dart.dart';

String web3AuthAddress = '';

Future<String?> web3AuthWalletAddress() async {
  try {
    if (web3AuthAddress.isNotEmpty) {
      return web3AuthAddress;
    }
    final privateKey = await Web3AuthFlutter.getPrivKey();
    final ethereumKeyPair = EthPrivateKey.fromHex(privateKey);
    final publicAddress = ethereumKeyPair.address.hex;
    web3AuthAddress = publicAddress;
    return publicAddress;
  } catch (e) {
    return null;
  }
}
