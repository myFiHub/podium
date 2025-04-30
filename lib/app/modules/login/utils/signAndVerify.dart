import 'dart:convert';

import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:web3dart/web3dart.dart';

/// signer is the public key of the signer or the private key of the signer
String? signMessage(String signer, String message) {
  try {
    final signature = EthSigUtil.signPersonalMessage(
      message: utf8.encode(message),
      privateKey: signer,
    );
    return signature;
  } catch (e) {
    return null;
  }
}

/// signer is the public key of the signer or the private key of the signer
bool verifySignature(String signature, String message, String signer) {
  try {
    final retreivedSigner = EthSigUtil.recoverPersonalSignature(
      message: utf8.encode(message),
      signature: signature,
    );
    return retreivedSigner == signer;
  } catch (e) {
    return false;
  }
}

String privateKeyToPublicKey(String privateKey) {
  final publicKey = EthPrivateKey.fromHex(privateKey).publicKey;
  return publicKey.toString();
}
