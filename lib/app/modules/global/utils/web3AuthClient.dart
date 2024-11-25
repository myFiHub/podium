import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/utils/logger.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3dart/web3dart.dart';
import "package:http/http.dart";

Web3Client _getClientByChainId(String chainId) {
  if (chainId == movementChainId) {
    return Web3Client(movementChain.chainId, Client());
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
    );
    return transactionSigned;
  } catch (e) {
    log.e(e);
    return null;
  }
}
