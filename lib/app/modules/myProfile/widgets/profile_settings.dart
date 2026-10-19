import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/referral_controller.dart';
import 'package:podium/app/modules/myProfile/controllers/my_profile_controller.dart';
import 'package:podium/app/modules/myProfile/widgets/color_theme_sheet.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

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

class ReferalSystem extends GetView<ReferalController> {
  const ReferalSystem({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final myProfileData = controller.myProfile.value;
      final remainingReferrals = myProfileData?.remaining_referrals_count ?? 0;
      final totalReferrals =
          (myProfileData?.referrals_count ?? 0) + remainingReferrals;
      final hasRemaining = remainingReferrals > 0;
      return AppSettingsRow(
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
  const BugsAndFeedbacks({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSettingsRow(
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
    return AppSettingsRow(
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
    return AppSettingsRow(
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
      return AppSettingsRow(
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
              AppIconTile(
                bordered: true,
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
