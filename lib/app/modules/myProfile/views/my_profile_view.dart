import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/loginType.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:web3modal_flutter/utils/util.dart';

import '../controllers/my_profile_controller.dart';

class MyProfileView extends GetView<MyProfileController> {
  const MyProfileView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              UserInfo(),
              // Button(
              //   onPressed: () {},
              //   type: ButtonType.outline,
              //   blockButton: true,
              //   text: 'Edit Profile',
              // ),
              space10,
              WalletInfo(),
              ParticleWalletManager(),
              WalletConnect(),
            ],
          ),
        ),
      ),
    );
  }
}

class ParticleWalletManager extends GetWidget<GlobalController> {
  const ParticleWalletManager({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          final particleAuthUserInfo = controller.particleAuthUserInfo.value;
          final wallets = particleAuthUserInfo?.wallets ?? [];
          return particleAuthUserInfo == null
              ? Container()
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: ColorName.greyText,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Particle Wallets',
                        style: const TextStyle(
                          fontSize: 33,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      space10,
                      ...wallets
                          .where((w) => w.publicAddress.isNotEmpty)
                          .toList()
                          .map(
                            (wallet) => GestureDetector(
                              onTap: () async {
                                await Clipboard.setData(
                                  ClipboardData(
                                    text: wallet.publicAddress,
                                  ),
                                );
                                Get.snackbar(
                                  'Copied',
                                  'Wallet address copied to clipboard',
                                  colorText: Colors.white,
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    color: ColorName.greyText,
                                  ),
                                  space10,
                                  Text(
                                    Util.truncate(
                                      wallet.publicAddress,
                                      length: 6,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w700,
                                      color: ColorName.greyText,
                                    ),
                                  ),
                                  space10,
                                ],
                              ),
                            ),
                          )
                          .toList()
                    ],
                  ),
                );
        }),
      ],
    );
  }
}

class WalletInfo extends GetWidget<GlobalController> {
  const WalletInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          final connectedWalletAddress =
              controller.connectedWalletAddress.value;
          return connectedWalletAddress == ''
              ? Container()
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: ColorName.greyText,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Text(
                        'Connected Wallet',
                        style: const TextStyle(
                          fontSize: 33,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      space10,
                      GestureDetector(
                          onTap: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: connectedWalletAddress,
                              ),
                            );
                            Get.snackbar(
                              'Copied',
                              'Wallet address copied to clipboard',
                              colorText: Colors.white,
                            );
                          },
                          child: Text(
                            Util.truncate(
                              connectedWalletAddress,
                              length: 6,
                            ),
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: ColorName.greyText,
                            ),
                          )),
                    ],
                  ));
        }),
      ],
    );
  }
}

class WalletConnect extends GetWidget<GlobalController> {
  const WalletConnect({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final walletConnected = controller.connectedWalletAddress.value;
        return Column(
          children: [
            walletConnected != ''
                ? Button(
                    onPressed: () {
                      controller.web3ModalService.disconnect();
                    },
                    type: ButtonType.outline,
                    color: ButtonColors.WARNING,
                    textColor: Colors.red,
                    borderSide: const BorderSide(color: Colors.red),
                    blockButton: true,
                    text: 'Disconnect Wallet',
                  )
                : Button(
                    onPressed: () {
                      controller.connectToWallet();
                    },
                    type: ButtonType.gradient,
                    blockButton: true,
                    text: 'Connect Wallet',
                  ),
            space10,
            space10,
            Obx(() {
              final isLoggingOut = controller.isLoggingOut.value;
              return Button(
                loading: isLoggingOut,
                onPressed: () {
                  final globalController = Get.find<GlobalController>();
                  globalController.setLoggedIn(false);
                },
                type: ButtonType.solid,
                blockButton: true,
                color: ButtonColors.DANGER,
                text: 'Logout',
              );
            })
          ],
        );
      },
    );
  }
}

class UserInfo extends GetWidget<GlobalController> {
  const UserInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final myUser = controller.currentUserInfo.value;
      if (myUser == null) {
        return Container();
      }
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GFAvatar(
              backgroundImage: NetworkImage(myUser.avatar),
              shape: GFAvatarShape.standard,
              size: 100,
            ),
            space10,
            space10,
            Text(
              myUser.fullName,
              style: const TextStyle(
                fontSize: 33,
                fontWeight: FontWeight.w700,
              ),
            ),
            space10,
            if (GetStorage().read(StorageKeys.loginType) != LoginType.x)
              Text(
                myUser.email,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: ColorName.greyText,
                ),
              ),
          ],
        ),
      );
    });
  }
}
