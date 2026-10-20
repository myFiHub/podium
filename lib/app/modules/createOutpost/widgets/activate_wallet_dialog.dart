import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/widgets/ui/app_ui.dart';

Future<bool?> showActivatePopup() async {
  return await Get.dialog<bool>(
    AppDialog(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Activate Wallet',
      message:
          'You need to activate your wallet to buy tickets for this event. Do you want to activate it now?',
      content: externalWalletAddress == null
          ? AppCallout(
              text:
                  'Your external wallet is disconnected, we checked against your Podium wallet address',
              color: AppColors.danger,
              icon: Icons.link_off_rounded,
            )
          : null,
      actions: [
        AppSecondaryButton(
          label: 'Cancel',
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(false);
          },
        ),
        AppPrimaryButton(
          label: 'Activate',
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(true);
          },
        ),
      ],
    ),
  );
}
