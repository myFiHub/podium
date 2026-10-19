import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/myProfile/controllers/my_profile_controller.dart';
import 'package:podium/app/modules/myProfile/widgets/profile_settings.dart';
import 'package:podium/app/modules/myProfile/widgets/profile_statistics.dart';
import 'package:podium/app/modules/myProfile/widgets/profile_user_info.dart';
import 'package:podium/app/modules/myProfile/widgets/profile_wallets.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class MyProfileView extends GetView<MyProfileController> {
  const MyProfileView({super.key});
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
                const AppSectionLabel('Account'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      const ConnectedAccountsButton(),
                      const AppRowDivider(indent: 68, endIndent: 0),
                      ReferalSystem(
                        key: controller.referalSystemKey,
                      ),
                    ],
                  ),
                ),
                const AppSectionLabel('Wallets'),
                const DefaultWallet(),
                InternalWallet(
                  key: controller.internalWalletKey,
                ),
                const ExternalWallet(),
                WalletConnect(
                  key: controller.walletConnectKey,
                ),
                const AppSectionLabel('Activity'),
                const HostDashboardButton(),
                MyProfileStatistics(
                  key: controller.statisticsKey,
                ),
                const AppSectionLabel('Preferences'),
                const AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ColorThemeSetting(),
                      AppRowDivider(indent: 68, endIndent: 0),
                      ToggleShowArchivedGroups(),
                      AppRowDivider(indent: 68, endIndent: 0),
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

class ContextSaver extends GetView<MyProfileController> {
  const ContextSaver({super.key});

  @override
  Widget build(BuildContext context) {
    controller.contextForIntro = context;

    return emptySpace;
  }
}
