import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import "package:http/http.dart";
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/utils/getWeb3AuthWalletAddress.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3dart/web3dart.dart';

Web3Client web3ClientByChainId(String chainId) {
  if (chainId == movementChain.chainId) {
    return Web3Client(movementChain.rpcUrl, Client());
  }
  final rpcUrl = chainInfoByChainId(chainId).rpcUrl;
  final client = Web3Client(rpcUrl, Client());
  return client;
}

Future<EthPrivateKey> _getCredentials() async {
  final privateKey = await Web3AuthFlutter.getPrivKey();
  final credentials = EthPrivateKey.fromHex(privateKey);
  return credentials;
}

class TransactionMetadata {
  String title;
  String message;
  String amount;

  TransactionMetadata({
    required this.title,
    required this.message,
    required this.amount,
  });
}

Future<String?> sendTransaction({
  required Transaction transaction,
  required String chainId,
  required TransactionMetadata metadata,
}) async {
  try {
    final confirmed = await _showTransactionConfirmationDialog(
      metadata: metadata,
      chainId: chainId,
    );
    if (confirmed == null || !confirmed) {
      return null;
    }
    final credentials = await _getCredentials();
    final client = web3ClientByChainId(chainId);
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
      final chainInfo = chainInfoByChainId(chainId);
      Toast.error(
        title: "Insufficient ${chainInfo.currency}",
        message: "Please top up your wallet on ${chainInfo.name}",
        mainbutton: TextButton(
          onPressed: () {
            _copyToClipboard(myAddress, prefix: "Address");
          },
          child: const Text("Copy Address"),
        ),
        duration: 7,
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

_showTransactionConfirmationDialog({
  required TransactionMetadata metadata,
  required String chainId,
}) async {
  final chainInfo = chainInfoByChainId(chainId);
  final result = await Get.defaultDialog(
    backgroundColor: ColorName.cardBackground,
    title: metadata.title,
    content: Column(
      children: [
        Text(metadata.message),
        Text("Amount: ${metadata.amount} ${chainInfo.currency}"),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(Get.overlayContext!, false),
        child: const Text("Cancel"),
      ),
      TextButton(
        onPressed: () {
          Navigator.pop(Get.overlayContext!, true);
        },
        child: const Text("Confirm"),
      ),
    ],
  );
  return result;
}
