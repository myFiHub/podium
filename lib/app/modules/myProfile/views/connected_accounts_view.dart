import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/web3AuthProviderToLoginTypeString.dart';
import 'package:podium/app/modules/myProfile/controllers/my_profile_controller.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/loginType.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:web3auth_flutter/enums.dart';

class ConnectedAccountsView extends GetView<MyProfileController> {
  const ConnectedAccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: Scaffold(
        body: Obx(() {
          final currentLoginType =
              controller.globalController.myUserInfo.value?.login_type;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (currentLoginType != null) ...[
                HeaderWidget(loginType: currentLoginType),
                space24,
              ],
              LoginOption(
                provider: Provider.twitter,
                icon: Assets.images.xPlatform,
                title: LoginTypeDisplayName.x,
                isConnected: currentLoginType == LoginType.x,
              ),
              space10,
              LoginOption(
                provider: Provider.apple,
                icon: Assets.images.apple,
                title: LoginTypeDisplayName.apple,
                isConnected: currentLoginType == LoginType.apple,
              ),
              space10,
              LoginOption(
                provider: Provider.google,
                icon: Assets.images.gIcon,
                title: LoginTypeDisplayName.google,
                isConnected: currentLoginType == LoginType.google,
              ),
              space10,
              LoginOption(
                provider: Provider.email_passwordless,
                icon: null,
                title: LoginTypeDisplayName.email,
                isConnected: currentLoginType == LoginType.email,
              ),
              space10,
              LoginOption(
                provider: Provider.facebook,
                icon: Assets.images.facebook,
                title: LoginTypeDisplayName.facebook,
                isConnected: currentLoginType == LoginType.facebook,
              ),
              space10,
              LoginOption(
                provider: Provider.linkedin,
                icon: Assets.images.linkedin,
                title: LoginTypeDisplayName.linkedin,
                isConnected: currentLoginType == LoginType.linkedin,
              ),
              space10,
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
    return Container(
      height: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ColorName.black.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          if (icon != null)
            icon!.image(
              width: 20.0,
              height: 20.0,
              // color: ColorName.black,
            ),
          if (icon == null)
            const Icon(Icons.email, size: 24, color: ColorName.white),
          space12,
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isConnected) _buildConnectedState() else _buildConnectButton(),
        ],
      ),
    );
  }

  Widget _buildConnectedState() {
    return Obx(() {
      final accounts = controller.myUserInfo.value?.accounts;
      final isPrimary = accounts?.any(
            (account) =>
                account.address == controller.myUserInfo.value?.address &&
                account.is_primary,
          ) ??
          false;
      final identifier = controller.myUserInfo.value?.login_type_identifier;
      return !isPrimary
          ? Row(
              children: [
                MakePrimaryButton(
                  address: controller.myUserInfo.value?.address ?? '',
                ),
                space12,
              ],
            )
          : Row(
              children: [
                IdentifierText(identifier: identifier),
                space12,
                const Button(
                  onPressed: null,
                  text: 'Primary Account',
                  size: ButtonSize.SMALL,
                  type: ButtonType.outline,
                  color: Colors.green,
                ),
                space12,
              ],
            );
    });
  }

  Widget _buildConnectButton() {
    return Obx(() {
      final isAddingAccount_provider =
          controller.addingOrSwitchingAccount_provider.value;
      final isLoading = isAddingAccount_provider == provider;
      final accounts = controller.myUserInfo.value?.accounts;
      final thisAccount = accounts?.firstWhereOrNull((account) {
        return (account.login_type == _loginType) ||
            (account.login_type == 'email' &&
                provider == Provider.email_passwordless);
      });
      final isPrimary = thisAccount?.is_primary ?? false;

      final thisTypeExistOnAccounts =
          accounts?.any((account) => account.login_type == _loginType) ?? false;

      if (thisTypeExistOnAccounts) {
        final existingAccount =
            accounts?.firstWhere((account) => account.login_type == _loginType);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IdentifierText(identifier: existingAccount?.login_type_identifier),
            if (!isPrimary) ...[
              space5,
              MakePrimaryButton(
                address: existingAccount?.address ?? '',
              ),
            ],
            if (isPrimary) ...[
              space5,
              const Button(
                onPressed: null,
                text: 'Primary',
                size: ButtonSize.SMALL,
                type: ButtonType.outline,
                color: Colors.green,
              ),
            ],
            space5,
            Button(
              loading: isLoading,
              text: 'Switch',
              size: ButtonSize.SMALL,
              type: ButtonType.solid,
              color: ColorName.black,
              onPressed: () => _showConnectConfirmationDialog(
                provider,
                title,
                email: thisAccount?.login_type_identifier,
              ),
            ),
          ],
        );
      }

      return Button(
        loading: isLoading,
        text: 'Connect',
        size: ButtonSize.SMALL,
        type: ButtonType.solid,
        color: ColorName.black,
        onPressed: () => _showConnectConfirmationDialog(
          provider,
          title,
          email: thisAccount?.login_type_identifier,
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
      return SizedBox(
        width: 100,
        height: 30,
        child: Button(
          loading: isLoading,
          text: 'Make primary',
          size: ButtonSize.SMALL,
          type: ButtonType.outline,
          color: Colors.orange,
          textColor: Colors.orange,
          onPressed: () {
            controller.setAccountAsPrimary(address);
          },
        ),
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
      backgroundColor: ColorName.cardBackground,
      title: const Text(
        'Account Connection',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'In process of merging accounts:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          space10,
          _buildInfoText(
            prefix: 'You will be ',
            highlighted: 'logged out',
            suffix: ' from your currently connected account',
            highlightColor: Colors.red,
          ),
          space10,
          _buildInfoText(
            prefix: 'You will be ',
            highlighted: 'logged in',
            suffix: ' with the new account',
            highlightColor: Colors.green,
          ),
          space10,
          _buildInfoText(
            prefix: 'Later, you can ',
            highlighted: 'log in',
            suffix: ' with your main account',
            highlightColor: ColorName.primaryBlue,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.close(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: () {
            Get.close();
            if (provider == Provider.email_passwordless) {
              controller.addOrSwitchAccount(provider, email: email);
            } else {
              controller.addOrSwitchAccount(provider);
            }
          },
          child: const Text(
            'Continue',
            style: TextStyle(
              color: ColorName.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoText({
    required String prefix,
    required String highlighted,
    required String suffix,
    required Color highlightColor,
  }) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: highlighted,
            style: TextStyle(
              color: highlightColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: suffix),
        ],
      ),
    );
  }
}

class IdentifierText extends StatelessWidget {
  const IdentifierText({
    super.key,
    required this.identifier,
  });

  final String? identifier;

  @override
  Widget build(BuildContext context) {
    return Text(
      identifier != null ? truncate(identifier!) : '',
      style: const TextStyle(
        fontSize: 10,
        color: Colors.indigo,
      ),
    );
  }
}

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({
    super.key,
    required this.loginType,
  });

  final String loginType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorName.black.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          space12,
          Expanded(
            child: Text(
              'Currently Logged in with ${loginTypeToDisplayName(loginType)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
