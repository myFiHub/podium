import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/login/widgets/launch_loader.dart';
import 'package:podium/app/modules/login/widgets/referral_input.dart';
import 'package:podium/app/modules/myProfile/views/connected_accounts_view.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/root.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3auth_flutter/enums.dart';

import '../controllers/login_controller.dart';

const _brandCyan = Color(0xFF4ED6DC);

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormBuilderState>();
    final addingOrSwitchingAccount_provider =
        Get.find<GlobalController>().addingOrSwitchingAccount_provider.value;
    if (addingOrSwitchingAccount_provider != null) {
      return const ConnectedAccountsView();
    }
    return PageWrapper(
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: FormBuilder(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _BrandHeader(),
                          const SizedBox(height: 20),
                          const _ReferrerBanner(),
                          Obx(() {
                            final isLoggingIn = controller.isLoggingIn.value ||
                                controller
                                    .globalController.isAutoLoggingIn.value;
                            if (isLoggingIn) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ProviderButton(
                                  onPressed: () {
                                    controller.socialLogin(
                                        loginMethod: Provider.twitter);
                                  },
                                  label: 'Enter Podium with X',
                                  highlighted: true,
                                  icon: Assets.images.xPlatform.image(
                                    width: 18,
                                    height: 18,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _ProviderButton(
                                  onPressed: () {
                                    controller.socialLogin(
                                        loginMethod: Provider.apple);
                                  },
                                  label: 'Continue with Apple',
                                  icon: Assets.images.apple.image(
                                    width: 20,
                                    height: 20,
                                    color: ColorName.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _ProviderButton(
                                  onPressed: () {
                                    controller.socialLogin(
                                      loginMethod: Provider.google,
                                    );
                                  },
                                  label: 'Continue with Google',
                                  icon: Assets.images.gIcon.image(
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _ProviderButton(
                                  onPressed: () {
                                    controller.socialLogin(
                                      loginMethod: Provider.email_passwordless,
                                    );
                                  },
                                  label: 'Continue with Email',
                                  icon: const Icon(
                                    Icons.mail_outline_rounded,
                                    size: 21,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const _OrDivider(),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ProviderTile(
                                        tooltip: 'Facebook',
                                        onPressed: () {
                                          controller.socialLogin(
                                              loginMethod: Provider.facebook);
                                        },
                                        icon: Assets.images.facebook.image(
                                          color: ColorName.white,
                                          height: 22,
                                          width: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ProviderTile(
                                        tooltip: 'LinkedIn',
                                        onPressed: () {
                                          controller.socialLogin(
                                              loginMethod: Provider.linkedin);
                                        },
                                        icon: Assets.images.linkedin.image(
                                          height: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ProviderTile(
                                        tooltip: 'GitHub',
                                        onPressed: () {
                                          controller.socialLogin(
                                              loginMethod: Provider.github);
                                        },
                                        icon: Assets.images.github.image(
                                          color: ColorName.white,
                                          height: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 8),
                          ReferralInput(),
                          const SizedBox(height: 8),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                color: ColorName.greyText,
                                fontSize: 12,
                                height: 1.6,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'By continuing, you agree to our ',
                                ),
                                TextSpan(
                                  text: 'End User License Agreement',
                                  style: const TextStyle(
                                    color: ColorName.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      launchUrl(Uri.parse(
                                          "https://docs.google.com/document/d/e/2PACX-1vRnlrIO5cBCm4Zlmn4WMQzCzl5TXpHsS5vN22j4NP8HIgPiWB8YHo0syZ9oVp1qvfh-9tlDEWvA5P8I/pub"));
                                    },
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    color: ColorName.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      launchUrl(Uri.parse(
                                          "https://docs.google.com/document/d/e/2PACX-1vQdVu6L4I-aubHE15l876bcloKgqO-FCWXn5OW3rhVy26EPgsSVpTP35kX9TGbD8jOyZ5TzL7dPnzOO/pub"));
                                    },
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Version ${Env.VERSION}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ColorName.greyText.withAlpha(150),
                              fontSize: 12,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Obx(() {
                final isLoggingIn = controller.isLoggingIn.value ||
                    controller.globalController.isAutoLoggingIn.value;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: isLoggingIn
                      ? const LaunchLoader()
                      : const SizedBox.shrink(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _brandCyan.withAlpha(45),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo_disc.png',
            width: 96,
            height: 96,
            filterQuality: FilterQuality.medium,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'PODIUM',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            color: _brandCyan,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Where attention pays.',
          textAlign: TextAlign.center,
          style: AppText.pageTitle,
        ),
        const SizedBox(height: 10),
        const Text(
          'Join live audio rooms, speak your mind and get rewarded. Sign in to start using your account.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: ColorName.greyText,
          ),
        ),
      ],
    );
  }
}

class _ReferrerBanner extends GetView<LoginController> {
  const _ReferrerBanner();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final referrer = controller.referrer.value;
      final referrerIsFul = controller.referrerIsFul.value;
      final referrerNotFound = controller.referrerNotFound.value;
      if (referrerNotFound) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.danger.withAlpha(24),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.danger.withAlpha(80)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Referrer not found',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      if (referrer == null) return const SizedBox.shrink();
      return AppCard(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Img(
                  src: referrer.image ?? '',
                  alt: referrer.name ?? '',
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('REFERRED BY', style: AppText.label),
                      const SizedBox(height: 2),
                      Shimmer.fromColors(
                        baseColor: Colors.white,
                        highlightColor: ColorName.primaryBlue,
                        child: Text(
                          referrer.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
              ],
            ),
            if (referrerIsFul) ...[
              const SizedBox(height: 10),
              const AppPill(
                label: 'But their referrals are all used up',
                color: AppColors.accent,
                icon: Icons.info_outline_rounded,
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _ProviderButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;
  final bool highlighted;
  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = highlighted ? Colors.black : Colors.white;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        backgroundColor: highlighted ? Colors.white : AppColors.fill,
        foregroundColor: fg,
        side: BorderSide(
          color: highlighted ? Colors.white : AppColors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Center(child: icon)),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _ProviderTile({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: EdgeInsets.zero,
          backgroundColor: AppColors.fill,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: icon,
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: ColorName.greyText,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border, height: 1)),
      ],
    );
  }
}
