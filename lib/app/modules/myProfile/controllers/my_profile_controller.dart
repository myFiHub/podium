import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:particle_auth_core/evm.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:url_launcher/url_launcher.dart';

class MyProfileController extends GetxController with BlockChainInteractions {
  final globalController = Get.find<GlobalController>();
  final isParticleActivatedOnFriendTech = false.obs;
  final isExternalWalletActivatedOnFriendTech = false.obs;
  final loadingParticleActivation = false.obs;
  final loadingExternalWalletActivation = false.obs;

  @override
  void onInit() {
    globalController.connectedWalletAddress.listen((address) {
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

  Future<bool> checkParticleWalletActivation() async {
    loadingParticleActivation.value = true;
    final particleAddress = await Evm.getAddress();
    final activeWallets = await particle_friendTech_getActiveUserWallets(
      particleAddress: particleAddress,
      chainId: baseChainId,
    );

    final isActivated = activeWallets.isParticleWalletActive;
    isParticleActivatedOnFriendTech.value = isActivated;
    loadingParticleActivation.value = false;
    return isActivated;
  }

  activateParticle() async {
    loadingParticleActivation.value = true;
    final activated =
        await particle_activate_friendtechWallet(chainId: baseChainId);
    loadingParticleActivation.value = false;
    isParticleActivatedOnFriendTech.value = activated;
  }

  activateExternalWallet() async {
    if (externalWalletChianId != baseChainId) {
      Get.snackbar(
        "Chain not supported",
        "please switch to Base on the external wallet",
        colorText: Colors.orange,
      );
      return;
    }
    loadingExternalWalletActivation.value = true;
    final activated = await ext_activate_friendtechWallet(
      chainId: baseChainId,
    );
    loadingExternalWalletActivation.value = false;
    isExternalWalletActivatedOnFriendTech.value = activated;
  }

  checkExternalWalletActivation() async {
    if (loadingExternalWalletActivation.value) return;
    if (externalWalletChianId != baseChainId) {
      isExternalWalletActivatedOnFriendTech.value = false;
      isExternalWalletActivatedOnFriendTech.value = false;
      return;
    }
    loadingExternalWalletActivation.value = true;
    final particleAddress = await Evm.getAddress();
    final externalWalletAddress = globalController.connectedWalletAddress.value;
    if (externalWalletAddress.isEmpty) {
      isExternalWalletActivatedOnFriendTech.value = false;
      loadingExternalWalletActivation.value = false;
      return;
    } else {
      final activeWallets = await particle_friendTech_getActiveUserWallets(
        particleAddress: particleAddress,
        externalWalletAddress: externalWalletAddress,
        chainId: baseChainId,
      );
      final isActivated = activeWallets.isExternalWalletActive;
      isExternalWalletActivatedOnFriendTech.value = isActivated;
      loadingExternalWalletActivation.value = false;
      return;
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
