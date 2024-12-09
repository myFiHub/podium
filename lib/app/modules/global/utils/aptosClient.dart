import 'dart:typed_data';

import 'package:aptos/aptos.dart';
import 'package:aptos/coin_client.dart';
import 'package:aptos/models/payload.dart';
import 'package:aptos/models/signature.dart';
import 'package:aptos/models/transaction.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed25519;
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
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
  }) async {
    final privateKey = await Web3AuthFlutter.getPrivKey();
    final seq = await sequenceNumber;
    final contractAddress =
        "0xc898a3b0a7c3ddc9ff813eeca34981b6a42b0918057a7c18ecb9f4a6ae82eefb";
    final maxGasAmount = '10000';
    final gasPrice = '100';
    final expirationTimestamp =
        ((DateTime.now().millisecondsSinceEpoch / 1000) + 300)
            .toString(); // Add a 5-min expiry
    // create transaction
  }
}
