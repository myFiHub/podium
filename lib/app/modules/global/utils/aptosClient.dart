import 'package:aptos/aptos.dart';
import 'package:aptos/coin_client.dart';
import 'package:aptos/models/entry_function_payload.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/utils/logger.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';

class AptosMovement {
  AptosMovement._internal();
  static final AptosMovement _instance = AptosMovement._internal();
  factory AptosMovement() => _instance;

  static AptosClient get client {
    return AptosClient(
      aptosRpcUrl,
      enableDebugLog: true,
    );
  }

  static AptosAccount get account {
    return aptosAccount;
  }

  static Future<int> get sequenceNumber async {
    final accountInfo = await client.getAccount(address);
    final sequenceNumber = int.parse(accountInfo.sequenceNumber);
    return sequenceNumber;
  }

  static String get address {
    return account.address;
  }

  static Future<BigInt> get balance async {
    final exists = await client.accountExist(address);
    if (!exists) {
      return BigInt.zero;
    }
    return await _coinClient.checkBalance(address);
  }

  static CoinClient get _coinClient {
    return CoinClient(client);
  }

  cheerBoo({
    required List<dynamic> parameters,
    double amount = 0.01,
    bool isCheer = true,
  }) async {
    try {
      final privateKey = await Web3AuthFlutter.getPrivKey();
      final seq = await sequenceNumber;

      // expiration time is 5 min
      final expirationTimestamp =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300;

      final cheerBooAddress =
          '0xc898a3b0a7c3ddc9ff813eeca34981b6a42b0918057a7c18ecb9f4a6ae82eefb';
      final amountToSend = doubleToBigIntMoveForAptos(amount).toString();

      int percentage = isCheer ? 100 : 50;

      final PercentageString = percentage.toString();

      final payload = EntryFunctionPayload(
        functionId: "${cheerBooAddress}::CheerOrBooV2::cheer_or_boo",
        typeArguments: [],
        arguments: [
          address,
          '0x2a5e58b78fab84f7695a0ad4c99621090e6b8d7cbfc6d97cd3f07e7e3cbbd1c7',
          [],
          true,
          amountToSend,
          PercentageString,
          'ee241bbd-ebe8-455a-afe1-1bf42ebe611c'
        ],
      );
      final transactionRequest = await client.generateTransaction(
        account,
        payload,
      );

      final signedTransaction =
          await client.signTransaction(account, transactionRequest);
      // final result = await client.submitTransaction(signedTransaction);

      log.d(signedTransaction);
    } catch (e) {
      log.e(e);
    }
  }
}
