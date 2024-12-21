import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:shimmer/shimmer.dart';
import 'package:web3auth_flutter/enums.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormBuilderState>();
    return Scaffold(
      body: Center(
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
                          controller.globalController.isAutoLoggingIn.value;
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
                              CircularProgressIndicator(),
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
                              constraints: BoxConstraints(maxWidth: 200),
                              child: const Text(
                                'Where the attention Pay.',
                                style: TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ),
                          const Text('Please log in to start using your account.',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                              )),
                          space10,
                          space10,
                          Button(
                            onPressed: () {
                              controller.socialLogin(
                                  loginMethod: Provider.email_passwordless);
                            },
                            text: 'Login with Email',
                            size: ButtonSize.LARGE,
                            type: ButtonType.solid,
                            color: ColorName.black,
                            blockButton: true,
                          ),
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
                          SizedBox(
                            height: 10,
                          ),
                          Button(
                            onPressed: () {
                              controller.socialLogin(
                                  loginMethod: Provider.google);
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
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                        loginMethod: Provider.apple);
                                  },
                                  icon: Assets.images.apple.image(
                                    color: ColorName.white,
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
                    Obx(() {
                      final referrer = controller.referrer.value;
                      final referrerIsFul = controller.referrerIsFul.value;
                      if (referrer == null) return const SizedBox();
                      return Positioned(
                        top: 60,
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
                                      src: referrer.avatar,
                                      alt: referrer.fullName,
                                      size: 20,
                                    ),
                                    space5,
                                    Shimmer.fromColors(
                                      baseColor: Colors.white,
                                      highlightColor: ColorName.primaryBlue,
                                      child: Text(
                                        referrer.fullName,
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
                        )
                      );
                    }) 
                  ],
                ),
              ),
            ),
          ),
        )
      ),
    );
  }
}
