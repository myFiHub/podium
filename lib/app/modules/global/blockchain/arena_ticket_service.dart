import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/utils/getWeb3AuthWalletAddress.dart';
import 'package:podium/app/modules/global/utils/web3AuthClient.dart';
import 'package:podium/app/modules/global/utils/weiToDecimalString.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:podium/app/modules/global/blockchain/amounts.dart';
import 'package:podium/app/modules/global/blockchain/wallet_picker.dart';

Future<BigInt?> getMyShares_arena({
  required String sharesSubject,
  required String chainId,
}) async {
  final sharesSubjectWallet = sharesSubject;
  final myAddress = await web3AuthWalletAddress(); //await Evm.getAddress();
  if (myAddress == null) {
    return null;
  }
  final contract =
      getDeployedContract(contract: Contracts.starsArena, chainId: chainId);
  if (contract == null) {
    return null;
  }
  const methodName = 'getMyShares';
  final parameters = [
    parseAddress(sharesSubjectWallet),
  ];
  final client = evmClientByChainId(chainId);
  try {
    final results = await Future.wait([
      client.call(
        contract: contract,
        sender: parseAddress(myAddress),
        function: contract.function(methodName),
        params: parameters,
      ),
      if (externalWalletAddress != null && externalWalletAddress!.isNotEmpty)
        client.call(
          contract: contract,
          sender: parseAddress(externalWalletAddress!),
          function: contract.function(methodName),
          params: parameters,
        ),
    ]);
    BigInt sum = BigInt.zero;
    for (var result in results) {
      if (result[0] != null) {
        sum += result[0];
      }
    }
    return sum;
  } catch (e) {
    l.e('error : $e');
    return null;
  }
}

Future<bool> ext_buySharesWithReferrer({
  String? referrerAddress,
  required String sharesSubject,
  num shareAmount = 1,
  String? targetUserId,
  required String chainId,
}) async {
  final referrer = referrerAddress ?? fihubAddress(chainId);
  if (referrer == null) {
    Toast.error(message: "Referrer address not found");
    return false;
  }
  final bigIntValue = await ext_getBuyPrice(
    sharesSubject: sharesSubject,
    shareAmount: shareAmount,
    chainId: chainId,
  );
  if (bigIntValue == null) {
    return false;
  }

  final globalController = Get.find<GlobalController>();
  final service = globalController.web3ModalService;
  final transaction = Transaction(
    from: parseAddress(externalWalletAddress!),
    value: EtherAmount.inWei(bigIntValue),
  );
  final contract = getDeployedContract(
    contract: Contracts.starsArena,
    chainId: chainId,
  );
  if (contract == null) {
    return false;
  }

  final referrerWallet = parseAddress(referrer);
  final sharesSubjectWallet = parseAddress(sharesSubject);
  service.launchConnectedWallet();
  try {
    final response = await service.requestWriteContract(
      topic: service.session!.topic,
      chainId: service.selectedChain!.chainId,
      deployedContract: contract,
      functionName: 'buySharesWithReferrerForUser',
      transaction: transaction,
      parameters: [
        sharesSubjectWallet,
        parseAddress(externalWalletAddress!),
        BigInt.from(shareAmount),
        referrerWallet,
      ],
    );
    final success = await externalTxSucceeded(response, chainId);

    return success;
  } on JsonRpcError catch (e) {
    if (e.message != null) {
      if (e.message!.contains('User denied transaction')) {
        Toast.error(message: "Transaction rejected");
      } else {
        Toast.error(message: e.message!);
      }
    }
    return false;
  } catch (e) {
    l.e('error : $e');
    return false;
  }
}

Future<BigInt?> getBuyPriceForArenaTicket({
  required String sharesSubject,
  num shareAmount = 1,
  required String chainId,
}) async {
  final myAddress = await web3AuthWalletAddress(); // Evm.getAddress();
  if (myAddress == null) {
    return null;
  }
  final contract = getDeployedContract(
    contract: Contracts.starsArena,
    chainId: chainId,
  );
  if (contract == null) {
    return null;
  }
  const methodName = 'getBuyPriceAfterFee';
  final parameters = [parseAddress(sharesSubject), BigInt.from(shareAmount)];

  try {
    final client = evmClientByChainId(chainId);
    final result = await client.call(
      contract: contract,
      function: contract.function(methodName),
      params: parameters,
    );
    if (result[0] != null) {
      return result[0];
    } else {
      return null;
    }
  } catch (e) {
    l.e('error : $e');
    return null;
  }
}

Future<bool> internal_buySharesWithReferrer({
  String? referrerAddress,
  required String sharesSubject,
  String? targetUserId,
  num shareAmount = 1,
  required String chainId,
}) async {
  String? referrer = referrerAddress;
  if (referrer == null || referrer.isEmpty) {
    referrer = fihubAddress(chainId);
  }

  if (referrer == null) {
    Toast.error(message: "Referrer address not found");
    return false;
  }
  final buyPrice = await getBuyPriceForArenaTicket(
    sharesSubject: sharesSubject,
    shareAmount: shareAmount,
    chainId: chainId,
  );
  if (buyPrice == null) {
    return false;
  }

  final sharesSubjectWallet = sharesSubject;
  final myAddress = await web3AuthWalletAddress(); //Evm.getAddress();
  if (myAddress == null) {
    return false;
  }
  final contract = getDeployedContract(
    contract: Contracts.starsArena,
    chainId: chainId,
  );
  if (contract == null) {
    return false;
  }

  const methodName = 'buySharesWithReferrerForUser';
  final parameters = [
    parseAddress(sharesSubjectWallet),
    parseAddress(myAddress),
    BigInt.from(shareAmount),
    parseAddress(referrer)
  ];
  try {
    final value = EtherAmount.fromBigInt(EtherUnit.wei, buyPrice);
    final transaction = Transaction.callContract(
      value: value,
      contract: contract,
      function: contract.function(methodName),
      parameters: parameters,
    );

    final metadata = TransactionMetadata(
      title: 'Buy Ticket',
      message: 'Buy Arena Ticket',
      amount: weiToDecimalString(wei: value),
    );

    final signature = await sendTransaction(
        transaction: transaction, chainId: chainId, metadata: metadata);

    if (signature != null && signature.length > 10) {
      return true;
    }
    return false;
  } catch (e) {
    l.e('error : $e ${((e as dynamic).data)}');

    Toast.error(message: (e as dynamic).message);

    return false;
  }
}

///  @param referrer: Optional parameter.
/// Represents the address of the referrer (if any).
/// If someone referred you to Stars Arena, you can pass their address here.
/// If there's no referrer, you can leave this parameter empty or set it to the zero address (0x0000000000000000000000000000000000000000).
///
/// @param sharesSubject: Represents the address of the entity (user or contract) for whom you want to buy shares.
/// In the context of Stars Arena, this would typically be the address of the user who intends to purchase shares.
/// You'll pass the Ethereum address (in hexadecimal format) as an argument when invoking this function.
///
/// @param amount: Specifies the number of shares you want to purchase.
/// It's an unsigned integer (non-negative whole number).
/// You'll provide the desired share quantity as an argument.
///

Future<BigInt?> ext_getBuyPrice({
  required String sharesSubject,
  required num shareAmount,
  required String chainId,
}) async {
  final globalController = Get.find<GlobalController>();
  final service = globalController.web3ModalService;
  final contract =
      getDeployedContract(contract: Contracts.starsArena, chainId: chainId);
  if (contract == null) {
    return null;
  }
  try {
    final sharesSubjectWallet = parseAddress(sharesSubject);
    final response = await service.requestReadContract(
      deployedContract: contract,
      topic: service.session!.topic,
      chainId: service.selectedChain!.chainId,
      functionName: 'getBuyPriceAfterFee',
      parameters: [
        sharesSubjectWallet,
        BigInt.from(shareAmount),
      ],
    );
    l.d('response: $response');
    final res = response[0] as BigInt;
    return res;
  } catch (e) {
    l.e('error : $e');
    return null;
  }
}
