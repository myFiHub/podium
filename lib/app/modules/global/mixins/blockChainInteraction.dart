import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:particle_auth_core/particle_auth_core.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/contracts/friendTech.dart';
import 'package:podium/contracts/starsArena.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/logger.dart';
import 'package:particle_base/particle_base.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/env.dart' as Environment;

import 'package:reown_appkit/reown_appkit.dart';

mixin BlockChainInteractions {
  Future<dynamic> ext_cheerOrBoo({
    required String target,
    required List<String> receiverAddresses,
    required num amount,
    required bool cheer,
    required String chainId,
  }) async {
    final globalController = Get.find<GlobalController>();
    final service = globalController.web3ModalService;
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
      return null;
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

  particle_getMyShares_arena({
    required String sharesSubject,
    required String chainId,
  }) async {
    final sharesSubjectWallet = sharesSubject;
    final myAddress = await Evm.getAddress();
    final contract =
        getDeployedContract(contract: Contracts.starsArena, chainId: chainId);
    if (contract == null) {
      return null;
    }
    final contractAddress = contract.address.hex;
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

  Future<BigInt?> particle_getMyShares_friendthech(
      {required String sharesSubject, required String chainId}) async {
    final sharesSubjectWallet = sharesSubject;
    final myAddress = await Evm.getAddress();
    final contract =
        getDeployedContract(contract: Contracts.friendTech, chainId: chainId);
    if (contract == null) {
      return null;
    }
    final contractAddress = contract.address.hex;
    final methodName = 'sharesBalance';
    final parameters = [myAddress, sharesSubjectWallet];
    const abiJson = FriendTechContract.abi;
    final abiJsonString = jsonEncode(abiJson);
    if (externalWalletChianId != '' &&
        externalWalletChianId != chainId &&
        externalWalletAddress != null &&
        externalWalletAddress!.isNotEmpty) {
      Get.snackbar(
        "Could't check external wallet address",
        "Please switch to ${chainNameById(chainId)} chain",
        colorText: Colors.red,
      );
    }
    final savedParticleChainId = particleChianId;

    final chainInfo = particleChainInfoByChainId(chainId);
    if (chainInfo == null) {
      log.f("chain info not found");
      return null;
    }
    if (chainInfo.id.toString() != savedParticleChainId) {
      await ParticleBase.setChainInfo(chainInfo);
    }
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
      final olderChainInfo = particleChainInfoByChainId(savedParticleChainId);
      if (chainId != savedParticleChainId && olderChainInfo != null) {
        await ParticleBase.setChainInfo(olderChainInfo);
      }
      if (results[0] == '0x') {
        log.f(
            'result 0: ${results[0]}, contract might not be deployed on this chain');
        return BigInt.zero;
      }

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

  Future<BigInt?> particle_getFriendTechTicketPrice({
    required String sharesSubject,
    int numberOfTickets = 1,
    required String chainId,
  }) async {
    final sharesSubjectWallet = sharesSubject;
    final myAddress = await Evm.getAddress();
    final contract =
        getDeployedContract(contract: Contracts.friendTech, chainId: chainId);
    if (contract == null) {
      return null;
    }
    final contractAddress = contract.address.hex;
    final methodName = 'getBuyPriceAfterFee';
    final parameters = [sharesSubjectWallet, numberOfTickets.toString()];
    const abiJson = FriendTechContract.abi;
    final abiJsonString = jsonEncode(abiJson);
    final savedChainId = particleChianId;
    final chainInfo = particleChainInfoByChainId(chainId);
    if (chainInfo == null) {
      log.f("chain info not found");
      return null;
    }
    if (chainInfo.id.toString() != savedChainId) {
      await ParticleBase.setChainInfo(chainInfo);
    }

    try {
      final result = await EvmService.readContract(
        myAddress,
        BigInt.zero,
        contractAddress,
        methodName,
        parameters,
        abiJsonString,
      );
      final olderChainInfo = particleChainInfoByChainId(savedChainId);
      if (chainId != savedChainId && olderChainInfo != null) {
        await ParticleBase.setChainInfo(olderChainInfo);
      }
      try {
        return BigInt.parse(result);
      } catch (e) {
        log.e('error : $e');
        return null;
      }
    } catch (e) {
      log.e('error : $e');
      if (chainInfo.id.toString() != savedChainId) {
        await ParticleBase.setChainInfo(chainInfo);
      }
      return null;
    }
  }

  particle_buyFriendTechTicket({
    required String sharesSubject,
    int numberOfTickets = 1,
    required String chainId,
  }) async {
    final sharesSubjectWallet = sharesSubject;
    final myAddress = await Evm.getAddress();
    final contract =
        getDeployedContract(contract: Contracts.friendTech, chainId: chainId);
    if (contract == null) {
      return false;
    }
    final buyPrice = await particle_getFriendTechTicketPrice(
      sharesSubject: sharesSubject,
      numberOfTickets: numberOfTickets,
      chainId: chainId,
    );
    if (buyPrice == null) {
      return false;
    }
    final contractAddress = contract.address.hex;
    final methodName = 'buyShares';
    final parameters = [sharesSubjectWallet, numberOfTickets.toString()];
    const abiJson = FriendTechContract.abi;
    final abiJsonString = jsonEncode(abiJson);
    final savedChainId = particleChianId;
    final chainInfo = particleChainInfoByChainId(chainId);
    if (chainInfo == null) {
      log.f("chain info not found");
      return false;
    }
    if (chainInfo.id.toString() != savedChainId) {
      await ParticleBase.setChainInfo(chainInfo);
    }

    final olderChainInfo = particleChainInfoByChainId(savedChainId);
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
      if (chainId != savedChainId && olderChainInfo != null) {
        await ParticleBase.setChainInfo(olderChainInfo);
      }
      if (signature.length > 10) {
        return true;
      }
      return false;
    } catch (e) {
      log.e('error : $e');
      if (chainId != savedChainId && olderChainInfo != null) {
        await ParticleBase.setChainInfo(olderChainInfo);
      }

      if (e
          .toString()
          .contains("Only the shares' subject can buy the first share")) {
        Get.snackbar("Error", "target user is not yet registered on friendtech",
            colorText: Colors.red);
      }

      return false;
    }
  }

  Future<bool> ext_buyFirendtechTicket({
    required String sharesSubject,
    int numberOfTickets = 1,
    required String chainId,
  }) async {
    final buyPrice = await particle_getFriendTechTicketPrice(
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
    service.launchConnectedWallet();
    try {
      final response = await service.requestWriteContract(
        topic: service.session!.topic,
        chainId: service.selectedChain!.chainId,
        deployedContract: contract,
        functionName: 'buyShares',
        transaction: transaction,
        parameters: [
          sharesSubjectWallet,
          numberOfTickets.toString(),
        ],
      );
      if (response == "User rejected") {
        Get.snackbar("Error", "transaction rejected");
      }
      if (response == null) {
        Get.snackbar("Error", "transaction failed");
        return false;
      } else {
        return true;
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
    required String chainId,
  }) async {
    final referrer = referrerAddress ?? fihubAddress(chainId);
    if (referrer == null) {
      Get.snackbar("Error", "Referrer address not found");
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
      return success;
    } on JsonRpcError catch (e) {
      if (e.message != null) {
        if (e.message!.contains('User denied transaction')) {
          Get.snackbar("Error", "Transaction rejected", colorText: Colors.red);
        } else {
          Get.snackbar("Error", e.message!, colorText: Colors.red);
        }
      }
      return false;
    } catch (e) {
      log.e('error : $e');
      return false;
    }
  }

  Future<BigInt?> particle_getBuyPrice({
    required String sharesSubject,
    num shareAmount = 1,
    required String chainId,
  }) async {
    final sharesSubjectWallet = sharesSubject;
    final myAddress = await Evm.getAddress();
    final contract = getDeployedContract(
      contract: Contracts.starsArena,
      chainId: chainId,
    );
    if (contract == null) {
      return null;
    }
    final contractAddress = contract.address.hex;
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
    String? referrerAddress,
    required String sharesSubject,
    num shareAmount = 1,
    required String chainId,
  }) async {
    final referrer = referrerAddress ?? fihubAddress(chainId);
    if (referrer == null) {
      Get.snackbar("Error", "Referrer address not found");
      return false;
    }
    final buyPrice = await particle_getBuyPrice(
      sharesSubject: sharesSubject,
      shareAmount: shareAmount,
      chainId: chainId,
    );
    if (buyPrice == null) {
      return false;
    }
    final sharesSubjectWallet = sharesSubject;
    final myAddress = await Evm.getAddress();
    final contract = getDeployedContract(
      contract: Contracts.starsArena,
      chainId: chainId,
    );
    if (contract == null) {
      return false;
    }

    final methodName = 'buySharesWithReferrer';
    final parameters = [sharesSubjectWallet, shareAmount.toString(), referrer];
    const abiJson = StarsArenaSmartContract.abi;
    final abiJsonString = jsonEncode(abiJson);
    try {
      final data = await EvmService.customMethod(
        contract.address.hex,
        methodName,
        parameters,
        abiJsonString,
      );
      final transaction = await EvmService.createTransaction(
        myAddress,
        data,
        buyPrice,
        contract.address.hex,
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

String? fihubAddress(String chainId) {
  return Environment.Env.fihubAddress(particleChianId);
}

class WalletNames {
  static const particle = "Particle Wallet";
  static const external = "External Wallet";
}

Future<String?> choseAWallet({required String chainId}) async {
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
