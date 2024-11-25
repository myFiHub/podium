import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3dart/web3dart.dart';

Future<String?> web3AuthWalletAddress() async {
  try {
    final privateKey = await Web3AuthFlutter.getPrivKey();
    final ethereumKeyPair = EthPrivateKey.fromHex(privateKey);
    final publicAddress = ethereumKeyPair.address.hex;
    return publicAddress;
  } catch (e) {
    return null;
  }
}
