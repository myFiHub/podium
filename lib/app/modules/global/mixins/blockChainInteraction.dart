import 'dart:convert';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/contracts/cheerBoo.dart';
import 'package:podium/utils/logger.dart';

import 'package:web3modal_flutter/web3modal_flutter.dart';

mixin BlockChainInteractions {
  final cheerBooContract = DeployedContract(
    ContractAbi.fromJson(
      jsonEncode(CheerBoo.abi),
      'CheerBoo',
    ),
    EthereumAddress.fromHex(CheerBoo.address),
  );

  Future<dynamic> cheerOrBoo({
    required String target,
    required List<String> receiverAddresses,
    required num amount,
    required bool cheer,
  }) async {
    final globalController = Get.find<GlobalController>();
    final service = globalController.web3ModalService;
    final valueToDistribute = formatValue(amount, decimals: BigInt.from(18));
    final transaction = Transaction(
      from: EthereumAddress.fromHex(service.session!.address!),
      value: EtherAmount.inWei(valueToDistribute),
    );
    final targetWallet = EthereumAddress.fromHex(target);
    final receivers =
        receiverAddresses.map((e) => EthereumAddress.fromHex(e)).toList();
    service.launchConnectedWallet();
    try {
      final response = await service.requestWriteContract(
        topic: service.session!.topic,
        chainId: service.selectedChain!.namespace,
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
