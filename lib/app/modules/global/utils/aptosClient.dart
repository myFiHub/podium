import 'package:aptos/aptos.dart';
import 'package:aptos/coin_client.dart';
import 'package:aptos/models/entry_function_payload.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/env.dart';
import 'package:podium/utils/logger.dart';

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

  Future<bool> cheerBoo({
    required String target,
    required List<String> receiverAddresses,
    required num amount,
    required bool cheer,
    required String chainId,
    required groupId,
  }) async {
    try {
      final cheerBooAddress = Env.cheerBooAptosAddress;
      final amountToSend = doubleToBigIntMoveForAptos(amount).toString();
      int percentage = cheer ? 100 : 50;
      if (receiverAddresses.length > 1) {
        percentage = 0;
      }
      final PercentageString = percentage.toString();

      final payload = EntryFunctionPayload(
        functionId: "${cheerBooAddress}::CheerOrBooV2::cheer_or_boo",
        typeArguments: [],
        arguments: [
          // address,
          target,
          receiverAddresses,
          cheer,
          amountToSend,
          PercentageString,
          groupId,
        ],
      );
      final transactionRequest = await client.generateTransaction(
        account,
        payload,
      );
      final signedTransaction =
          await client.signTransaction(account, transactionRequest);
      final result = await client.submitSignedBCSTransaction(signedTransaction);
      if (result.isOk) {
        return true;
      }
      return false;
    } catch (e) {
      log.e(e);
      return false;
    }
  }
}
