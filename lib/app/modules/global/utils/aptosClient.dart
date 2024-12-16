import 'package:aptos/aptos.dart';
import 'package:aptos/coin_client.dart';
import 'package:aptos/models/entry_function_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
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
      // final coinType =
      //     "0x1::aptos_coin::AptosCoin"; // Replace with the actual coin type
      // final registered = await _registerCoinStore(coinType);
      // if (!registered) {
      //   return false;
      // }
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

// Function to check if CoinStore is registered
  static Future<bool> _isCoinStoreRegistered(String coinType) async {
    try {
      final resource = await client.getAccountResource(
          address, "0x1::coin::CoinStore<$coinType>");
      return resource != null;
    } catch (e) {
      return false;
    }
  }

// Function to register CoinStore
  static Future<bool> _registerCoinStore(String coinType) async {
    final registere = await _isCoinStoreRegistered(coinType);
    if (registere) {
      return true;
    }
    try {
      final payload = EntryFunctionPayload(
        functionId: "0x1::coin::register",
        typeArguments: [coinType],
        arguments: [],
      );
      final transactionRequest =
          await client.generateTransaction(account, payload);
      final signedTransaction =
          await client.signTransaction(account, transactionRequest);
      final result = await client.submitSignedBCSTransaction(signedTransaction);
      if (result['hash'] != null) {
        final transactionHash = result['hash'];
        while (true) {
          final transactionStatus =
              await client.getTransactionByHash(transactionHash);
          if (transactionStatus['type'] == 'user_transaction' &&
              transactionStatus['success'] == true) {
            return true;
          }
          await Future.delayed(const Duration(
              seconds: 5)); // Wait for 5 seconds before checking again
        }
      }
      return false;
    } catch (e) {
      log.e(e);
      return false;
    }
  }
}
