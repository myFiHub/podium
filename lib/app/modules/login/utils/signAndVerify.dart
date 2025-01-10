import 'dart:convert';

import 'package:eth_sig_util/eth_sig_util.dart';

String? signMessage(String privateKey, String message) {
  try {
    final signature = EthSigUtil.signPersonalMessage(
      message: utf8.encode(message),
      privateKey: privateKey,
    );
    return signature;
  } catch (e) {
    return null;
  }
}

bool verifySignature(String signature, String message, String address) {
  try {
    final senderAddress = EthSigUtil.recoverPersonalSignature(
      message: utf8.encode(message),
      signature: signature,
    );
    return senderAddress == address;
  } catch (e) {
    return false;
  }
}
