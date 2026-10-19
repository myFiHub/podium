import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/web3AuthProviderToLoginTypeString.dart';
import 'package:podium/app/modules/myProfile/constants/connected_accounts_constants.dart';
import 'package:podium/app/modules/myProfile/controllers/my_profile_controller.dart';
import 'package:podium/app/modules/myProfile/widgets/header_widget.dart';
import 'package:podium/app/modules/myProfile/widgets/identifier_text.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/loginType.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:web3auth_flutter/enums.dart';

class ConnectedAccountsView extends GetView<MyProfileController> {
  const ConnectedAccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return PageWrapper(
      child: Scaffold(
        body: Obx(() {
          final currentLoginType =
              controller.globalController.myUserInfo.value?.login_type;

          if (currentLoginType == null) {
            return const Center(
              child: AppEmptyState(
                icon: Icons.link_off_rounded,
                title: 'No account connected',
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              AppPageHeader(
                title: 'Connected Accounts',
                subtitle: 'Sign in to Podium with any linked method',
                showBack: canPop,
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
              ),
              HeaderWidget(loginType: currentLoginType),
              const AppSectionHeader(
                title: 'Sign-in methods',
                padding: EdgeInsets.fromLTRB(4, 24, 4, 10),
              ),
              LoginOption(
                provider: Provider.twitter,
                icon: Assets.images.xPlatform,
                title: LoginTypeDisplayName.x,
                isConnected: currentLoginType == LoginType.x,
              ),
              const SizedBox(height: 10),
              LoginOption(
                provider: Provider.apple,
                icon: Assets.images.apple,
                title: LoginTypeDisplayName.apple,
                isConnected: currentLoginType == LoginType.apple,
              ),
              const SizedBox(height: 10),
              LoginOption(
                provider: Provider.google,
                icon: Assets.images.gIcon,
                title: LoginTypeDisplayName.google,
                isConnected: currentLoginType == LoginType.google,
              ),
              const SizedBox(height: 10),
              LoginOption(
                provider: Provider.email_passwordless,
                icon: null,
                title: LoginTypeDisplayName.email,
                isConnected: currentLoginType == LoginType.email,
              ),
              const SizedBox(height: 10),
              LoginOption(
                provider: Provider.facebook,
                icon: Assets.images.facebook,
                title: LoginTypeDisplayName.facebook,
                isConnected: currentLoginType == LoginType.facebook,
              ),
              const SizedBox(height: 10),
              LoginOption(
                provider: Provider.linkedin,
                icon: Assets.images.linkedin,
                title: LoginTypeDisplayName.linkedin,
                isConnected: currentLoginType == LoginType.linkedin,
              ),
              const SizedBox(height: 10),
              LoginOption(
                provider: Provider.github,
                icon: Assets.images.github,
                title: LoginTypeDisplayName.github,
                isConnected: currentLoginType == LoginType.github,
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.filled = true,
    this.color = AppColors.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : color;
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        backgroundColor: filled ? color : color.withAlpha(20),
        foregroundColor: foreground,
        disabledBackgroundColor:
            filled ? color.withAlpha(150) : color.withAlpha(20),
        disabledForegroundColor: foreground,
        side: filled ? null : BorderSide(color: color.withAlpha(110)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: loading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
              ),
            )
          : Text(label),
    );
  }
}

class _PrimaryBadge extends StatelessWidget {
  const _PrimaryBadge();

  @override
  Widget build(BuildContext context) {
    return const AppPill(
      label: 'Primary',
      icon: Icons.check_rounded,
      color: ConnectedAccountsConstants.successColor,
    );
  }
}

class LoginOption extends GetView<GlobalController> {
  const LoginOption({
    super.key,
    required this.provider,
    required this.icon,
    required this.title,
    required this.isConnected,
  });

  final Provider provider;
  final AssetGenImage? icon;
  final String title;
  final bool isConnected;

  String get _loginType => web3AuthProviderToLoginTypeString(provider);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final myUser = controller.myUserInfo.value;
      final isAddingAccount_provider =
          controller.addingOrSwitchingAccount_provider.value;
      final accounts = myUser?.accounts;

      Widget subtitle = Text(
        isConnected ? 'Active now' : 'Not connected',
        style: AppText.caption,
      );
      Widget trailing = const SizedBox.shrink();

      if (accounts != null) {
        if (isConnected) {
          final isPrimary = accounts.any(
            (account) => account.address == myUser?.address && account.is_primary,
          );
          subtitle = IdentifierText(identifier: myUser?.login_type_identifier);
          trailing = !isPrimary
              ? MakePrimaryButton(address: myUser?.address ?? '')
              : const _PrimaryBadge();
        } else {
          final isLoading = isAddingAccount_provider == provider;
          final thisAccount = accounts.firstWhereOrNull((account) {
            return (account.login_type == _loginType) ||
                (account.login_type == 'email' &&
                    provider == Provider.email_passwordless);
          });
          final isPrimary = thisAccount?.is_primary ?? false;
          final thisTypeExistOnAccounts =
              accounts.any((account) => account.login_type == _loginType);

          if (thisTypeExistOnAccounts) {
            final existingAccount = accounts
                .firstWhere((account) => account.login_type == _loginType);
            subtitle = IdentifierText(
              identifier: existingAccount.login_type_identifier,
            );
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isPrimary)
                  MakePrimaryButton(address: existingAccount.address)
                else
                  const _PrimaryBadge(),
                const SizedBox(width: 6),
                _SmallActionButton(
                  loading: isLoading,
                  label: 'Switch',
                  onPressed: () => _showConnectConfirmationDialog(
                    provider,
                    title,
                    email: thisAccount?.login_type_identifier,
                  ),
                ),
              ],
            );
          } else {
            trailing = _SmallActionButton(
              loading: isLoading,
              label: 'Connect',
              onPressed: () => _showConnectConfirmationDialog(
                provider,
                title,
                email: thisAccount?.login_type_identifier,
              ),
            );
          }
        }
      }

      return AppCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        color: isConnected
            ? ConnectedAccountsConstants.successColor.withAlpha(14)
            : null,
        borderColor: isConnected
            ? ConnectedAccountsConstants.successColor.withAlpha(110)
            : null,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.fill,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: icon != null
                  ? icon!.image(
                      width: ConnectedAccountsConstants.iconSize,
                      height: ConnectedAccountsConstants.iconSize,
                    )
                  : const Icon(
                      Icons.email_outlined,
                      size: ConnectedAccountsConstants.iconSize,
                      color: Colors.white,
                    ),
            ),
            const SizedBox(width: 12),
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
                    ),
                  ),
                  const SizedBox(height: 2),
                  subtitle,
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      );
    });
  }

  void _showConnectConfirmationDialog(
    Provider provider,
    String title, {
    String? email,
  }) {
    Get.dialog(
      ConnectConfirmationDialog(provider: provider, title: title, email: email),
    );
  }
}

class MakePrimaryButton extends GetView<MyProfileController> {
  const MakePrimaryButton({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading =
          controller.addressThatIsBeningMadePrimary.value == address;
      return _SmallActionButton(
        loading: isLoading,
        label: 'Make primary',
        filled: false,
        color: AppColors.accent,
        onPressed: () {
          controller.setAccountAsPrimary(address);
        },
      );
    });
  }
}

class ConnectConfirmationDialog extends GetView<MyProfileController> {
  const ConnectConfirmationDialog({
    super.key,
    required this.provider,
    required this.title,
    this.email,
  });

  final Provider provider;
  final String title;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(30),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withAlpha(70)),
        ),
        child: const Icon(
          Icons.swap_horiz_rounded,
          color: AppColors.primary,
        ),
      ),
      title: const Text('Account Connection'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'In process of merging accounts:',
            style: AppText.muted,
          ),
          const SizedBox(height: 14),
          _buildInfoText(
            icon: Icons.logout_rounded,
            prefix: 'You will be ',
            highlighted: 'logged out',
            suffix: ' from your currently connected account',
            highlightColor: AppColors.danger,
          ),
          const SizedBox(height: 10),
          _buildInfoText(
            icon: Icons.login_rounded,
            prefix: 'You will be ',
            highlighted: 'logged in',
            suffix: ' with the new account',
            highlightColor: ConnectedAccountsConstants.successColor,
          ),
          const SizedBox(height: 10),
          _buildInfoText(
            icon: Icons.info_outline_rounded,
            prefix: 'Later, you can ',
            highlighted: 'log in',
            suffix: ' with your main account',
            highlightColor: ConnectedAccountsConstants.primaryBlue,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.closeOverlay(),
          style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
          ),
          onPressed: () {
            Get.closeOverlay();
            if (provider == Provider.email_passwordless) {
              controller.addOrSwitchAccount(provider, email: email);
            } else {
              controller.addOrSwitchAccount(provider);
            }
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildInfoText({
    required IconData icon,
    required String prefix,
    required String highlighted,
    required String suffix,
    required Color highlightColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: highlightColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: prefix),
                  TextSpan(
                    text: highlighted,
                    style: TextStyle(
                      color: highlightColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: suffix),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
