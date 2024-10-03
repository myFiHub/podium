import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:particle_auth_core/evm.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class MyProfileController extends GetxController with BlockChainInteractions {
  final globalController = Get.find<GlobalController>();
  final isParticleActivatedOnFriendTech = false.obs;
  final isExternalWalletActivatedOnFriendTech = false.obs;
  final loadingParticleActivation = false.obs;
  final loadingExternalWalletActivation = false.obs;
  get liveExternalChainId {
    // final service=globalController.web3ModalService.
  }
  @override
  void onInit() {
    globalController.externalWalletChainId.listen((address) {
      if (address.isNotEmpty && externalWalletChianId == baseChainId) {
        checkExternalWalletActivation();
      }
    });
    checkParticleWalletActivation();
    checkExternalWalletActivation();
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

  Future<bool> checkParticleWalletActivation({bool? silent}) async {
    if (silent != true) {
      loadingParticleActivation.value = true;
    }
    final particleAddress = await Evm.getAddress();
    final activeWallets = await particle_friendTech_getActiveUserWallets(
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
        await particle_activate_friendtechWallet(chainId: baseChainId);
    loadingParticleActivation.value = false;
    isParticleActivatedOnFriendTech.value = activated;
  }

  activateExternalWallet() async {
    loadingExternalWalletActivation.value = true;
    if (externalWalletChianId != baseChainId) {
      Get.snackbar(
        "Chain not supported",
        "please switch to Base on the external wallet",
        colorText: Colors.orange,
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

    final particleAddress = await Evm.getAddress();
    final externalWalletAddress = globalController.connectedWalletAddress.value;
    if (externalWalletAddress.isEmpty) {
      isExternalWalletActivatedOnFriendTech.value = false;
      if (silent != true) {
        loadingExternalWalletActivation.value = false;
      }
      return false;
    } else {
      final activeWallets = await particle_friendTech_getActiveUserWallets(
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
