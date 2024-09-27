import 'dart:convert';
import 'dart:math';

import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:particle_auth_core/particle_auth_core.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/contracts/cheerBoo.dart';
import 'package:podium/contracts/proxy.dart';
import 'package:podium/contracts/starsArena.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/logger.dart';
import 'package:particle_base/particle_base.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';

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
    final selectedChain = globalController.web3ModalService.selectedChain;

    if (selectedChain == null) {
      return;
    } else if (selectedChain.chainId != '30732') {
      await Get.snackbar("Not supported on ${selectedChain.name}",
          'Switch external wallet to Movement please');
      // final switched =
      //     await globalController.switchExternalWalletChain('30732');
      // if (!switched) {
      //   return;
      // }
    }
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

  Future<BigInt?> ext_getBuyPrice({
    required String sharesSubject,
    required num shareAmount,
  }) async {
    final globalController = Get.find<GlobalController>();
    final service = globalController.web3ModalService;

    // service.launchConnectedWallet();
    try {
      final sharesSubjectWallet = parsAddress(sharesSubject);
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
      final results = await Future.wait([
        EvmService.readContract(
          myAddress,
          BigInt.zero,
          contractAddress,
          methodName,
          parameters,
          abiJsonString,
        ),
        if (externalWalletAddress != null && externalWalletAddress!.isNotEmpty)
          EvmService.readContract(
            externalWalletAddress!,
            BigInt.zero,
            contractAddress,
            methodName,
            parameters,
            abiJsonString,
          ),
      ]);
      BigInt sum = BigInt.zero;
      for (var result in results) {
        if (result != null) {
          sum += BigInt.parse(result);
        }
      }
      return sum;
    } catch (e) {
      log.e('error : $e');
      return null;
    }
  }

  Future<bool> ext_buySharesWithReferrer({
    String referrer = ZERO_ADDRESS,
    required String sharesSubject,
    num shareAmount = 1,
  }) async {
    final bigIntValue = await ext_getBuyPrice(
        sharesSubject: sharesSubject, shareAmount: shareAmount);
    if (bigIntValue == null) {
      return false;
    }
    final value = bigIntValue.toInt();

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
      final response = await service.requestWriteContract(
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
      final success = response != null &&
          response is String &&
          response.startsWith("0x") &&
          response.length > 10;
      return success;
    } catch (e) {
      log.e('error : $e');
      return false;
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

  Future<bool> particle_buySharesWithReferrer({
    String referrer = ZERO_ADDRESS,
    required String sharesSubject,
    num shareAmount = 1,
  }) async {
    final buyPrice = await particle_getBuyPrice(
      sharesSubject: sharesSubject,
      shareAmount: shareAmount,
    );
    if (buyPrice == null) {
      return false;
    }
    final sharesSubjectWallet = sharesSubject;
    final myAddress = await Evm.getAddress();
    final contractAddress = StarsArenaSmartContract.address;
    final methodName = 'buySharesWithReferrer';
    final parameters = [sharesSubjectWallet, shareAmount.toString(), referrer];
    const abiJson = StarsArenaSmartContract.abi;
    final abiJsonString = jsonEncode(abiJson);
    try {
      final data = await EvmService.customMethod(
        contractAddress,
        methodName,
        parameters,
        abiJsonString,
      );
      final transaction = await EvmService.createTransaction(
        myAddress,
        data,
        buyPrice,
        contractAddress,
        gasFeeLevel: GasFeeLevel.high,
      );
      final signature = await Evm.sendTransaction(transaction);
      if (signature.length > 10) {
        return true;
      }
      return false;
    } catch (e) {
      log.e('error : $e ${((e as dynamic).data)}');
      if (e.toString().toLowerCase().contains('fund')) {
        final selectedChain = await ParticleBase.getChainInfo();
        final selectedChainName = selectedChain.name;
        final selectedChainCurrency = selectedChain.nativeCurrency.symbol;
        Get.snackbar(
          "Error:Insufficient $selectedChainCurrency",
          "Please top up your wallet on $selectedChainName",
          colorText: Colors.red,
          mainButton: TextButton(
            onPressed: () {
              _copyToClipboard(myAddress, prefix: "Address");
            },
            child: Text("Copy"),
          ),
        );
      } else {
        Get.snackbar(
          "Error",
          (e as dynamic).message,
          colorText: Colors.red,
        );
      }
      return false;
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

void _copyToClipboard(String text, {String? prefix}) {
  Clipboard.setData(ClipboardData(text: text)).then(
    (_) => Get.snackbar(
      "${prefix} Copied",
      "",
      colorText: Colors.green,
    ),
  );
}

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

class WalletNames {
  static const particle = "Particle Wallet";
  static const external = "External Wallet";
}

Future<String?> choseAWallet() async {
  if (externalWalletAddress == null) {
    return WalletNames.particle;
  }
  if (externalWalletAddress!.isEmpty) {
    return WalletNames.particle;
  }
  final store = GetStorage();
  final savedWallet = store.read(StorageKeys.selectedWalletName);
  if (savedWallet != null) {
    return savedWallet;
  }
  final selectedWallet = await Get.dialog(
    barrierDismissible: true,
    AlertDialog(
      title: Text("Choose a wallet"),
      backgroundColor: ColorName.cardBackground,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Button(
              text: "Particle Wallet",
              type: ButtonType.outline,
              color: ColorName.primaryBlue,
              blockButton: true,
              icon: Assets.images.particleIcon.image(
                width: 20,
                height: 20,
              ),
              onPressed: () {
                final shouldRemember = store.read("rememberWallet") ?? false;
                if (shouldRemember) {
                  store.write(
                      StorageKeys.selectedWalletName, WalletNames.particle);
                }
                Navigator.pop(Get.overlayContext!, WalletNames.particle);
              }),
          space10,
          Button(
              text: "External Wallet",
              type: ButtonType.outline,
              color: ColorName.primaryBlue,
              blockButton: true,
              onPressed: () {
                final shouldRemember = store.read("rememberWallet") ?? false;
                if (shouldRemember) {
                  store.write(
                      StorageKeys.selectedWalletName, WalletNames.external);
                }
                Navigator.pop(Get.overlayContext!, WalletNames.external);
              }),
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
      ),
    ),
  );
  return selectedWallet;
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
