import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/utils/getWeb3AuthWalletAddress.dart';
import 'package:podium/app/modules/global/utils/web3AuthClient.dart';
import 'package:podium/app/modules/global/utils/weiToDecimalString.dart';
import 'package:podium/env.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:podium/app/modules/global/blockchain/amounts.dart';
import 'package:podium/app/modules/global/blockchain/wallet_picker.dart';

Future<bool> ext_cheerOrBoo({
  required String target,
  required List<String> receiverAddresses,
  required num amount,
  required bool cheer,
  required String chainId,
  required groupId,
}) async {
  final service = web3ModalService;
  if (externalWalletChianId != chainId) {
    final chain =
        ReownAppKitModalNetworks.getNetworkInfo(Env.chainNamespace, chainId);
    try {
      if (chain == null) {
        return false;
      }
      Toast.error(
          message:
              "Please switch to ${chain.name} chain on your wallet and try again");
      return false;
    } catch (e) {
      l.e('Failed to switch chain: $e');
    }
  }
  final transaction = Transaction(
    from: parseAddress(externalWalletAddress!),
    value: parseValue(amount),
  );
  final targetWallet = parseAddress(target);
  final receivers = receiverAddresses.map((e) => parseAddress(e)).toList();
  final contract = getDeployedContract(
    contract: Contracts.cheerboo,
    chainId: chainId,
  );
  if (contract == null) {
    return false;
  }
  service.launchConnectedWallet();
  BigInt percentage = BigInt.from(100);
  // it's not possible to boo, and have more than one receiver
  if (!cheer) {
    percentage = BigInt.from(50);
  }
  // this means that the user is cheering themselves
  if (receiverAddresses.length > 1) {
    percentage = BigInt.from(0);
  }
  final parameters = [
    targetWallet,
    receivers,
    cheer,
    percentage,
    groupId,
  ];
  try {
    final response = await service.requestWriteContract(
      topic: service.session!.topic,
      chainId: service.selectedChain!.chainId,
      deployedContract: contract,
      functionName: 'cheerOrBoo',
      transaction: transaction,
      parameters: parameters,
    );
    if (response == "User rejected") {
      Toast.error(message: "Transaction rejected");
    }
    if (response == null) {
      Toast.error(message: "Transaction failed");
      return false;
    }
    return await externalTxSucceeded(response, chainId);
  } catch (e) {
    l.e('error : $e');
    return false;
  }
}

Future<bool?> internal_cheerOrBoo({
  required String target,
  required List<String> receiverAddresses,
  required num amount,
  required bool cheer,
  required String chainId,
  required LiveMember user,
  required groupId,
}) async {
  final myAddress = await web3AuthWalletAddress(); // Evm.getAddress();
  if (myAddress == null) {
    return false;
  }
  final contract =
      getDeployedContract(contract: Contracts.cheerboo, chainId: chainId);
  if (contract == null) {
    return null;
  }

  try {
    BigInt percentage = BigInt.from(100);
    // it's not possible to boo, and have more than one receiver
    if (!cheer) {
      percentage = BigInt.from(50);
    }
    // this means that the user is cheering themselves
    if (receiverAddresses.length > 1) {
      percentage = BigInt.from(0);
    }
    final value = parseValue(amount);
    const methodName = 'cheerOrBoo';
    final parameters = [
      parseAddress(target),
      receiverAddresses.map((e) => parseAddress(e)).toList(),
      cheer,
      percentage,
      groupId,
    ];
    final transaction = Transaction.callContract(
      contract: contract,
      function: contract.function(methodName),
      parameters: parameters,
      value: value,
    );

    late TransactionMetadata metadata;
    if (target == myAddress) {
      metadata = TransactionMetadata(
        title: cheer ? 'Cheer' : 'Boo',
        message: '${cheer ? 'Cheer' : 'Boo'} yourself',
        amount: weiToDecimalString(wei: value, decimals: 2),
      );
    } else {
      metadata = TransactionMetadata(
        title: cheer ? 'Cheer' : 'Boo',
        message: '${cheer ? 'Cheer' : 'Boo'} ${user.name}',
        amount: weiToDecimalString(wei: value, decimals: 2),
      );
    }
    final signature = await sendTransaction(
      transaction: transaction,
      chainId: chainId,
      metadata: metadata,
    );
    if (signature != null && signature.length > 10) {
      return true;
    }
    return false;
  } catch (e) {
    l.e('error : $e');
    if (e.toString().contains('insufficient funds')) {}
  }
  return false;

  ///
}
