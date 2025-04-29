import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/myProfile/controllers/my_profile_controller.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/styles.dart';
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorName.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      space12,
                      Expanded(
                        child: Text(
                          'Currently connected with ${_getLoginTypeDisplayName(currentLoginType)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                space24,
              ],
              _buildLoginOption(
                provider: Provider.twitter,
                icon: Assets.images.xPlatform,
                title: 'X (Twitter)',
                isConnected: currentLoginType == 'twitter',
              ),
              space10,
              _buildLoginOption(
                provider: Provider.apple,
                icon: Assets.images.apple,
                title: 'Apple',
                isConnected: currentLoginType == 'apple',
              ),
              space10,
              _buildLoginOption(
                provider: Provider.google,
                icon: Assets.images.gIcon,
                title: 'Google',
                isConnected: currentLoginType == 'google',
              ),
              space10,
              _buildLoginOption(
                provider: Provider.email_passwordless,
                icon: null,
                title: 'Email',
                isConnected: currentLoginType == 'email',
              ),
              space10,
              _buildLoginOption(
                provider: Provider.facebook,
                icon: Assets.images.facebook,
                title: 'Facebook',
                isConnected: currentLoginType == 'facebook',
              ),
              space10,
              _buildLoginOption(
                provider: Provider.linkedin,
                icon: Assets.images.linkedin,
                title: 'LinkedIn',
                isConnected: currentLoginType == 'linkedin',
              ),
              space10,
              _buildLoginOption(
                provider: Provider.github,
                icon: Assets.images.github,
                title: 'GitHub',
                isConnected: currentLoginType == 'github',
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLoginOption({
    required Provider provider,
    required dynamic icon,
    required String title,
    required bool isConnected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorName.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          if (icon != null)
            icon.image(
              width: 24.0,
              height: 24.0,
              color: ColorName.black,
            ),
          if (icon == null)
            const Icon(Icons.email, size: 24, color: ColorName.black),
          space12,
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isConnected)
            const Icon(Icons.check_circle, color: Colors.green)
          else
            Button(
              text: 'Connect',
              size: ButtonSize.SMALL,
              type: ButtonType.solid,
              color: ColorName.black,
              onPressed: () {
                _showConnectConfirmationDialog(provider, title);
              },
            ),
        ],
      ),
    );
  }

  void _showConnectConfirmationDialog(Provider provider, String title) {
    Get.dialog(
      AlertDialog(
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
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: '• You will be '),
                  TextSpan(
                    text: 'logged out',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: ' from your currently connected account'),
                ],
              ),
            ),
            space10,
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: '• You will be '),
                  TextSpan(
                    text: 'logged in',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: ' with the new account'),
                ],
              ),
            ),
            space10,
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: '• Later, you can '),
                  TextSpan(
                    text: 'log in',
                    style: TextStyle(
                      color: ColorName.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: ' with your main account'),
                ],
              ),
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
              // TODO: Implement the actual connection logic here
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
      ),
    );
  }

  String _getLoginTypeDisplayName(String loginType) {
    switch (loginType) {
      case 'twitter':
        return 'X (Twitter)';
      case 'apple':
        return 'Apple';
      case 'google':
        return 'Google';
      case 'email':
        return 'Email';
      case 'facebook':
        return 'Facebook';
      case 'linkedin':
        return 'LinkedIn';
      case 'github':
        return 'GitHub';
      default:
        return loginType;
    }
  }
}
