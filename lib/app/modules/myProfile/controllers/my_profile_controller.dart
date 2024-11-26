import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:particle_auth_core/evm.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getWeb3AuthWalletAddress.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/models/cheerBooEvent.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class Payments {
  int numberOfCheersReceived = 0;
  int numberOfBoosReceived = 0;
  int numberOfCheersSent = 0;
  int numberOfBoosSent = 0;
  Map<String, String> income = {};
  Payments(
      {this.numberOfCheersReceived = 0,
      this.numberOfBoosReceived = 0,
      this.numberOfCheersSent = 0,
      this.numberOfBoosSent = 0,
      required this.income});
}

class MyProfileController extends GetxController {
  final globalController = Get.find<GlobalController>();
  final isParticleActivatedOnFriendTech = false.obs;
  final isExternalWalletActivatedOnFriendTech = false.obs;
  final loadingParticleActivation = false.obs;
  final loadingExternalWalletActivation = false.obs;
  final isGettingPayments = false.obs;
  final payments = Rx(Payments(
    income: {},
  ));

  @override
  void onInit() {
    globalController.externalWalletChainId.listen((address) {
      if (address.isNotEmpty && externalWalletChianId == baseChainId) {
        checkExternalWalletActivation();
      }
    });
    _getPayments();
    // checkParticleWalletActivation();
    // checkExternalWalletActivation();
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  _getPayments() async {
    try {
      isGettingPayments.value = true;
      final (received, paid) = await (
        getReceivedPayments(
          userId: myId,
        ),
        getInitiatedPayments(
          userId: myId,
        )
      ).wait;
      final _payments = Payments(
        numberOfCheersReceived: 0,
        numberOfBoosReceived: 0,
        numberOfCheersSent: 0,
        numberOfBoosSent: 0,
        income: {},
      );

      received.forEach((element) {
        String thisIncome = '0.0';
        if (_payments.income[element.chainId] == null) {
          _payments.income[element.chainId] = thisIncome;
        }
        if (element.type == PaymentTypes.cheer ||
            element.type == PaymentTypes.boo) {
          thisIncome = (Decimal.parse(element.amount) * Decimal.parse("0.95"))
              .toString();
          if (element.type == PaymentTypes.cheer) {
            _payments.numberOfCheersReceived++;
          } else if (element.type == PaymentTypes.boo) {
            _payments.numberOfBoosReceived++;
          }
        } else {
          thisIncome = element.amount;
        }
        final addedDecimal = Decimal.parse(_payments.income[element.chainId]!) +
            Decimal.parse(thisIncome);
        _payments.income[element.chainId] = addedDecimal.toString();
      });
      paid.forEach((element) {
        if (element.type == PaymentTypes.cheer) {
          _payments.numberOfCheersSent++;
        } else if (element.type == PaymentTypes.boo) {
          _payments.numberOfBoosSent++;
        }
      });
      isGettingPayments.value = false;
      payments.value = _payments;
      payments.refresh();
    } catch (e) {
      log.e(e);
    }
  }

  Future<bool> checkParticleWalletActivation({bool? silent}) async {
    if (silent != true) {
      loadingParticleActivation.value = true;
    }
    final particleAddress =
        await web3AuthWalletAddress(); // await Evm.getAddress();
    if (particleAddress == null) {
      return false;
    }
    final activeWallets = await internal_friendTech_getActiveUserWallets(
      particleAddress: particleAddress,
      chainId: baseChainId,
    );

    final isActivated = activeWallets.isParticleWalletActive;
    isParticleActivatedOnFriendTech.value = isActivated;

    if (silent != true) {
      loadingParticleActivation.value = false;
    }

    return isActivated;
  }

  activateParticle() async {
    loadingParticleActivation.value = true;
    final isAlreadyActivated = await checkParticleWalletActivation(
      silent: true,
    );
    log.d('isAlreadyActivated: $isAlreadyActivated');
    if (isAlreadyActivated) {
      return;
    }
    final activated =
        await internal_activate_friendtechWallet(chainId: baseChainId);
    loadingParticleActivation.value = false;
    isParticleActivatedOnFriendTech.value = activated;
  }

  activateExternalWallet() async {
    loadingExternalWalletActivation.value = true;
    if (externalWalletChianId != baseChainId) {
      Toast.error(
        message:
            "Chain not supported, please switch to Base on the external wallet",
      );
      loadingExternalWalletActivation.value = false;
      return;
    }
    final isActivated = await checkExternalWalletActivation(silent: true);
    if (isActivated != false) {
      return;
    }
    final activated = await ext_activate_friendtechWallet(
      chainId: baseChainId,
    );
    loadingExternalWalletActivation.value = false;
    isExternalWalletActivatedOnFriendTech.value = activated;
  }

  Future<bool?> checkExternalWalletActivation({bool? silent}) async {
    if (loadingExternalWalletActivation.value) return null;
    if (externalWalletChianId != baseChainId) {
      isExternalWalletActivatedOnFriendTech.value = false;
      return false;
    }

    if (silent != true) {
      loadingExternalWalletActivation.value = true;
    }

    final particleAddress = await web3AuthWalletAddress(); // Evm.getAddress();
    if (particleAddress == null) {
      isExternalWalletActivatedOnFriendTech.value = false;
      if (silent != true) {
        loadingExternalWalletActivation.value = false;
      }
      return false;
    }
    final externalWalletAddress = globalController.connectedWalletAddress.value;
    if (externalWalletAddress.isEmpty) {
      isExternalWalletActivatedOnFriendTech.value = false;
      if (silent != true) {
        loadingExternalWalletActivation.value = false;
      }
      return false;
    } else {
      final activeWallets = await internal_friendTech_getActiveUserWallets(
        particleAddress: particleAddress,
        externalWalletAddress: externalWalletAddress,
        chainId: baseChainId,
      );
      final isActivated = activeWallets.isExternalWalletActive;
      isExternalWalletActivatedOnFriendTech.value = isActivated;
      if (silent != true) {
        loadingExternalWalletActivation.value = false;
      }
      return isActivated;
    }
  }

  openFeedbackPage() {
    launchUrl(
      Uri.parse(
        'https://docs.google.com/forms/u/1/d/1yj3GC6-JkFnWo1UiWj36sMISave9529x2fpqzHv2hIo/edit',
      ),
    );
  }
}
