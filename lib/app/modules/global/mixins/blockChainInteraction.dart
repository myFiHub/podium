import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/utils/getWeb3AuthWalletAddress.dart';
import 'package:podium/app/modules/global/utils/web3AuthClient.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/cheerBooEvent.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/env.dart' as Environment;

import 'package:reown_appkit/reown_appkit.dart';

Future<bool> ext_cheerOrBoo({
  required String target,
  required List<String> receiverAddresses,
  required num amount,
  required bool cheer,
  required String chainId,
}) async {
  final service = web3ModalService;
  final transaction = Transaction(
    from: parsAddress(service.session!.address!),
    value: parseValue(amount),
  );
  final targetWallet = parsAddress(target);
  final receivers = receiverAddresses.map((e) => parsAddress(e)).toList();
  final contract = getDeployedContract(
    contract: Contracts.cheerboo,
    chainId: chainId,
  );
  if (contract == null) {
    return false;
  }
  service.launchConnectedWallet();

  try {
    final response = await service.requestWriteContract(
      topic: service.session!.topic,
      chainId: service.selectedChain!.chainId,
      deployedContract: contract,
      functionName: 'cheerOrBoo',
      transaction: transaction,
      parameters: [
        targetWallet,
        receivers,
        cheer,
      ],
    );
    if (response == "User rejected") {
      Toast.error(message: "transaction rejected");
    }
    if (response == null) {
      Toast.error(message: "transaction failed");
      return false;
    } else {
      return (response as String).startsWith('0x') && response.length > 10;
    }
  } catch (e) {
    log.e('error : $e');
    return false;
  }
}

internal_cheerOrBoo({
  required String target,
  required List<String> receiverAddresses,
  required num amount,
  required bool cheer,
  required String chainId,
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
    final methodName = 'cheerOrBoo';
    final parameters = [
      parsAddress(target),
      receiverAddresses.map((e) => parsAddress(e)).toList(),
      cheer
    ];
    final transaction = Transaction.callContract(
      contract: contract,
      function: contract.function(methodName),
      parameters: parameters,
      value: parseValue(amount),
    );
    final signature = await sendTransaction(
      transaction: transaction,
      chainId: chainId,
    );
    if (signature != null && signature.length > 10) {
      return true;
    }
    return false;
  } catch (e) {
    log.e('error : $e');
    if (e.toString().contains('insufficient funds')) {}
  }
  return false;

  ///
}

///  @param referrer: Optional parameter.
/// Represents the address of the referrer (if any).
/// If someone referred you to Stars Arena, you can pass their address here.
/// If there’s no referrer, you can leave this parameter empty or set it to the zero address (0x0000000000000000000000000000000000000000).
///
/// @param sharesSubject: Represents the address of the entity (user or contract) for whom you want to buy shares.
/// In the context of Stars Arena, this would typically be the address of the user who intends to purchase shares.
/// You’ll pass the Ethereum address (in hexadecimal format) as an argument when invoking this function.
///
/// @param amount: Specifies the number of shares you want to purchase.
/// It’s an unsigned integer (non-negative whole number).
/// You’ll provide the desired share quantity as an argument.
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
  // service.launchConnectedWallet();
  try {
    final sharesSubjectWallet = parsAddress(sharesSubject);
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
    log.d('response: $response');
    final res = response[0] as BigInt;
    return res;
  } catch (e) {
    log.e('error : $e');
    return null;
  }
}

Future<BigInt?> ext_getMyShares({
  required String sharesSubject,
  required String chainId,
}) async {
  final globalController = Get.find<GlobalController>();
  final service = globalController.web3ModalService;
  final sharesSubjectWallet = parsAddress(sharesSubject);
  final contract =
      getDeployedContract(contract: Contracts.starsArena, chainId: chainId);
  if (contract == null) {
    return null;
  }
  try {
    final response = await service.requestReadContract(
      deployedContract: contract,
      topic: service.session!.topic,
      chainId: service.selectedChain!.chainId,
      functionName: 'getMyShares',
      parameters: [
        sharesSubjectWallet,
      ],
    );
    final res = response[0] as BigInt;
    return res;
  } catch (e) {
    log.e('error : $e');
    return null;
  }
}

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
  final methodName = 'getMyShares';
  final parameters = [parsAddress(sharesSubjectWallet)];
  final client = web3ClientByChainId(chainId);
  try {
    final results = await Future.wait([
      client.call(
        contract: contract,
        sender: parsAddress(myAddress),
        function: contract.function(methodName),
        params: parameters,
      ),
      if (externalWalletAddress != null && externalWalletAddress!.isNotEmpty)
        client.call(
          contract: contract,
          sender: parsAddress(externalWalletAddress!),
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
    log.e('error : $e');
    return null;
  }
}

Future<UserActiveWalletOnFriendtech> internal_friendTech_getActiveUserWallets(
    {required String internalWalletAddress,
    String? externalWalletAddress,
    required String chainId}) async {
  final List<Future<BigInt?>> arrayToCall = [];

  try {
    arrayToCall.add(_internal_getShares_friendthech(
      sellerAddress: internalWalletAddress,
      buyerAddress: internalWalletAddress,
      chainId: chainId,
    ));
    if (externalWalletAddress != null &&
        externalWalletAddress.isNotEmpty &&
        externalWalletAddress != internalWalletAddress) {
      arrayToCall.add(_internal_getShares_friendthech(
        sellerAddress: externalWalletAddress,
        buyerAddress: externalWalletAddress,
        chainId: chainId,
      ));
    }
    final List<BigInt?> results = await Future.wait(arrayToCall);
    final isInternalWalletActiveOnFriendTechActive =
        results[0] != null && results[0] != BigInt.zero;
    bool isExternalActive = false;
    if (results.length > 1) {
      isExternalActive = results[1] != null && results[1] != BigInt.zero;
    }

    return UserActiveWalletOnFriendtech(
      isExternalWalletActive: isExternalActive,
      isInternalWalletActive: isInternalWalletActiveOnFriendTechActive,
      externalWalletAddress: externalWalletAddress,
      internalWalletAddress: internalWalletAddress,
    );
  } catch (e) {
    log.e('error : $e');
    return UserActiveWalletOnFriendtech(
      isExternalWalletActive: false,
      isInternalWalletActive: false,
      externalWalletAddress: externalWalletAddress,
      internalWalletAddress: internalWalletAddress,
    );
  }
}

Future<BigInt> internal_getUserShares_friendTech({
  required String defaultWallet,
  required String internalWallet,
  required String chainId,
}) async {
  try {
    BigInt numberOfShares = BigInt.zero;
    final myExternalWallet = externalWalletAddress;
    final myInternalWalletAddress =
        await web3AuthWalletAddress(); //Evm.getAddress();
    final List<Future<dynamic>> arrayToCall = [];
    // check if my internal wallet bought any of the user's addresses tickets
    arrayToCall.add(_internal_getShares_friendthech(
      sellerAddress: internalWallet,
      chainId: chainId,
    ));
    if (defaultWallet != internalWallet) {
      arrayToCall.add(_internal_getShares_friendthech(
        sellerAddress: defaultWallet,
        chainId: chainId,
      ));
    }

    // check if external wallet bought any of the user's addresses tickets
    if (myExternalWallet != null) {
      arrayToCall.add(_internal_getShares_friendthech(
        sellerAddress: internalWallet,
        chainId: chainId,
        buyerAddress: myExternalWallet,
      ));
      if (myExternalWallet != myInternalWalletAddress) {
        arrayToCall.add(_internal_getShares_friendthech(
          sellerAddress: defaultWallet,
          chainId: chainId,
          buyerAddress: myExternalWallet,
        ));
      }
    }

    final results = await Future.wait(arrayToCall);
    for (var result in results) {
      if (result != null) {
        numberOfShares += BigInt.parse(result.toString());
      }
    }
    return numberOfShares;
  } catch (e) {
    log.e('error : $e');
    Toast.error(message: "Could not get user shares");
    return BigInt.zero;
  }
}

Future<BigInt?> _internal_getShares_friendthech({
  required String sellerAddress,
  required String chainId,
  String? buyerAddress,
}) async {
  final buyerWalletAddress =
      buyerAddress ?? await web3AuthWalletAddress(); // Evm.getAddress();
  if (buyerWalletAddress == null) {
    return BigInt.zero;
  }
  final contract =
      getDeployedContract(contract: Contracts.friendTech, chainId: chainId);
  if (contract == null) {
    return null;
  }
  final methodName = 'sharesBalance';
  final client = web3ClientByChainId(chainId);
  try {
    final results = await Future.wait([
      client.call(
        contract: contract,
        function: contract.function(methodName),
        params: [parsAddress(sellerAddress), parsAddress(buyerWalletAddress)],
      ),
      // EvmService.readContract(
      //   buyerWalletAddress,
      //   BigInt.zero,
      //   contractAddress,
      //   methodName,
      //   parameters,
      //   abiJsonString,
      // ),
      if (externalWalletAddress != null && externalWalletAddress!.isNotEmpty)
        client.call(
          contract: contract,
          function: contract.function(methodName),
          params: [
            parsAddress(sellerAddress),
            parsAddress(externalWalletAddress!),
          ],
        ),
      // EvmService.readContract(
      //   externalWalletAddress!,
      //   BigInt.zero,
      //   contractAddress,
      //   methodName,
      //   parameters,
      //   abiJsonString,
      // ),
    ]);

    if (results[0][0] == '0x') {
      log.f(
          'result 0: ${results[0]}, contract might not be deployed on this chain');
      return BigInt.zero;
    }
    BigInt sum = BigInt.zero;
    for (var result in results) {
      if (result[0] != null) {
        sum += result[0];
      }
    }
    return sum;
  } catch (e) {
    log.e('error : $e');
    return null;
  }
}

Future<BigInt?> internal_getFriendTechTicketPrice({
  required String sharesSubject,
  int numberOfTickets = 1,
  required String chainId,
}) async {
  final sharesSubjectWallet = sharesSubject;
  final myAddress = await web3AuthWalletAddress(); //Evm.getAddress();
  if (myAddress == null) {
    return null;
  }
  final contract =
      getDeployedContract(contract: Contracts.friendTech, chainId: chainId);
  if (contract == null) {
    return null;
  }
  final methodName = 'getBuyPriceAfterFee';
  final parameters = [sharesSubjectWallet, numberOfTickets.toString()];
  try {
    final client = web3ClientByChainId(chainId);
    final result = await client.call(
      contract: contract,
      function: contract.function(methodName),
      params: parameters,
    );
    try {
      if (result[0] != null) {
        return result[0];
      } else {
        return null;
      }
    } catch (e) {
      log.e('error : $e');
      return null;
    }
  } catch (e) {
    log.e('error : $e');
    return null;
  }
}

Future<bool> internal_activate_friendtechWallet(
    {required String chainId}) async {
  try {
    final myWalletAddress = await web3AuthWalletAddress(); //Evm.getAddress();
    if (myWalletAddress == null) {
      return false;
    }
    final bought = await internal_buyFriendTechTicket(
      sharesSubject: myWalletAddress,
      chainId: chainId,
      targetUserId: myId,
    );
    return bought;
  } catch (e) {
    return false;
  }
}

Future<bool> ext_activate_friendtechWallet({
  required String chainId,
}) async {
  if (externalWalletAddress == null) {
    return false;
  }
  if (externalWalletAddress!.isEmpty) {
    return false;
  }
  final bought = await ext_buyFirendtechTicket(
    sharesSubject: externalWalletAddress!,
    chainId: chainId,
    targetUserId: myId,
  );
  return bought;
}

Future<bool> internal_buyFriendTechTicket({
  required String sharesSubject,
  int numberOfTickets = 1,
  required String chainId,
  required String targetUserId,
}) async {
  final sharesSubjectWallet = sharesSubject;
  final myAddress = await web3AuthWalletAddress(); // Evm.getAddress();
  if (myAddress == null) {
    return false;
  }
  final contract =
      getDeployedContract(contract: Contracts.friendTech, chainId: chainId);
  if (contract == null) {
    return false;
  }
  final buyPrice = await internal_getFriendTechTicketPrice(
    sharesSubject: sharesSubject,
    numberOfTickets: numberOfTickets,
    chainId: chainId,
  );
  if (buyPrice == null) {
    return false;
  }
  final methodName = 'buyShares';
  final parameters = [
    parsAddress(sharesSubjectWallet),
    BigInt.from(numberOfTickets),
  ];

  try {
    final transaction = Transaction.callContract(
      value: EtherAmount.fromBigInt(EtherUnit.wei, buyPrice),
      contract: contract,
      function: contract.function(methodName),
      parameters: parameters,
    );
    final signature =
        await sendTransaction(transaction: transaction, chainId: chainId);

    if (signature != null && signature.length > 10) {
      if (targetUserId != myId) {
        saveNewPayment(
          event: PaymentEvent(
            type: PaymentTypes.frienTechTicket,
            targetAddress: sharesSubjectWallet,
            amount: bigIntWeiToDouble(buyPrice).toString(),
            initiatorAddress: myAddress,
            initiatorId: myId,
            targetId: targetUserId,
            chainId: chainId,
          ),
        );
      }

      return true;
    }
    return false;
  } catch (e) {
    log.e('error : $e');

    return false;
  }
}

Future<bool> ext_buyFirendtechTicket({
  required String sharesSubject,
  int numberOfTickets = 1,
  required String chainId,
  required String targetUserId,
}) async {
  final buyPrice = await internal_getFriendTechTicketPrice(
    sharesSubject: sharesSubject,
    numberOfTickets: numberOfTickets,
    chainId: chainId,
  );
  if (buyPrice == null) {
    return false;
  }
  final globalController = Get.find<GlobalController>();
  final service = globalController.web3ModalService;
  final transaction = Transaction(
    from: parsAddress(service.session!.address!),
    value: parseValue(buyPrice.toDouble()),
  );
  final contract = getDeployedContract(
    contract: Contracts.friendTech,
    chainId: chainId,
  );
  if (contract == null) {
    return false;
  }
  final sharesSubjectWallet = parsAddress(sharesSubject);
  try {
    service.launchConnectedWallet();
    final response = await service.requestWriteContract(
      topic: service.session!.topic,
      chainId: service.selectedChain!.chainId,
      deployedContract: contract,
      functionName: 'buyShares',
      transaction: transaction,
      parameters: [
        sharesSubjectWallet,
        BigInt.from(numberOfTickets),
      ],
    );
    if (response == "User rejected") {
      Toast.error(message: "transaction rejected");
    }
    if (response == null) {
      Toast.error(message: "transaction failed");
      return false;
    } else {
      final isValid =
          (response as String).startsWith('0x') && response.length > 10;
      if (isValid && targetUserId != myId) {
        saveNewPayment(
          event: PaymentEvent(
            type: PaymentTypes.frienTechTicket,
            targetAddress: sharesSubjectWallet.hex,
            amount: bigIntWeiToDouble(buyPrice).toString(),
            initiatorAddress: externalWalletAddress!,
            initiatorId: myId,
            targetId: targetUserId,
            chainId: chainId,
          ),
        );
        return true;
      }
      return false;
    }
  } catch (e) {
    log.e('error : $e');

    return false;
  }
}

Future<bool> ext_buySharesWithReferrer({
  String? referrerAddress,
  required String sharesSubject,
  num shareAmount = 1,
  required String targetUserId,
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
    from: parsAddress(service.session!.address!),
    value: EtherAmount.inWei(bigIntValue),
  );
  final contract = getDeployedContract(
    contract: Contracts.starsArena,
    chainId: chainId,
  );
  if (contract == null) {
    return false;
  }

  final referrerWallet = parsAddress(referrer);
  final sharesSubjectWallet = parsAddress(sharesSubject);
  service.launchConnectedWallet();
  try {
    final response = await service.requestWriteContract(
      topic: service.session!.topic,
      chainId: service.selectedChain!.chainId,
      deployedContract: contract,
      functionName: 'buySharesWithReferrer',
      transaction: transaction,
      parameters: [
        sharesSubjectWallet,
        BigInt.from(shareAmount),
        referrerWallet,
      ],
    );
    final success = response != null &&
        response is String &&
        response.startsWith("0x") &&
        response.length > 10;
    if (success) {
      saveNewPayment(
        event: PaymentEvent(
          type: PaymentTypes.arenaTicket,
          targetAddress: sharesSubjectWallet.hex,
          amount: bigIntWeiToDouble(bigIntValue).toString(),
          initiatorAddress: externalWalletAddress!,
          initiatorId: myId,
          targetId: targetUserId,
          chainId: chainId,
        ),
      );
    }

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
    log.e('error : $e');
    return false;
  }
}

Future<BigInt?> internal_getBuyPrice({
  required String sharesSubject,
  num shareAmount = 1,
  required String chainId,
}) async {
  final sharesSubjectWallet = sharesSubject;
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
  final methodName = 'getBuyPriceAfterFee';
  final parameters = [
    parsAddress(sharesSubjectWallet),
    BigInt.from(shareAmount)
  ];

  try {
    final client = web3ClientByChainId(chainId);
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
    log.e('error : $e');
    return null;
  }
}

Future<bool> internal_buySharesWithReferrer({
  String? referrerAddress,
  required String sharesSubject,
  required String targetUserId,
  num shareAmount = 1,
  required String chainId,
}) async {
  final referrer = referrerAddress ?? fihubAddress(chainId);
  if (referrer == null) {
    Toast.error(message: "Referrer address not found");
    return false;
  }
  final buyPrice = await internal_getBuyPrice(
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

  final methodName = 'buySharesWithReferrer';
  final parameters = [
    parsAddress(sharesSubjectWallet),
    BigInt.from(shareAmount),
    parsAddress(referrer)
  ];
  try {
    final transaction = Transaction.callContract(
        value: EtherAmount.fromBigInt(EtherUnit.wei, buyPrice),
        contract: contract,
        function: contract.function(methodName),
        parameters: parameters);
    final signature =
        await sendTransaction(transaction: transaction, chainId: chainId);
    if (signature != null && signature.length > 10) {
      saveNewPayment(
        event: PaymentEvent(
          type: PaymentTypes.arenaTicket,
          targetAddress: sharesSubjectWallet,
          amount: bigIntWeiToDouble(buyPrice).toString(),
          initiatorAddress: myAddress,
          initiatorId: myId,
          targetId: targetUserId,
          chainId: chainId,
        ),
      );
      return true;
    }
    return false;
  } catch (e) {
    log.e('error : $e ${((e as dynamic).data)}');

    Toast.error(message: (e as dynamic).message);

    return false;
  }
}

int multiplier(BigInt decimals) {
  final d = decimals.toInt();
  final pad = '1'.padRight(d + 1, '0');
  return int.parse(pad);
}

BigInt formatValue(num value, {required BigInt decimals}) {
  final m = multiplier(decimals);
  final result = EtherAmount.fromInt(
    EtherUnit.ether,
    (value * m).toInt(),
  );
  return result.getInEther;
}

EthereumAddress parsAddress(String address) {
  return EthereumAddress.fromHex(address);
}

EtherAmount parseValue(num amount) {
  final v = formatValue(amount, decimals: BigInt.from(18));
  return EtherAmount.inWei(v);
}

BigInt doubleToBigIntWei(num v) {
  final BigInt weiToEthRatio = BigInt.from(10).pow(18);
  final BigInt vInWei = BigInt.from(v * weiToEthRatio.toInt());
  return vInWei;
}

double bigIntWeiToDouble(BigInt v) {
  final BigInt weiToEthRatio = BigInt.from(10).pow(18);
  final double vInEth = v.toDouble() / weiToEthRatio.toDouble();
  return vInEth;
}

String hexToAscii(String hexString) => List.generate(
      hexString.length ~/ 2,
      (i) => String.fromCharCode(
        int.parse(hexString.substring(i * 2, (i * 2) + 2), radix: 16),
      ),
    ).join();

void _copyToClipboard(String text, {String? prefix}) async {
  await Get.closeCurrentSnackbar();
  Clipboard.setData(ClipboardData(text: text)).then(
    (_) => Toast.info(
      title: "${prefix} Copied",
      message: text,
    ),
  );
}

String? fihubAddress(String chainId) {
  return Environment.Env.fihubAddress(chainId);
}

class WalletNames {
  static const internal = "Internal Wallet";
  static const external = "External Wallet";
}

Future<String?> choseAWallet({required String chainId}) async {
  if (externalWalletAddress == null) {
    return WalletNames.internal;
  }
  if (externalWalletAddress!.isEmpty) {
    return WalletNames.internal;
  }
  final store = GetStorage();
  final savedWallet = store.read(StorageKeys.selectedWalletName);
  if (savedWallet != null) {
    return savedWallet;
  }

  final selectedWallet = await Get.dialog(
    barrierDismissible: true,
    AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Choose a wallet"),
          space10,
          Img(
            src: chainInfoByChainId(chainId).chainIcon ??
                Assets.images.logo.path,
            alt: "logo",
            size: 20,
          ),
        ],
      ),
      backgroundColor: ColorName.cardBackground,
      content: SelectChainContent(
        chainId: chainId,
      ),
    ),
  );
  return selectedWallet;
}

class SelectChainContent extends GetView<GlobalController> {
  final String chainId;
  const SelectChainContent({super.key, required this.chainId});

  @override
  Widget build(BuildContext context) {
    final store = GetStorage();

    return Obx(() {
      final targetChainId = chainId;
      final externalChaiId = controller.externalWalletChainId.value;
      final externalWalletEnabled =
          externalChaiId.isNotEmpty && externalChaiId == targetChainId;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Button(
              text: "Podium Wallet",
              type: ButtonType.outline,
              color: ColorName.primaryBlue,
              blockButton: true,
              icon: Assets.images.logo.image(
                width: 20,
                height: 20,
              ),
              onPressed: () {
                final shouldRemember = store.read("rememberWallet") ?? false;
                if (shouldRemember) {
                  store.write(
                      StorageKeys.selectedWalletName, WalletNames.internal);
                }
                Navigator.pop(Get.overlayContext!, WalletNames.internal);
              }),
          space10,
          Button(
              text: "External Wallet",
              type: ButtonType.outline,
              color: ColorName.primaryBlue,
              blockButton: true,
              onPressed: externalWalletEnabled
                  ? () {
                      final shouldRemember =
                          store.read("rememberWallet") ?? false;
                      if (shouldRemember) {
                        store.write(StorageKeys.selectedWalletName,
                            WalletNames.external);
                      }
                      Navigator.pop(Get.overlayContext!, WalletNames.external);
                    }
                  : null),
          if (externalWalletEnabled == false)
            Text(
              "to use External Wallet, please switch to Avalanche chain (${targetChainId}) on your wallet and try again",
              style: TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          space10,
          // remember my choice
          RememberCheckBox(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(Get.overlayContext!, null);
                },
                child: Text("Cancel"),
              ),
            ],
          )
        ],
      );
    });
  }
}

class RememberCheckBox extends StatefulWidget {
  const RememberCheckBox({super.key});

  @override
  State<RememberCheckBox> createState() => _RememberCheckBoxState();
}

class _RememberCheckBoxState extends State<RememberCheckBox> {
  bool value = false;
  @override
  Widget build(BuildContext context) {
    final store = GetStorage();
    final savedValue = store.read("rememberWallet");
    if (savedValue != null && savedValue is bool && savedValue != value) {
      value = savedValue;
    }
    return GestureDetector(
      onTap: () {
        store.write("rememberWallet", !value);
        setState(() {
          value = !value;
        });
      },
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (value) {
              store.write("rememberWallet", value);
              setState(() {
                this.value = value!;
              });
            },
          ),
          Text("Remember my choice"),
        ],
      ),
    );
  }
}

class UserActiveWalletOnFriendtech {
  final bool isInternalWalletActive;
  final bool isExternalWalletActive;
  final String? externalWalletAddress;
  final String internalWalletAddress;
  bool get hasActiveWallet => isInternalWalletActive || isExternalWalletActive;
  String get preferedWalletAddress {
    if (isExternalWalletActive && externalWalletAddress != null) {
      return externalWalletAddress!;
    }
    return internalWalletAddress;
  }

  UserActiveWalletOnFriendtech({
    required this.isInternalWalletActive,
    required this.isExternalWalletActive,
    required this.externalWalletAddress,
    required this.internalWalletAddress,
  });
}
