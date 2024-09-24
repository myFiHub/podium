import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:particle_auth_core/particle_auth_core.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/contracts/cheerBoo.dart';
import 'package:podium/contracts/proxy.dart';
import 'package:podium/contracts/starsArena.dart';
import 'package:podium/utils/logger.dart';
import 'package:particle_base/particle_base.dart';

import 'package:reown_appkit/reown_appkit.dart';

final cheerBooContract = getContract(
  abi: CheerBoo.abi,
  address: CheerBoo.address,
  name: "CheerBoo",
);
final proxyContract = getContract(
  abi: ProxyContract.abi,
  address: ProxyContract.address,
  name: "TransparentUpgradeableProxy",
);
final starsArenaContract = getContract(
  abi: StarsArenaSmartContract.abi,
  address: StarsArenaSmartContract.address,
  name: "StarsArena",
);
mixin BlockChainInteractions {
  Future<dynamic> cheerOrBoo({
    required String target,
    required List<String> receiverAddresses,
    required num amount,
    required bool cheer,
  }) async {
    final globalController = Get.find<GlobalController>();
    final service = globalController.web3ModalService;
    final transaction = Transaction(
      from: parsAddress(service.session!.address!),
      value: parseValue(amount),
    );
    final targetWallet = parsAddress(target);
    final receivers = receiverAddresses.map((e) => parsAddress(e)).toList();
    service.launchConnectedWallet();

    try {
      final response = await service.requestWriteContract(
        topic: service.session!.topic,
        chainId: service.selectedChain!.chainId,
        deployedContract: cheerBooContract,
        functionName: 'cheerOrBoo',
        transaction: transaction,
        parameters: [
          targetWallet,
          receivers,
          cheer,
        ],
      );
      if (response == "User rejected") {
        Get.snackbar("Error", "transaction rejected");
      }
      if (response == null) {
        Get.snackbar("Error", "transaction failed");
        return null;
      } else {
        return response;
      }
    } catch (e) {
      log.e('error : $e');
      return null;
    }
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

  Future<BigInt?> getBuyPrice({
    required String sharesSubject,
    required num shareAmount,
  }) async {
    final globalController = Get.find<GlobalController>();
    final service = globalController.web3ModalService;
    final sharesSubjectWallet = parsAddress(sharesSubject);
    // service.launchConnectedWallet();
    try {
      final response = await service.requestReadContract(
        deployedContract: starsArenaContract,
        topic: service.session!.topic,
        chainId: service.selectedChain!.chainId,
        functionName: 'getBuyPriceAfterFee',
        parameters: [
          sharesSubjectWallet,
          BigInt.from(shareAmount),
        ],
      );
      final res = response[0] as BigInt;
      return res;
    } catch (e) {
      log.e('error : $e');
      return null;
    }
  }

  Future<BigInt?> ext_getMyShares({
    required String sharesSubject,
  }) async {
    final globalController = Get.find<GlobalController>();
    final service = globalController.web3ModalService;
    final sharesSubjectWallet = parsAddress(sharesSubject);
    try {
      final response = await service.requestReadContract(
        deployedContract: starsArenaContract,
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

  particle_getMyShares({
    required String sharesSubject,
  }) async {
    final sharesSubjectWallet = sharesSubject;
    final myAddress = await Evm.getAddress();
    final contractAddress = StarsArenaSmartContract.address;
    final methodName = 'getMyShares';
    final parameters = [sharesSubjectWallet];
    const abiJson = StarsArenaSmartContract.abi;
    final abiJsonString = jsonEncode(abiJson);

    try {
      final result = await EvmService.readContract(
        myAddress,
        BigInt.zero,
        contractAddress,
        methodName,
        parameters,
        abiJsonString,
      );
      if (result != null) {
        return BigInt.parse(result);
      }
    } catch (e) {
      log.e('error : $e');
      return null;
    }
  }

  ext_buySharesWithReferrer({
    String referrer = ZERO_ADDRESS,
    required String sharesSubject,
    required num shareAmount,
    required num value,
  }) {
    final globalController = Get.find<GlobalController>();
    final service = globalController.web3ModalService;
    final transaction = Transaction(
      from: parsAddress(service.session!.address!),
      value: parseValue(value),
    );

    final referrerWallet = parsAddress(referrer);
    final sharesSubjectWallet = parsAddress(sharesSubject);
    service.launchConnectedWallet();
    try {
      final response = service.requestWriteContract(
        topic: service.session!.topic,
        chainId: service.selectedChain!.chainId,
        deployedContract: starsArenaContract,
        functionName: 'buySharesWithReferrer',
        transaction: transaction,
        parameters: [
          sharesSubjectWallet,
          BigInt.from(shareAmount),
          referrerWallet,
        ],
      );
      return response;
    } catch (e) {
      log.e('error : $e');
      return null;
    }
  }

  Future<BigInt?> particle_getBuyPrice({
    required String sharesSubject,
    num shareAmount = 1,
  }) async {
    final sharesSubjectWallet = sharesSubject;
    final myAddress = await Evm.getAddress();
    final contractAddress = StarsArenaSmartContract.address;
    final methodName = 'getBuyPriceAfterFee';
    final parameters = [sharesSubjectWallet, shareAmount.toString()];
    const abiJson = StarsArenaSmartContract.abi;
    final abiJsonString = jsonEncode(abiJson);

    try {
      final result = await EvmService.readContract(
        myAddress,
        BigInt.zero,
        contractAddress,
        methodName,
        parameters,
        abiJsonString,
      );
      if (result != null) {
        return BigInt.parse(result);
      } else {
        return null;
      }
    } catch (e) {
      log.e('error : $e');
      return null;
    }
  }

  particle_buySharesWithReferrer({
    String referrer = ZERO_ADDRESS,
    required String sharesSubject,
    num shareAmount = 1,
  }) async {
    final buyPrice = await particle_getBuyPrice(
      sharesSubject: sharesSubject,
      shareAmount: shareAmount,
    );
    if (buyPrice == null) {
      return null;
    }
    final sharesSubjectWallet = sharesSubject;
    final myAddress = await Evm.getAddress();
    final contractAddress = StarsArenaSmartContract.address;
    final methodName = 'buySharesWithReferrer';
    final parameters = [sharesSubjectWallet, shareAmount, referrer];
    const abiJson = StarsArenaSmartContract.abi;
    final abiJsonString = jsonEncode(abiJson);
    try {
      final transaction = await EvmService.writeContract(
        myAddress,
        buyPrice,
        contractAddress,
        methodName,
        parameters,
        abiJsonString,
      );
      final signature = await Evm.sendTransaction(transaction);
      return signature;
    } catch (e) {
      log.e('error : $e');
      if (e.toString().contains('insufficient funds')) {
        Get.snackbar(
          "Error",
          "Insufficient funds",
          colorText: Colors.red,
        );
      }
      ;
      return null;
    }
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

DeployedContract getContract(
    {required abi, required String address, required String name}) {
  return DeployedContract(
    ContractAbi.fromJson(
      jsonEncode(abi),
      name,
    ),
    EthereumAddress.fromHex(address),
  );
}

double bigIntWeiToDouble(BigInt v) {
  final BigInt weiToEthRatio = BigInt.from(10).pow(18);
  final double vInEth = v.toDouble() / weiToEthRatio.toDouble();
  return vInEth;
}

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
