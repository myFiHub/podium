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
    l.e('error : $e');
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
    final myInternalWalletAddress = await web3AuthWalletAddress();
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
    l.e('error : $e');
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
  const methodName = 'sharesBalance';
  final client = evmClientByChainId(chainId);
  try {
    final results = await Future.wait([
      client.call(
        contract: contract,
        function: contract.function(methodName),
        params: [parseAddress(sellerAddress), parseAddress(buyerWalletAddress)],
      ),
      if (externalWalletAddress != null && externalWalletAddress!.isNotEmpty)
        client.call(
          contract: contract,
          function: contract.function(methodName),
          params: [
            parseAddress(sellerAddress),
            parseAddress(externalWalletAddress!),
          ],
        ),
    ]);

    if (results[0][0] == '0x') {
      l.f('result 0: ${results[0]}, contract might not be deployed on this chain');
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
    l.e('error : $e');
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
  const methodName = 'getBuyPriceAfterFee';
  final parameters = [
    parseAddress(sharesSubjectWallet),
    BigInt.from(numberOfTickets),
  ];
  try {
    final client = evmClientByChainId(chainId);
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
      l.e('error : $e');
      return null;
    }
  } catch (e) {
    l.e('error : $e');
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
  const methodName = 'buyShares';
  final parameters = [
    parseAddress(sharesSubjectWallet),
    BigInt.from(numberOfTickets),
  ];

  try {
    final value = EtherAmount.fromBigInt(EtherUnit.wei, buyPrice);
    final transaction = Transaction.callContract(
      value: value,
      contract: contract,
      function: contract.function(methodName),
      parameters: parameters,
    );
    final isValueZero = buyPrice == BigInt.zero;
    final metadata = TransactionMetadata(
      title: isValueZero ? "Activation" : 'Buy Ticket',
      message:
          isValueZero ? "Activate Wallet Address" : 'Buy FriendTech Ticket',
      amount: weiToDecimalString(wei: value),
    );
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
    from: parseAddress(externalWalletAddress!),
    value: EtherAmount.inWei(buyPrice),
  );
  final contract = getDeployedContract(
    contract: Contracts.friendTech,
    chainId: chainId,
  );
  if (contract == null) {
    return false;
  }
  final sharesSubjectWallet = parseAddress(sharesSubject);
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
      Toast.error(message: "Transaction rejected");
    }
    if (response == null) {
      Toast.error(message: "Transaction failed");
      return false;
    } else {
      final isValid = await externalTxSucceeded(response, chainId);
      return isValid;
    }
  } catch (e) {
    l.e('error : $e');

    return false;
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
