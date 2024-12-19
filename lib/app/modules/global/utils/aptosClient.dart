import 'package:aptos/aptos.dart';
import 'package:aptos/coin_client.dart';
import 'package:aptos/models/entry_function_payload.dart';
// import 'package:aptos_sdk_dart/aptos_sdk_dart.dart' as AptosSdkDart;
// import 'package:built_value/json_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/env.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
// import 'package:web3auth_flutter/web3auth_flutter.dart';

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

  static const _podiumProtocolName = 'PodiumProtocol';
  static const _cheerBooName = 'CheerOrBoo';

  static get podiumProtocolAddress {
    return Env.podiumProtocolAddress(movementAptosChainId);
  }

  static get cheerBooAddress {
    return Env.cheerBooAddress(movementAptosChainId);
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

  static Future<bool> get isMyAccountActive async {
    final exists = await client.accountExist(address);
    return exists;
  }

  static Future<BigInt> get balance async {
    final exists = await isMyAccountActive;
    if (!exists) {
      return BigInt.zero;
    }
    return await _coinClient.checkBalance(address);
  }

  static CoinClient get _coinClient {
    return CoinClient(client);
  }

  static Future<bool?> cheerBoo({
    required String target,
    required List<String> receiverAddresses,
    required num amount,
    required bool cheer,
    required groupId,
  }) async {
    try {
      final b = await balance;
      if (b < doubleToBigIntMoveForAptos(amount)) {
        Toast.error(
          title: 'Insufficient balance',
          mainbutton: TextButton(
            onPressed: () {
              final addr = address;
              Clipboard.setData(
                ClipboardData(text: addr),
              );
              Toast.info(
                title: 'Copied!',
                message: 'Address copied to clipboard',
              );
            },
            child: const Text(
              'Copy Address',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        );
        return null;
      }

      final amountToSend = doubleToBigIntMoveForAptos(amount).toString();
      int percentage = cheer ? 100 : 50;
      if (receiverAddresses.length > 1) {
        percentage = 0;
      }
      final PercentageString = percentage.toString();

      final payload = EntryFunctionPayload(
        functionId: "${cheerBooAddress}::$_cheerBooName::cheer_or_boo",
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
      await client.submitSignedBCSTransaction(signedTransaction);
      // if (result['hash'] != null) {
      //   final transactionStatus =
      //       await client.getTransactionByHash(result['hash']);
      //   log.d(transactionStatus);
      //   if (transactionStatus['success']) {
      //     return true;
      //   }
      // }
      return true;
    } catch (e) {
      log.e(e);
      return false;
    }
  }

  static Future<double?> getTicketPriceForPodiumPass({
    required String sellerAddress,
    int numberOfTickets = 1,
  }) async {
    try {
      final response = await client.view(
        "${podiumProtocolAddress}::$_podiumProtocolName::calculate_buy_price_with_fees",
        [],
        [
          sellerAddress,
          numberOfTickets.toString(),
          {"vec": []}
        ],
      );
      final pString = response[0];
      final bigIntPrice = BigInt.from(pString);
      final parsedAmount = bigIntCoinToMoveOnAptos(bigIntPrice);
      return parsedAmount;
    } catch (e) {
      log.e(e);
      return null;
    }
  }

  static Future<BigInt?> getMyBalanceOnPodiumPass({
    required String sellerAddress,
  }) async {
    try {
      final respone = await client.view(
        "${podiumProtocolAddress}::$_podiumProtocolName::get_balance",
        [],
        [
          myUser.aptosInternalWalletAddress,
          sellerAddress,
        ],
      );
      return BigInt.from(int.parse(respone[0]));
    } catch (e) {
      log.e(e);
      return null;
    }
  }

  static Future<bool> buyTicketFromTicketSellerOnPodiumPass({
    required String sellerAddress,
    int numberOfTickets = 1,
  }) async {
    try {
//////////////////////////////////
      ///
      // final privateKey = await Web3AuthFlutter.getPrivKey() as dynamic;
      // AptosSdkDart.AptosClientHelper aptosClientHelper =
      //     AptosSdkDart.AptosClientHelper(
      //   AptosSdkDart.AptosApiDart(
      //     basePathOverride: aptosRpcUrl,
      //   ),
      // );

      // AptosSdkDart.AptosAccount account =
      //     AptosSdkDart.AptosAccount.fromPrivateKeyHexString(privateKey);

      // // Build an entry function payload that transfers coin.
      // AptosSdkDart.TransactionPayloadBuilder transactionPayloadBuilder =
      //     AptosSdkDart.AptosClientHelper.buildPayload(
      //         "$podiumProtocolAddress::$_podiumProtocolName::buy_pass", [], [
      //   StringJsonObject(sellerAddress),
      //   StringJsonObject(numberOfTickets.toString()),
      // ]);

      // // Build a transasction request. This includes a call to determine the
      // // current sequence number so we can build that transasction.
      // AptosSdkDart.SubmitTransactionRequestBuilder
      //     submitTransactionRequestBuilder = await aptosClientHelper
      //         .generateTransaction(account.address, transactionPayloadBuilder);

      // // Convert the transaction into the appropriate format and then sign it.
      // submitTransactionRequestBuilder = await aptosClientHelper
      //     .encodeSubmission(account, submitTransactionRequestBuilder);

      // // Finally submit the transaction.
      // AptosSdkDart.PendingTransaction pendingTransaction =
      //     await AptosSdkDart.unwrapClientCall(aptosClientHelper.client
      //         .getTransactionsApi()
      //         .submitTransaction(
      //             submitTransactionRequest:
      //                 submitTransactionRequestBuilder.build()));

      // // Wait for the transaction to be committed.
      // AptosSdkDart.PendingTransactionResult pendingTransactionResult =
      //     await aptosClientHelper.waitForTransaction(pendingTransaction.hash);
      // log.d(pendingTransactionResult);
      // if (pendingTransactionResult.committed) {
      //   return true;
      // }
      // return false;
//////////////////////////////

      // final price = await getTicketSellPriceForPodiumPass(
      //   sellerAddress: sellerAddress,
      //   numberOfTickets: numberOfTickets,
      // );
      // if (price == null) {
      //   return false;
      // }
      final payload = EntryFunctionPayload(
        functionId: "${podiumProtocolAddress}::$_podiumProtocolName::buy_pass",
        typeArguments: [],
        arguments: [
          sellerAddress,
          numberOfTickets.toString(),
          myUser.aptosInternalWalletAddress
        ],
      );
      final transactionRequest = await client.generateTransaction(
        account,
        payload,
      );
      final signedTransaction =
          await client.signTransaction(account, transactionRequest);
      await client.submitSignedBCSTransaction(signedTransaction);
      return true;
    } catch (e, stackTrace) {
      log.e(e, stackTrace: stackTrace);
      return false;
    }
  }

  static Future<BigInt?> getTicketSellPriceForPodiumPass({
    required String sellerAddress,
    int numberOfTickets = 1,
  }) async {
    try {
      final response = await client.view(
        "${podiumProtocolAddress}::$_podiumProtocolName::calculate_sell_price_with_fees",
        [],
        [sellerAddress, numberOfTickets.toString()],
      );
      final price = response[0];
      return BigInt.from(int.parse(price));
    } catch (e) {
      log.e(e);
      return null;
    }
  }
}
