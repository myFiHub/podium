import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/referral_controller.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/global/widgets/chainIcons.dart';
import 'package:podium/app/modules/myProfile/controllers/my_profile_controller.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/loginType.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';

class MyProfileView extends GetView<MyProfileController> {
  const MyProfileView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (res, r) {
        controller.introFinished(false);
      },
      child: Scaffold(
        body: SingleChildScrollView(
          controller: controller.scrollController,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const ContextSaver(),
              const UserInfo(),
              ReferalSystem(
                key: controller.referalSystemKey,
              ),
              const DefaultWallet(),
              space10,
              InternalWallet(
                key: controller.internalWalletKey,
              ),
              const ExternalWallet(),
              WalletConnect(
                key: controller.walletConnectKey,
              ),
              space10,
              _Statistics(
                key: controller.statisticsKey,
              ),
              space10,
              const ToggleShowArchivedGroups(),
              space10,
              const BugsAndFeedbacks(),
              space10,
              const LogoutButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class ContextSaver extends GetView<MyProfileController> {
  const ContextSaver({super.key});

  @override
  Widget build(BuildContext context) {
    controller.contextForIntro = context;

    return const SizedBox.shrink();
  }
}

class ReferalSystem extends GetView<ReferalController> {
  const ReferalSystem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        space10,
        Obx(() {
          final allReferrals = controller.myReferals.value.values.toList();
          final count = allReferrals.length;
          final remaining =
              allReferrals.where((element) => element.usedBy == '').length;
          final numberOfAllReferals = allReferrals.length;
          if (numberOfAllReferals == 0) {
            return const SizedBox();
          }
          return Button(
            onPressed: remaining == 0
                ? null
                : () {
                    controller.referButtonClicked();
                  },
            blockButton: true,
            type: ButtonType.outline,
            child: RichText(
                text: TextSpan(
              children: [
                TextSpan(
                  text: remaining > 0 ? 'Refer a friend' : 'All referrals used',
                  style: TextStyle(
                    fontSize: 18,
                    color: remaining == 0 ? Colors.grey : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (remaining > 0)
                  const WidgetSpan(
                    child: Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Icon(
                        Icons.person_add,
                        size: 20,
                        color: Colors.green,
                      ),
                    ),
                  ),
                if (remaining > 0)
                  WidgetSpan(
                      child: Text(
                    ' $remaining/$count remaining',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ))
              ],
            )),
          );
        }),
      ],
    );
  }
}

class BugsAndFeedbacks extends GetView<MyProfileController> {
  const BugsAndFeedbacks({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        space10,
        Button(
          onPressed: () {
            controller.openFeedbackPage();
          },
          blockButton: true,
          type: ButtonType.outline,
          child: RichText(
              text: const TextSpan(
            children: [
              TextSpan(
                text: 'Report a bug or give feedback',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const WidgetSpan(
                child: const Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: const Icon(
                    Icons.bug_report,
                    size: 20,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          )),
        ),
      ],
    );
  }
}

class ToggleShowArchivedGroups extends GetView<GlobalController> {
  const ToggleShowArchivedGroups({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text(
        'Show My Archived Rooms',
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Obx(() {
        final value = controller.showArchivedGroups.value;
        return Switch(
          value: value,
          onChanged: (v) {
            controller.toggleShowArchivedGroups();
          },
        );
      }),
    );
  }
}

class DefaultWallet extends StatefulWidget {
  const DefaultWallet({super.key});

  @override
  State<DefaultWallet> createState() => _DefaultWalletState();
}

class _DefaultWalletState extends State<DefaultWallet> {
  bool visible = false;
  @override
  Widget build(BuildContext context) {
    final store = GetStorage();
    final String defaultWallet =
        store.read(StorageKeys.selectedWalletName) ?? '';
    if (defaultWallet.isNotEmpty) {
      visible = true;
    }
    if (visible == false) {
      return Container();
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Text(
                'Default Wallet:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              space10,
              Text(
                defaultWallet,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.purple[200],
                ),
              ),
            ],
          ),
          space10,
          Button(
            size: ButtonSize.SMALL,
            borderSide: const BorderSide(color: Colors.red),
            onPressed: () {
              store.remove(StorageKeys.selectedWalletName);
              setState(() {
                visible = false;
              });
            },
            type: ButtonType.outline,
            text: 'Forget',
          ),
        ],
      );
    }
  }
}

class EvmBalances extends GetView<MyProfileController> {
  const EvmBalances({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final balances = controller.balances.value;
      final loading = controller.isGettingBalances.value;
      if (loading) {
        return Container(
          width: Get.width - 16,
          height: 48,
          child: Center(
            child: Container(
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(),
            ),
          ),
        );
      }
      return Container(
        // add a top border
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: ColorName.greyText,
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.only(top: 12),
        width: Get.width - 24,
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Base ETH',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    space5,
                    Img(
                      src: chainIconUrlByChainId(baseChainId),
                      size: 16,
                    ),
                  ],
                ),
                Text(
                  balances.Base,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'AVAX',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    space5,
                    Img(
                      src: chainIconUrlByChainId(avalancheChainId),
                      size: 16,
                    ),
                  ],
                ),
                Text(
                  balances.Avalanche,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'MOVE',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    space5,
                    Img(
                      src: chainIconUrlByChainId(movementChain.chainId),
                      size: 16,
                    ),
                  ],
                ),
                Text(
                  balances.Movement,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class InternalWallet extends GetView<GlobalController> {
  const InternalWallet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorName.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Assets.images.logo.image(
                    width: 30,
                    height: 30,
                  ),
                  space10,
                  Text(
                    'Podium Wallet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue[100],
                    ),
                  ),
                  space5,
                  Icon(Icons.link, color: Colors.blue[100]),
                  space5,
                ],
              ),
              space10,
              const EvmAddressAndBalances(),
              space10,
              const AptosAddressAndBalance(),
            ],
          ),
          // FriendTeckActivationButton()
        ],
      ),
    );
  }
}

class AptosAddressAndBalance extends StatelessWidget {
  const AptosAddressAndBalance({super.key});
  @override
  Widget build(BuildContext context) {
    final aptosWalletAddress = myUser.aptosInternalWalletAddress;
    return AddressAndBalanceWidget(
      address: aptosWalletAddress,
      balanceWidget: const AptosBalance(),
      addressPrefix: 'Aptos:',
    );
  }
}

class AddressAndBalanceWidget extends StatelessWidget {
  const AddressAndBalanceWidget({
    super.key,
    required String this.address,
    required Widget this.balanceWidget,
    required String this.addressPrefix,
  });

  final String address;
  final Widget balanceWidget;
  final String addressPrefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width - 16,
      decoration: const BoxDecoration(
        color: ColorName.cardBorder,
        borderRadius: const BorderRadius.all(
          const Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          space10,
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(
                ClipboardData(
                  text: address,
                ),
              );
              Toast.neutral(
                title: 'Copied',
                message: 'Wallet address copied to clipboard',
              );
            },
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: ColorName.greyText,
                ),
                space10,
                Text(
                  '${addressPrefix}${truncate(
                    address,
                    length: 9,
                  )}',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: ColorName.greyText,
                  ),
                ),
                space10,
                const Icon(
                  Icons.copy,
                  color: Colors.grey,
                )
              ],
            ),
          ),
          space10,
          balanceWidget,
          space10,
        ],
      ),
    );
  }
}

class EvmAddressAndBalances extends StatelessWidget {
  const EvmAddressAndBalances({super.key});

  @override
  Widget build(BuildContext context) {
    final walletAddress = myUser.evmInternalWalletAddress;
    return AddressAndBalanceWidget(
      address: walletAddress,
      balanceWidget: const EvmBalances(),
      addressPrefix: 'EVM:',
    );
  }
}

class AptosBalance extends GetView<MyProfileController> {
  const AptosBalance({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final balances = controller.balances.value;
      final loading = controller.isGettingBalances.value;
      if (loading) {
        return Container(
          width: Get.width - 16,
          height: 48,
          child: Center(
            child: Container(
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(),
            ),
          ),
        );
      }
      return Container(
        // add a top border
        height: 48,
        width: Get.width - 16,
        decoration: const BoxDecoration(
          border: const Border(
            top: const BorderSide(
              color: ColorName.greyText,
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Aptos MOVE',
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    space5,
                    Img(
                      src: chainIconUrlByChainId(movementChain.chainId),
                      size: 16,
                    ),
                  ],
                ),
                Text(
                  balances.movementAptos,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class FriendTechExternalWalletActivationButton
    extends GetWidget<MyProfileController> {
  const FriendTechExternalWalletActivationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'FriendTech',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        Obx(() {
          final isLoading = controller.loadingExternalWalletActivation.value;
          final isActivated =
              controller.isExternalWalletActivatedOnFriendTech.value;
          return Button(
            loading: isLoading,
            size: ButtonSize.SMALL,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActivated ? Colors.green[400] : Colors.red[100],
            ),
            onPressed: (isActivated || isLoading)
                ? null
                : () async {
                    await controller.activateExternalWallet();
                  },
            type: ButtonType.gradient,
            text: isActivated ? 'Activated' : 'Activate',
          );
        }),
      ],
    );
  }
}

class FriendTeckActivationButton extends GetWidget<MyProfileController> {
  const FriendTeckActivationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'FriendTech',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        Obx(() {
          final isLoading = controller.loadingInternalWalletActivation.value;
          final isActivated =
              controller.isInternalWalletActivatedOnFriendTech.value;
          return Button(
            loading: isLoading,
            size: ButtonSize.SMALL,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActivated ? Colors.green[400] : Colors.red[100],
            ),
            onPressed: (isActivated || isLoading)
                ? null
                : () async {
                    await controller.activateInternalWallet();
                  },
            type: ButtonType.gradient,
            text: isActivated ? 'Activated' : 'Activate',
          );
        }),
      ],
    );
  }
}

class ExternalWallet extends GetView<GlobalController> {
  const ExternalWallet({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final connectedWalletAddress = controller.connectedWalletAddress.value;
      return connectedWalletAddress == ''
          ? Container()
          : Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: ColorName.greyText,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'External Wallet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.green[100],
                            ),
                          ),
                          space5,
                          Icon(Icons.link, color: Colors.green[100]),
                          space5,
                          const ExternalWalletChainIcon(
                            size: 20,
                          ),
                        ],
                      ),
                      space10,
                      GestureDetector(
                          onTap: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: connectedWalletAddress,
                              ),
                            );
                            Toast.neutral(
                              title: 'Copied',
                              message: 'Wallet address copied to clipboard',
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                color: ColorName.greyText,
                              ),
                              space10,
                              Text(
                                truncate(
                                  connectedWalletAddress,
                                  length: 12,
                                ),
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                  color: ColorName.greyText,
                                ),
                              ),
                              space10,
                              const Icon(
                                Icons.copy,
                                color: Colors.grey,
                              )
                            ],
                          )),
                    ],
                  ),
                  // FriendTechExternalWalletActivationButton()
                ],
              ));
    });
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
                    text: 'Disconnect External Wallet',
                  )
                : Button(
                    onPressed: () {
                      controller.connectToWallet();
                    },
                    type: ButtonType.gradient,
                    blockButton: true,
                    text: 'Connect External Wallet',
                  ),
            space10,
          ],
        );
      },
    );
  }
}

class LogoutButton extends GetView<GlobalController> {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
    });
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
    if (loginType == LoginType.github) {
      emailValue = 'Logged in with Github';
    }

    return Obx(() {
      final myUser = controller.currentUserInfo.value;
      if (myUser == null) {
        return Container();
      }
      String avatar = myUser.avatar;
      if (avatar == defaultAvatar) {
        avatar = avatarPlaceHolder(myUser.fullName);
      }
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Img(
              src: avatar,
              size: 100,
              alt: myUser.fullName,
            ),
            space10,
            space10,
            Text(
              myUser.fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: Get.width - 120,
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ColorName.greyText,
                      ),
                      children: [
                        const TextSpan(
                          text: 'ID: ',
                        ),
                        TextSpan(
                          text: myUser.id,
                        ),
                      ],
                    ),
                  ),
                ),
                space5,
                IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: myUser.id));
                      Toast.neutral(
                        title: 'Copied',
                        message: 'User ID copied to clipboard',
                      );
                    },
                    icon: const Icon(
                      Icons.copy,
                      color: Colors.grey,
                    ))
              ],
            )
          ],
        ),
      );
    });
  }
}

class _Statistics extends GetWidget<MyProfileController> {
  const _Statistics({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final payments = controller.payments.value;
      final loading = controller.isGettingPayments.value;
      if (loading) {
        return const CircularProgressIndicator();
      }
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: ColorName.greyText,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Cheers received',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          payments.numberOfCheersReceived.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'Boos received',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          payments.numberOfBoosReceived.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                space10,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Cheers sent',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          payments.numberOfCheersSent.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'Boos sent',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          payments.numberOfBoosSent.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          space10,
          Container(
            width: Get.width - 2,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: ColorName.greyText,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(children: [
              Text(
                'Earned',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[200],
                ),
              ),
              if (payments.income.entries.isEmpty)
                const Text(
                  'Nothing yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ColorName.greyText,
                  ),
                ),
              ...payments.income.entries.map(
                (e) {
                  final chainInfo = chainInfoByChainId(e.key);
                  final currency = chainInfo.currency;
                  final chainName = chainInfo.name;
                  final chainIcon = chainInfo.chainIcon!;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  chainName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                space5,
                                Img(src: chainIcon, size: 20),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  e.value.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                space5,
                                Text(
                                  currency,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      space5,
                      // separetor
                      if (e.key != payments.income.entries.last.key)
                        Container(
                          height: 1,
                          color: ColorName.greyText,
                        ),
                    ],
                  );
                },
              ).toList(),
            ]),
          ),
        ],
      );
    });
  }
}
