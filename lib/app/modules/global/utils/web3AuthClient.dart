import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/utils/getWeb3AuthWalletAddress.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3dart/web3dart.dart';
import "package:http/http.dart";

Web3Client _getClientByChainId(String chainId) {
  if (chainId == movementChainId) {
    return Web3Client(movementChain.rpcUrl, Client());
  }
  final rpcUrl = particleChainInfoByChainId(chainId).rpcUrl;
  final client = Web3Client(rpcUrl, Client());
  return client;
}

Future<EthPrivateKey> _getCredentials() async {
  final privateKey = await Web3AuthFlutter.getPrivKey();
  final credentials = EthPrivateKey.fromHex(privateKey);
  return credentials;
}

Future<String?> sendTransaction({
  required Transaction transaction,
  required String chainId,
}) async {
  try {
    final credentials = await _getCredentials();
    final client = _getClientByChainId(chainId);
    final transactionSigned = await client.sendTransaction(
      credentials,
      transaction,
      chainId: int.parse(chainId),
    );
    return transactionSigned;
  } catch (e) {
    log.e(e);
    final myAddress = await web3AuthWalletAddress();
    if (myAddress == null) {
      return null;
    }
    final stError = e.toString();
    if (stError.contains("insufficient funds") ||
        stError.contains("insufficient balance")) {
      final chainInfo = particleChainInfoByChainId(chainId);
      Toast.error(
        title: "Insufficient ${chainInfo.nativeCurrency.symbol}",
        message: "Please top up your wallet on ${chainInfo.name}",
        mainbutton: TextButton(
          onPressed: () {
            _copyToClipboard(myAddress, prefix: "Address");
          },
          child: Text("Copy Address"),
        ),
        duration: 5,
      );
    }
    return null;
  }
}

void _copyToClipboard(String text, {String? prefix}) async {
  await Get.closeCurrentSnackbar();
  Clipboard.setData(ClipboardData(text: text)).then(
    (_) => Toast.info(
      title: "${prefix} Copied",
      message: text,
    ),
  );
}
