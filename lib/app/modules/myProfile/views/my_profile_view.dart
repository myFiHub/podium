import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/referral_controller.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/global/widgets/chainIcons.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/modules/myProfile/controllers/my_profile_controller.dart';
import 'package:podium/app/modules/myProfile/widgets/color_theme_sheet.dart';
import 'package:podium/app/modules/records/controllers/records_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/root.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/loginType.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:shimmer/shimmer.dart';

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
        body: PageWrapper(
          child: SingleChildScrollView(
            controller: controller.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const ContextSaver(),
                const NonPrimaryAccountWarning(),
                const UserInfo(),
                const _SectionLabel('Account'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      const ConnectedAccountsButton(),
                      const _RowDivider(),
                      ReferalSystem(
                        key: controller.referalSystemKey,
                      ),
                    ],
                  ),
                ),
                const _SectionLabel('Wallets'),
                const DefaultWallet(),
                InternalWallet(
                  key: controller.internalWalletKey,
                ),
                const ExternalWallet(),
                WalletConnect(
                  key: controller.walletConnectKey,
                ),
                const _SectionLabel('Activity'),
                _Statistics(
                  key: controller.statisticsKey,
                ),
                const _SectionLabel('Preferences'),
                const AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ColorThemeSetting(),
                      _RowDivider(),
                      ToggleShowArchivedGroups(),
                      _RowDivider(),
                      BugsAndFeedbacks(),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const LogoutButton(),
                const SizedBox(height: 10),
                const DeleteAccountButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(
      title: title,
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 68,
      color: AppColors.border,
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color? color;
  Color get _color => color ?? AppColors.primary;

  final double size;
  const _IconTile({
    required this.icon,
    this.color,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color.withAlpha(30),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: _color.withAlpha(50)),
      ),
      child: Icon(icon, size: size * 0.5, color: _color),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  Color get _iconColor => iconColor ?? AppColors.primary;

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dimmed;
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.iconColor,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconTile(
              icon: icon,
              color: dimmed ? AppColors.textMuted : _iconColor,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: dimmed ? AppColors.textMuted : ColorName.white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                (onTap != null
                    ? Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      )
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final bool subtle;
  final VoidCallback onPressed;
  const _DangerButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        subtle ? Colors.transparent : AppColors.danger.withAlpha(30);
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: background,
        foregroundColor: AppColors.danger,
        disabledBackgroundColor: background,
        disabledForegroundColor: AppColors.danger,
        side: BorderSide(color: AppColors.danger.withAlpha(subtle ? 60 : 90)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      child: loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.danger,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );
  }
}

class DeleteAccountButton extends GetView<MyProfileController> {
  const DeleteAccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDeactivatingAccount = controller.isDeactivatingAccount.value;
      return _DangerButton(
        loading: isDeactivatingAccount,
        subtle: true,
        icon: Icons.delete_outline_rounded,
        onPressed: () {
          controller.showDeactivationDialog();
        },
        label: 'Delete Account',
      );
    });
  }
}

class ContextSaver extends GetView<MyProfileController> {
  const ContextSaver({super.key});

  @override
  Widget build(BuildContext context) {
    controller.contextForIntro = context;

    return emptySpace;
  }
}

class ReferalSystem extends GetView<ReferalController> {
  const ReferalSystem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final myProfileData = controller.myProfile.value;
      final remainingReferrals = myProfileData?.remaining_referrals_count ?? 0;
      final totalReferrals =
          (myProfileData?.referrals_count ?? 0) + remainingReferrals;
      final hasRemaining = remainingReferrals > 0;
      return _SettingsRow(
        icon: Icons.person_add_alt_1_rounded,
        iconColor: AppColors.success,
        title: hasRemaining ? 'Refer a friend' : 'All referrals used',
        subtitle: hasRemaining
            ? '$remainingReferrals/$totalReferrals remaining'
            : 'No invites left',
        dimmed: !hasRemaining,
        onTap: hasRemaining
            ? () {
                controller.referButtonClicked();
              }
            : null,
      );
    });
  }
}

class BugsAndFeedbacks extends GetView<MyProfileController> {
  const BugsAndFeedbacks({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      icon: Icons.bug_report_outlined,
      iconColor: AppColors.accent,
      title: 'Report a bug or give feedback',
      subtitle: 'Help us make Podium better',
      onTap: () {
        controller.openFeedbackPage();
      },
    );
  }
}

class ColorThemeSetting extends StatelessWidget {
  const ColorThemeSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      icon: Icons.palette_outlined,
      title: 'Color theme',
      subtitle: AppPalette.current.name,
      onTap: () {
        showAppSheet(const ColorThemeSheet());
      },
    );
  }
}

class ToggleShowArchivedGroups extends GetView<GlobalController> {
  const ToggleShowArchivedGroups({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      icon: Icons.archive_outlined,
      title: 'Show My Archived Outposts',
      subtitle: 'Include archived outposts in your lists',
      onTap: () {
        controller.toggleShowArchivedOutposts();
      },
      trailing: Obx(() {
        final value = controller.showArchivedOutposts.value;
        return Switch(
          value: value,
          onChanged: (v) {
            controller.toggleShowArchivedOutposts();
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
      return const SizedBox.shrink();
    }
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          _IconTile(
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
        _PriceSkeleton(
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
        iconSrc: chainIconUrlByChainId(movementEVMChain.chainId),
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
                _IconTile(
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

class LogoutButton extends GetView<GlobalController> {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoggingOut = controller.isLoggingOut.value;
      return _DangerButton(
        loading: isLoggingOut,
        icon: Icons.logout_rounded,
        onPressed: () {
          final globalController = Get.find<GlobalController>();
          globalController.setLoggedIn(false);
        },
        label: 'Logout',
      );
    });
  }
}

class _AvatarRing extends StatelessWidget {
  final Widget child;
  const _AvatarRing({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withAlpha(60)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 28,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ColorName.cardBackground,
        ),
        child: child,
      ),
    );
  }
}

class UserInfo extends GetView<GlobalController> {
  const UserInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final myUser = controller.myUserInfo.value;
      if (myUser == null) {
        return const SizedBox.shrink();
      }
      String identifier = myUser.login_type_identifier ?? '';
      final loginType = GetStorage().read(StorageKeys.loginType);

      final loginTypes = {
        LoginType.x: 'Logged in with X platform',
        LoginType.facebook: 'Logged in with Facebook',
        LoginType.linkedin: 'Logged in with LinkedIn',
        LoginType.apple: 'Logged in with Apple',
        LoginType.github: 'Logged in with Github'
      };

      if (loginTypes.containsKey(loginType)) {
        identifier = loginTypes[loginType]!;
      }

      String avatar = myUser.image ?? '';
      if (avatar == defaultAvatar) {
        avatar = avatarPlaceHolder(myUser.name);
      }

      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            _AvatarRing(
              child: Hero(
                tag: 'profile_avatar_${myUser.uuid}',
                child: Img(
                  src: avatar,
                  size: 96,
                  alt: myUser.name,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              myUser.name ?? '',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.pageTitle.copyWith(fontSize: 24),
            ),
            if (identifier.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                identifier,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.muted,
              ),
            ],
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Material(
                color: AppColors.fill,
                shape: StadiumBorder(
                  side: BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: myUser.uuid));
                    Toast.neutral(
                      title: 'Copied',
                      message: 'ID copied to clipboard',
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('ID', style: AppText.label),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            myUser.uuid,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
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

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int value;
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorName.white.withAlpha(8),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: ColorName.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
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
        return const AppCard(
          child: SizedBox(
            height: 120,
            child: Center(child: LoadingWidget()),
          ),
        );
      }
      final incomeEntries = payments.income.entries.toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.celebration_rounded,
                        color: AppColors.accent,
                        label: 'Cheers received',
                        value: payments.numberOfCheersReceived,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.thumb_down_alt_rounded,
                        color: AppColors.danger,
                        label: 'Boos received',
                        value: payments.numberOfBoosReceived,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.celebration_outlined,
                        color: AppColors.accent,
                        label: 'Cheers sent',
                        value: payments.numberOfCheersSent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.thumb_down_alt_outlined,
                        color: AppColors.danger,
                        label: 'Boos sent',
                        value: payments.numberOfBoosSent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: _SettingsRow(
              icon: Icons.graphic_eq_rounded,
              iconColor: AppColors.accent,
              title: 'Recorded Audios',
              subtitle: 'Listen back to your outpost recordings',
              onTap: () {
                final isRegistered = Get.isRegistered<RecordsController>();
                if (isRegistered) {
                  final recordsController = Get.find<RecordsController>();
                  recordsController.loadRecordings();
                }
                Navigate.to(
                  type: NavigationTypes.toNamed,
                  route: Routes.RECORDS,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _IconTile(
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 14),
                    Text('Earned', style: AppText.cardTitle),
                  ],
                ),
                const SizedBox(height: 12),
                if (incomeEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('Nothing yet', style: AppText.muted),
                  ),
                for (final e in incomeEntries) ...[
                  _IncomeRow(chainId: e.key, amount: e.value.toString()),
                  if (e.key != incomeEntries.last.key)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                    ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _IncomeRow extends StatelessWidget {
  final String chainId;
  final String amount;
  const _IncomeRow({required this.chainId, required this.amount});

  @override
  Widget build(BuildContext context) {
    final chainInfo = chainInfoByChainId(chainId);
    final currency = chainInfo.currency;
    final chainName = chainInfo.name;
    final chainIcon = chainInfo.chainIcon!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Img(
            src: chainIcon,
            size: 22,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              chainName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$amount $currency',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceSkeleton extends StatelessWidget {
  const _PriceSkeleton({
    required this.price,
    required this.isLoading,
  });

  final String price;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return Text(
        price,
        textAlign: TextAlign.end,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: ColorName.white,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: ColorName.white.withAlpha(20),
      highlightColor: ColorName.white.withAlpha(50),
      period: const Duration(milliseconds: 900),
      child: Container(
        width: 56,
        height: 14,
        decoration: BoxDecoration(
          color: ColorName.white.withAlpha(20),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

class ConnectedAccountsButton extends GetView<GlobalController> {
  const ConnectedAccountsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final myUser = controller.myUserInfo.value;
      if (myUser == null) {
        return const SizedBox.shrink();
      }
      final myAccounts = myUser.accounts;
      final accountCount = myAccounts.length;
      final buttonText = accountCount <= 1
          ? 'Connect Accounts'
          : 'Connected Accounts ($accountCount)';
      return _SettingsRow(
        icon: Icons.manage_accounts_rounded,
        title: buttonText,
        subtitle: 'Manage your sign-in methods',
        onTap: () {
          Navigate.to(
            type: NavigationTypes.toNamed,
            route: Routes.CONNECTED_ACCOUNTS,
          );
        },
      );
    });
  }
}

class NonPrimaryAccountWarning extends GetView<GlobalController> {
  const NonPrimaryAccountWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final myUser = controller.myUserInfo.value;
        if (myUser == null) {
          return const SizedBox.shrink();
        }
        final accounts = myUser.accounts;
        final primaryAccount = accounts.firstWhere(
          (account) => account.is_primary,
          orElse: () => ConnectedAccount(
              address: myUser.address,
              aptos_address: myUser.aptos_address!,
              image: myUser.image,
              is_primary: true,
              login_type: myUser.login_type,
              login_type_identifier: myUser.login_type_identifier ?? '',
              uuid: myUser.uuid),
        );
        final isThisAccountPrimary = primaryAccount.address == myUser.address;
        if (isThisAccountPrimary) {
          return const SizedBox.shrink();
        }
        return AppCard(
          margin: const EdgeInsets.only(top: 4, bottom: 8),
          color: AppColors.danger.withAlpha(22),
          borderColor: AppColors.danger.withAlpha(80),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(
                icon: Icons.warning_amber_rounded,
                color: AppColors.danger,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secondary Account',
                      style: AppText.cardTitle.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This is not your primary account. Only the primary account can perform certain actions.',
                      style: AppText.caption.copyWith(
                        color: ColorName.white.withAlpha(200),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
