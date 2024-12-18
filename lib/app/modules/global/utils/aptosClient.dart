import 'package:aptos/aptos.dart';
import 'package:aptos/coin_client.dart';
import 'package:aptos/models/entry_function_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/env.dart';
import 'package:podium/services/toast/toast.dart';
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

  static Future<BigInt?> getTicketPriceForPodiumPass({
    required String sellerAddress,
    int numberOfTickets = 1,
  }) async {
    try {
      final price = await client.view(
        "${podiumProtocolAddress}::$_podiumProtocolName::calculate_buy_price_with_fees",
        [],
        [
          sellerAddress,
          numberOfTickets.toString(),
          {"vec": []}
        ],
      );
      return price;
    } catch (e) {
      log.e(e);
      return null;
    }
  }

  static Future<BigInt?> getTicketSellPriceForPodiumPass({
    required String sellerAddress,
    int numberOfTickets = 1,
  }) async {
    try {
      final price = await client.view(
        "${podiumProtocolAddress}::$_podiumProtocolName::calculate_sell_price_with_fees",
        [],
        [sellerAddress, numberOfTickets.toString()],
      );
      return price;
    } catch (e) {
      log.e(e);
      return null;
    }
  }
}
