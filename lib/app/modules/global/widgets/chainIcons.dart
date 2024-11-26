import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/gen/assets.gen.dart';

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
        final externalChain = chainInfoByChainId(externalWalletChainId);
        externalChainNetworkIcon = externalChain.icon;
      }
      if (externalChainNetworkIcon == '') {
        externalChainNetworkIcon = movementChain.chainIcon ?? '';
      }
      if (connectedExternalWalletAddress == '' || externalChain == null) {
        return const SizedBox();
      }
      return Tooltip(
        message: externalChain.name,
        preferBelow: false,
        child: Container(
          height: size.toDouble(),
          child: externalChainNetworkIcon == ''
              ? Assets.images.movementLogo.svg(
                  width: size.toDouble(),
                  height: size.toDouble(),
                )
              : Image.network(externalChainNetworkIcon),
        ),
      );
    });
  }
}
