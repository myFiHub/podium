import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3auth_flutter/enums.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormBuilderState>();
    return PageWrapper(
      child: Scaffold(
        body: Stack(
          children: [
            Obx(
              () {
                final referrer = controller.referrer.value;
                final referrerIsFul = controller.referrerIsFul.value;
                final referrerNotFound = controller.referrerNotFound.value;
                if (referrerNotFound)
                  return Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Referrer not found',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                if (referrer == null) return const SizedBox();
                return Positioned(
                    top: 12,
                    right: 0,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ColorName.black,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ColorName.cardBorder,
                          width: 1,
                        ),
                      ),
                      width: Get.width - 20,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Referred by: ',
                                  style: TextStyle(
                                    color: ColorName.white,
                                    fontSize: 12,
                                  ),
                                ),
                                space5,
                                Img(
                                  src: referrer.image ?? '',
                                  alt: referrer.name ?? '',
                                  size: 20,
                                ),
                                space5,
                                Shimmer.fromColors(
                                  baseColor: Colors.white,
                                  highlightColor: ColorName.primaryBlue,
                                  child: Text(
                                    referrer.name ?? '',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (referrerIsFul)
                              const Text(
                                'but User\'s referrals are all used up',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ));
              },
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    child: FormBuilder(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(() {
                            final isLoggingIn = controller.isLoggingIn.value ||
                                controller
                                    .globalController.isAutoLoggingIn.value;
                            if (isLoggingIn) {
                              return Center(
                                child: Column(
                                  children: [
                                    Hero(
                                      tag: 'logo',
                                      child: Container(
                                        height: 200,
                                        child: Assets.images.logo.image(),
                                      ),
                                    ),
                                    const Text(
                                      'Welcome to',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                    const Text(
                                      'Podium',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    space10,
                                    const LoadingWidget(),
                                    space10,
                                    const Text('Please wait...'),
                                  ],
                                ),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 200),
                                    child: const Text(
                                      'Where attention pays.',
                                      style: TextStyle(
                                        fontSize: 35,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ),
                                ),
                                const Text(
                                    'Please log in to start using your account.',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w300,
                                    )),
                                space10,
                                space10,
                                Button(
                                  onPressed: () {
                                    controller.socialLogin(
                                        loginMethod: Provider.twitter);
                                  },
                                  text: 'Enter Podium with X',
                                  icon: Assets.images.xPlatform.image(
                                    width: 20,
                                    height: 20,
                                    color: ColorName.white,
                                  ),
                                  size: ButtonSize.LARGE,
                                  type: ButtonType.solid,
                                  color: ColorName.black,
                                  blockButton: true,
                                ),
                                space10,
                                Button(
                                  onPressed: () {
                                    controller.socialLogin(
                                        loginMethod: Provider.apple);
                                  },
                                  text: 'Apple Login',
                                  icon: Assets.images.apple.image(
                                    width: 20,
                                    height: 20,
                                    color: ColorName.white,
                                  ),
                                  size: ButtonSize.LARGE,
                                  type: ButtonType.solid,
                                  color: ColorName.black,
                                  blockButton: true,
                                ),
                                space10,
                                Button(
                                  onPressed: () {
                                    controller.socialLogin(
                                      loginMethod: Provider.google,
                                    );
                                  },
                                  text: 'Sign in with Google',
                                  icon: Assets.images.gIcon.image(
                                    width: 20,
                                  ),
                                  size: ButtonSize.LARGE,
                                  type: ButtonType.solid,
                                  color: ColorName.black,
                                  blockButton: true,
                                ),
                                space10,
                                Button(
                                  onPressed: () {
                                    controller.socialLogin(
                                      loginMethod: Provider.email_passwordless,
                                    );
                                  },
                                  text: 'Login with Email',
                                  size: ButtonSize.LARGE,
                                  type: ButtonType.solid,
                                  color: ColorName.black,
                                  blockButton: true,
                                ),
                                space10,
                                const Center(
                                  child: Text(
                                    "Or login with other methods:",
                                    style: const TextStyle(
                                      color: ColorName.greyText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                space10,
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: ColorName.black,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                          onPressed: () {
                                            controller.socialLogin(
                                                loginMethod: Provider.facebook);
                                          },
                                          icon: Assets.images.facebook.image(
                                            color: ColorName.white,
                                            height: 25,
                                          )),
                                    ),
                                    Container(
                                      width: 80,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: ColorName.black,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          controller.socialLogin(
                                              loginMethod: Provider.linkedin);
                                        },
                                        icon: Assets.images.linkedin.image(
                                          height: 25,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 80,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: ColorName.black,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          controller.socialLogin(
                                              loginMethod: Provider.github);
                                        },
                                        icon: Assets.images.github.image(
                                          color: ColorName.white,
                                          height: 25,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }),
                          space10,
                          const ReferralInput(),
                          space10,
                          Center(
                            child: Text(
                              "Version: " + Env.VERSION,
                              style: const TextStyle(
                                color: ColorName.greyText,
                                fontSize: 10,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                          space10,
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: ColorName.greyText,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w300,
                                      height: 2,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text:
                                            "By logging in, you agree to our ",
                                      ),
                                      TextSpan(
                                        text: "End User License Agreement",
                                        style: const TextStyle(
                                          color: ColorName.primaryBlue,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            launchUrl(Uri.parse(
                                                "https://docs.google.com/document/d/e/2PACX-1vRnlrIO5cBCm4Zlmn4WMQzCzl5TXpHsS5vN22j4NP8HIgPiWB8YHo0syZ9oVp1qvfh-9tlDEWvA5P8I/pub"));
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: ColorName.greyText,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w300,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: "and ",
                                      ),
                                      TextSpan(
                                        text: "Privacy Policy",
                                        style: const TextStyle(
                                          color: ColorName.primaryBlue,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            launchUrl(Uri.parse(
                                                "https://docs.google.com/document/d/e/2PACX-1vQdVu6L4I-aubHE15l876bcloKgqO-FCWXn5OW3rhVy26EPgsSVpTP35kX9TGbD8jOyZ5TzL7dPnzOO/pub"));
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReferralInput extends GetView<LoginController> {
  const ReferralInput({super.key});

  void _showReferralDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: ColorName.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter Referrer ID',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final referrerNotFound = controller.referrerNotFound.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.textController,
                        decoration: InputDecoration(
                          hintText: 'Enter referrer ID',
                          border: const OutlineInputBorder(),
                          errorText: referrerNotFound ? 'User not found' : null,
                          errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.paste),
                      onPressed: () {
                        controller.handlePaste();
                        Get.close();
                      },
                      tooltip: 'Paste',
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.close(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Get.close();
                      controller.handleConfirm();
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoggingIn = controller.isLoggingIn.value ||
          controller.globalController.isAutoLoggingIn.value;
      if (isLoggingIn) return const SizedBox.shrink();
      return InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: _showReferralDialog,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            textAlign: TextAlign.center,
            'Referred by someone? Enter the ID',
            style: TextStyle(
              color: ColorName.greyText,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );
    });
  }
}
