import 'package:aptos/aptos.dart';
import 'package:aptos/coin_client.dart';
import 'package:aptos/models/entry_function_payload.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';

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
    final contractAddress =
        "0xc898a3b0a7c3ddc9ff813eeca34981b6a42b0918057a7c18ecb9f4a6ae82eefb";
    // create transaction
    final payload = EntryFunctionPayload(
        functionId: "${contractAddress}::CheerOrBoo::cheer_or_boo",
        typeArguments: [],
        arguments: [
          address, // Replace with the target address
          [], // Replace with the list of supporter addresses
          true, // Replace with true for cheer, false for boo
          100, // Replace with the amount
        ]);

    final transactionRequest = await client.generateTransaction(
      account,
      payload,
    );
    final signedTransaction =
        await client.signTransaction(account, transactionRequest);
    final result = await client.submitSignedBCSTransaction(signedTransaction);
    return result;
  }
}
