import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/utils/web3AuthClient.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/ui/aurora.dart';

/// External wallets answer with the tx hash; anything else is a rejection or
/// failure. A hash still has to be mined successfully to count.
Future<bool> externalTxSucceeded(dynamic response, String chainId) async {
  if (response is! String ||
      !response.startsWith('0x') ||
      response.length <= 10) {
    return false;
  }
  return waitForEvmReceipt(chainId: chainId, txHash: response);
}

String? fihubAddress(String chainId) {
  return Env.fihubAddress(chainId);
}

class WalletNames {
  static const internal_EVM = "Internal EVM Wallet";
  static const internal_Aptos = "Internal Aptos Wallet";
  static const external = "External Wallet";
}

Future<String?> choseAWallet(
    {required String chainId, bool? supportsAptos}) async {
  final hideExternalWalletAndRemember =
      externalWalletAddress == null && supportsAptos == true;
  if (externalWalletAddress == null && supportsAptos != true) {
    return WalletNames.internal_EVM;
  }
  final store = GetStorage();
  final savedWallet = store.read(StorageKeys.selectedWalletName);
  if (savedWallet != null && supportsAptos != true) {
    return savedWallet;
  }

  final selectedWallet = await Get.dialog(
    barrierDismissible: true,
    AppDialogMotion(
      child: AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Choose a wallet"),
            space10,
            Img(
              src: chainInfoByChainId(chainId).chainIcon ??
                  Assets.images.logo.path,
              alt: "logo",
              size: 20,
            ),
          ],
        ),
        content: SelectChainContent(
          includeAptos: supportsAptos == true,
          chainId: chainId,
          hideExternalWalletAndRemember: hideExternalWalletAndRemember,
        ),
      ),
    ),
  );
  return selectedWallet;
}

class SelectChainContent extends GetView<GlobalController> {
  final String chainId;
  final bool includeAptos;
  final bool hideExternalWalletAndRemember;
  const SelectChainContent({
    super.key,
    required this.chainId,
    required this.includeAptos,
    required this.hideExternalWalletAndRemember,
  });

  @override
  Widget build(BuildContext context) {
    final store = GetStorage();

    return Obx(() {
      final targetChainId = chainId;
      final externalChaiId = controller.externalWalletChainId.value;
      final targetChain = chainInfoByChainId(chainId);
      final externalWalletEnabled =
          externalChaiId.isNotEmpty && externalChaiId == targetChainId;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Button(
              type: ButtonType.outline,
              color: ColorName.primaryBlue,
              blockButton: true,
              icon: Assets.images.logo.image(
                width: 20,
                height: 20,
              ),
              child: AutoSizeText(
                "Podium Wallet (${chainNameById(chainId)})",
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
              onPressed: () {
                final shouldRemember =
                    store.read(StorageKeys.rememberSelectedWallet) ?? false;
                if (shouldRemember) {
                  store.write(
                      StorageKeys.selectedWalletName, WalletNames.internal_EVM);
                }
                Navigator.pop(Get.overlayContext!, WalletNames.internal_EVM);
              }),
          space10,
          if (includeAptos)
            Button(
                text: "Podium Wallet (Aptos)",
                type: ButtonType.outline,
                color: ColorName.primaryBlue,
                blockButton: true,
                icon: Assets.images.logo.image(
                  width: 20,
                  height: 20,
                ),
                onPressed: () {
                  Navigator.pop(
                      Get.overlayContext!, WalletNames.internal_Aptos);
                }),
          space10,
          if (!hideExternalWalletAndRemember)
            Button(
                text: "External Wallet",
                type: ButtonType.outline,
                color: ColorName.primaryBlue,
                blockButton: true,
                onPressed: externalWalletEnabled
                    ? () {
                        final shouldRemember =
                            store.read(StorageKeys.rememberSelectedWallet) ??
                                false;
                        if (shouldRemember) {
                          store.write(StorageKeys.selectedWalletName,
                              WalletNames.external);
                        }
                        Navigator.pop(
                            Get.overlayContext!, WalletNames.external);
                      }
                    : null),
          if (externalWalletEnabled == false)
            Text(
              "to use External Wallet, please switch to ${targetChain.name} ($targetChainId) on your wallet and try again",
              style: TextStyle(color: ColorName.danger, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          space10,
          // remember my choice
          if (!hideExternalWalletAndRemember) const RememberCheckBox(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(Get.overlayContext!, null);
                },
                child: const Text("Cancel"),
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
    final savedValue = store.read(StorageKeys.rememberSelectedWallet);
    if (savedValue != null && savedValue is bool && savedValue != value) {
      value = savedValue;
    }
    return GestureDetector(
      onTap: () {
        store.write(StorageKeys.rememberSelectedWallet, !value);
        setState(() {
          value = !value;
        });
      },
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (value) {
              store.write(StorageKeys.rememberSelectedWallet, value);
              setState(() {
                this.value = value!;
              });
            },
          ),
          const Text("Remember my choice"),
        ],
      ),
    );
  }
}
