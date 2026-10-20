import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/global/widgets/chainIcons.dart';
import 'package:podium/app/modules/myProfile/controllers/my_profile_controller.dart';
import 'package:podium/app/modules/myProfile/widgets/profile_statistics.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/ui/app_ui.dart';

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
      return const SizedBox.shrink();
    }
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          AppIconTile(
            bordered: true,
            icon: Icons.star_outline_rounded,
            color: AppColors.accent,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Default wallet', style: AppText.caption),
                const SizedBox(height: 2),
                Text(
                  defaultWallet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle,
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () {
              store.remove(StorageKeys.selectedWalletName);
              setState(() {
                visible = false;
              });
            },
            child: const Text('Forget'),
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String iconSrc;
  final String label;
  final String price;
  final bool isLoading;
  const _BalanceRow({
    required this.iconSrc,
    required this.label,
    required this.price,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Img(
          src: iconSrc,
          size: 20,
          borderRadius: BorderRadius.circular(999),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.muted,
          ),
        ),
        PriceSkeleton(
          isLoading: isLoading,
          price: price,
        ),
      ],
    );
  }
}

class EvmBalances extends GetView<MyProfileController> {
  const EvmBalances({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final balances = controller.balances.value;
      final loading = controller.isGettingBalances.value;

      return Column(
        children: [
          _BalanceRow(
            iconSrc: chainIconUrlByChainId(baseChainId),
            label: 'Base ETH',
            price: balances.Base,
            isLoading: loading,
          ),
          const SizedBox(height: 10),
          _BalanceRow(
            iconSrc: chainIconUrlByChainId(avalancheChainId),
            label: 'AVAX',
            price: balances.Avalanche,
            isLoading: loading,
          ),
        ],
      );
    });
  }
}

class InternalWallet extends GetView<GlobalController> {
  const InternalWallet({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Assets.images.logo.image(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Podium Wallet', style: AppText.cardTitle),
                    const SizedBox(height: 2),
                    Text('Your built-in wallet', style: AppText.caption),
                  ],
                ),
              ),
              AppPill(
                label: 'Linked',
                icon: Icons.link_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AptosAddressAndBalance(),
          const SizedBox(height: 10),
          const EvmAddressAndBalances(),
          const SizedBox(height: 14),
          const PrivateKeyButton(),
        ],
      ),
    );
  }
}

class AptosAddressAndBalance extends GetView<GlobalController> {
  const AptosAddressAndBalance({super.key});
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final myUser = controller.myUserInfo.value;
      if (myUser == null) {
        return const SizedBox.shrink();
      }
      final aptosWalletAddress = myUser.aptos_address!;
      return AddressAndBalanceWidget(
        address: aptosWalletAddress,
        balanceWidget: const AptosBalance(),
        label: 'Movement',
      );
    });
  }
}

class AddressAndBalanceWidget extends StatelessWidget {
  const AddressAndBalanceWidget({
    super.key,
    required this.address,
    required this.label,
    this.balanceWidget,
  });

  final String address;
  final Widget? balanceWidget;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ColorName.white.withAlpha(8),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label.toUpperCase(),
                            style: AppText.label,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            truncate(address, length: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: ColorName.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.fill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (balanceWidget != null) ...[
              Divider(height: 1, thickness: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: balanceWidget,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EvmAddressAndBalances extends GetView<GlobalController> {
  const EvmAddressAndBalances({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final myUser = controller.myUserInfo.value;
      if (myUser == null) {
        return const SizedBox.shrink();
      }
      final walletAddress = myUser.address;
      return AddressAndBalanceWidget(
        address: walletAddress,
        balanceWidget: const EvmBalances(),
        label: 'EVM',
      );
    });
  }
}

class AptosBalance extends GetView<MyProfileController> {
  const AptosBalance({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final balances = controller.balances.value;
      final loading = controller.isGettingBalances.value;

      return _BalanceRow(
        iconSrc: Assets.images.movementIcon.path,
        label: 'MOVE',
        price: balances.movementAptos,
        isLoading: loading,
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
            fontSize: 12,
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
              color: isActivated ? ColorName.success : ColorName.white,
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
            fontSize: 12,
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
              color: isActivated ? ColorName.success : ColorName.white,
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
      if (connectedWalletAddress == '') {
        return const SizedBox.shrink();
      }
      return AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppIconTile(
                  bordered: true,
                  icon: Icons.link_rounded,
                  color: AppColors.success,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('External Wallet', style: AppText.cardTitle),
                      const SizedBox(height: 2),
                      Text(
                        'Connected',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const ExternalWalletChainIcon(
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AddressAndBalanceWidget(
              address: connectedWalletAddress,
              label: 'Address',
            ),
          ],
        ),
      );
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
        return walletConnected != ''
            ? AppSecondaryButton(
                onPressed: () {
                  controller.disconnect();
                },
                color: AppColors.danger,
                icon: Icons.link_off_rounded,
                label: 'Disconnect External Wallet',
              )
            : AppPrimaryButton(
                onPressed: () {
                  controller.connectToWallet();
                },
                icon: Icons.add_link_rounded,
                label: 'Connect External Wallet',
              );
      },
    );
  }
}

class PrivateKeyButton extends GetView<MyProfileController> {
  const PrivateKeyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSecondaryButton(
      onPressed: () => controller.showPrivateKeyWarning(),
      color: AppColors.danger,
      icon: Icons.key_rounded,
      label: 'Copy Private Key',
    );
  }
}
