import 'dart:async';
import 'dart:convert';

import 'package:aptos/aptos.dart';
import 'package:aptos/coin_client.dart';
import 'package:aptos/models/entry_function_payload.dart';
// import 'package:aptos_sdk_dart/aptos_sdk_dart.dart' as AptosSdkDart;
// import 'package:built_value/json_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/showConfirmPopup.dart';
import 'package:podium/env.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
// import 'package:web3auth_flutter/web3auth_flutter.dart';

class AptosMovement {
  AptosMovement._internal();
  static final AptosMovement _instance = AptosMovement._internal();
  factory AptosMovement() => _instance;

  static AptosClient get client {
    final globalController = Get.find<GlobalController>();
    final movementAptosProtoTestNetChain =
        globalController.movementAptosNetwork;
    return AptosClient(
      // movementAptosBardokChain.rpcUrl,
      movementAptosProtoTestNetChain.rpcUrl,
      enableDebugLog: Env.environment == DEVELOPMENT,
    );
  }

  static const _podiumProtocolName = 'PodiumProtocol';
  static const _cheerBooName = 'CheerOrBoo';

  static get podiumProtocolAddress {
    return movementAptosPodiumProtocolAddress;
  }

  static get cheerBooAddress {
    return movementAptosCheerBooAddress;
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

  static const String _indexerUrl =
      'https://indexer.mainnet.movementnetwork.xyz/v1/graphql';

  static Future<BigInt> _getBalanceFromIndexer(String address) async {
    try {
      final String query = '''
        query GetBalance(\$address: String!) {
          current_fungible_asset_balances(
            where: {
              owner_address: {_eq: \$address},
              asset_type: {_eq: "0x000000000000000000000000000000000000000000000000000000000000000a"}
            }
            limit: 1
          ) {
            amount
          }
        }
      ''';

      final response = await http.post(
        Uri.parse(_indexerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'variables': {'address': address},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final balances = data['data']['current_fungible_asset_balances'];
        if (balances != null && balances.isNotEmpty) {
          return BigInt.parse(balances[0]['amount'].toString());
        }
      }
      return BigInt.zero;
    } catch (e) {
      l.e('Error fetching balance from indexer: $e');
      return BigInt.zero;
    }
  }

  static Future<BigInt> getAddressBalance(String address) async {
    try {
      return await _getBalanceFromIndexer(address);
    } catch (e) {
      l.e(e);
      return BigInt.zero;
    }
  }

  static Future<BigInt> get balance async {
    final exists = await isMyAccountActive;
    if (!exists) {
      return BigInt.zero;
    }
    return await getAddressBalance(address);
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
          mainButton: TextButton(
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
      final res = await client.submitSignedBCSTransaction(signedTransaction);
      final hash = res['hash'];
      await client.waitForTransaction(hash, checkSuccess: true);
      return true;
    } catch (e) {
      l.e(e);
      Toast.error(message: 'Error submitting transaction');
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
      final bigIntPrice = BigInt.from(int.parse(pString));
      final parsedAmount = bigIntCoinToMoveOnAptos(bigIntPrice);
      return parsedAmount;
    } catch (e) {
      l.e(e);
      return null;
    }
  }

  static Future<BigInt?> getMyBalanceOnPodiumPass({
    String? myAddress,
    required String sellerAddress,
  }) async {
    try {
      final respone = await client.view(
        "${podiumProtocolAddress}::$_podiumProtocolName::get_balance",
        [],
        [
          myAddress ?? myUser.aptos_address,
          sellerAddress,
        ],
      );
      return BigInt.from(int.parse(respone[0]));
    } catch (e) {
      l.e(e);
      return null;
    }
  }

  Future<void> listenToEvents({
    required String address,
    required String eventHandle,
    required String fieldName,
  }) async {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        // Replace with the actual method to fetch events
        final events = await client.getEventsByEventHandle(
          address,
          eventHandle,
          fieldName,
          limit: 10, // Adjust the limit as needed
        );

        l.d(events);
      } catch (e) {
        print('Error fetching events: $e');
      }
    });
  }

  static Future<bool?> buyTicketFromTicketSellerOnPodiumPass({
    required String sellerAddress,
    required String sellerName,
    String referrer = '',
    int numberOfTickets = 1,
  }) async {
    try {
      final referrerAddress =
          referrer == '' ? Env.fihubAddress_Aptos : referrer;

      final price = await getTicketPriceForPodiumPass(
        sellerAddress: sellerAddress,
        numberOfTickets: numberOfTickets,
      );
      if (price == null) {
        return false;
      }
      final parsedPrice = price;
      final confirmed = await showConfirmPopup(
        title: 'Buy Podium Pass',
        richMessage: RichText(
          text: TextSpan(
            style: const TextStyle(height: 1.5),
            children: [
              const TextSpan(text: 'buy '),
              TextSpan(
                  text: numberOfTickets.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                  text: ' Podium Pass${numberOfTickets > 1 ? 'es' : ''} from '),
              TextSpan(
                  text: sellerName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' for '),
              TextSpan(
                  text: parsedPrice.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' MOVE?'),
            ],
          ),
        ),
        cancelText: 'Cancel',
        confirmText: 'Confirm',
      );

      if (!confirmed) {
        return null;
      }
      final payload = EntryFunctionPayload(
        functionId: "${podiumProtocolAddress}::$_podiumProtocolName::buy_pass",
        typeArguments: [],
        arguments: [
          sellerAddress,
          numberOfTickets.toString(),
          referrerAddress,
        ],
      );
      final transactionRequest = await client.generateTransaction(
        account,
        payload,
      );
      final signedTransaction =
          await client.signTransaction(account, transactionRequest);
      final res = await client.submitSignedBCSTransaction(signedTransaction);
      final hash = res['hash'];
      await client.waitForTransaction(hash, checkSuccess: true);
      return true;
    } catch (e, stackTrace) {
      l.e(e, stackTrace: stackTrace);
      final isCopyableError = e.toString().contains('Waiting for transaction');
      Toast.error(
        title: 'Error',
        message: isCopyableError
            ? e.toString()
            : 'Error Submiting Transaction, please try again later',
        mainButton: !isCopyableError
            ? null
            : TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: e.toString()));
                },
                child: const Text('Copy Error'),
              ),
      );
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
      l.e(e);
      return null;
    }
  }

  static Future<bool?> sellTicketOnPodiumPass({
    required String sellerAddress,
    required int numberOfTickets,
  }) async {
    try {
      final price = await getTicketSellPriceForPodiumPass(
        sellerAddress: sellerAddress,
        numberOfTickets: numberOfTickets,
      );
      if (price == null) {
        return null;
      }
      final parsedPrice = bigIntCoinToMoveOnAptos(price);
      final confirmed = await showConfirmPopup(
        title: 'Sell Podium Pass',
        richMessage: RichText(
          text: TextSpan(
            children: [
              const TextSpan(text: 'sell '),
              TextSpan(
                  text: numberOfTickets.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                  text: ' Podium Pass${numberOfTickets > 1 ? 'es' : ''} for '),
              TextSpan(
                  text: parsedPrice.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' MOVE?'),
            ],
          ),
        ),
        cancelText: 'Cancel',
        confirmText: 'Confirm',
      );
      if (!confirmed) {
        return null;
      }
      final payload = EntryFunctionPayload(
        functionId: "${podiumProtocolAddress}::$_podiumProtocolName::sell_pass",
        typeArguments: [],
        arguments: [sellerAddress, numberOfTickets.toString()],
      );
      final transactionRequest = await client.generateTransaction(
        account,
        payload,
      );
      final signedTransaction =
          await client.signTransaction(account, transactionRequest);
      final res = await client.submitSignedBCSTransaction(signedTransaction);
      final hash = res['hash'];
      await client.waitForTransaction(hash, checkSuccess: true);
      return true;
    } catch (e) {
      l.e(e);
      Toast.error(message: 'Error submitting transaction');
      return false;
    }
  }
}
