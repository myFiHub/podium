import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/gen/assets.gen.dart';

class ParticleWalletChainIcon extends GetWidget<GlobalController> {
  final int size;
  const ParticleWalletChainIcon({
    this.size = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final particleChain = controller.particleWalletChain(null);
      if (particleChain == null) {
        return const SizedBox();
      }
      return Container(
        height: size.toDouble(),
        child: Image.network(
          particleChain.icon,
        ),
      );
    });
  }
}

class ExternalWalletChainIcon extends GetWidget<GlobalController> {
  final int size;
  const ExternalWalletChainIcon({
    this.size = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final connectedExternalWalletAddress =
          controller.connectedWalletAddress.value;
      final externalWalletChainId = controller.externalWalletChainId.value;
      final externalChain = controller.externalWalletChain;
      String externalChainNetworkIcon = '';
      if (externalChain != null) {
        externalChainNetworkIcon =
            controller.particleWalletChain(externalWalletChainId)?.icon ?? '';
      }
      if (externalChainNetworkIcon == '') {
        externalChainNetworkIcon = movementChain.chainIcon ?? '';
      }
      if (connectedExternalWalletAddress == '' || externalChain == null) {
        return const SizedBox();
      }
      return Container(
        height: size.toDouble(),
        child: externalChainNetworkIcon == ''
            ? Assets.images.movementLogo.svg(
                width: size.toDouble(),
                height: size.toDouble(),
              )
            : Image.network(externalChainNetworkIcon ?? ''),
      );
    });
  }
}
