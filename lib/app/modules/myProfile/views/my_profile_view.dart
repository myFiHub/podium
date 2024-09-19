import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/loginType.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';

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

class ParticleWalletManager extends GetView<GlobalController> {
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
                          .where((w) =>
                              w.publicAddress.isNotEmpty &&
                              w.chainName == 'evm_chain')
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
                                    truncate(
                                      wallet.publicAddress,
                                      length: 12,
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

class WalletInfo extends GetView<GlobalController> {
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
                            truncate(
                              connectedWalletAddress,
                              length: 12,
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

class WalletConnect extends GetView<GlobalController> {
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
                      controller.disconnect();
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

class UserInfo extends GetView<GlobalController> {
  const UserInfo({super.key});

  @override
  Widget build(BuildContext context) {
    String emailValue = controller.currentUserInfo.value?.email as String;
    final loginType = GetStorage().read(StorageKeys.loginType);
    if (loginType == LoginType.x) {
      emailValue = 'Logged in with X platform';
    }
    if (loginType == LoginType.facebook) {
      emailValue = 'Logged in with Facebook';
    }
    if (loginType == LoginType.linkedin) {
      emailValue = 'Logged in with LinkedIn';
    }
    if (loginType == LoginType.apple) {
      emailValue = 'Logged in with Apple';
    }

    return Obx(() {
      final myUser = controller.currentUserInfo.value;
      if (myUser == null) {
        return Container();
      }
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Hero(
              tag: myUser.id,
              child: Img(
                src: myUser.avatar,
                size: 100,
                alt: myUser.fullName,
              ),
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
            Text(
              emailValue,
              style: const TextStyle(
                fontSize: 18,
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
