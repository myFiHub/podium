import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';

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
                    /*  Hero(
                    tag: 'logo',
                    child: Container(
                      height: 200,
                      child: Assets.images.logo.image(),
                    ),
                  ), */
                    /*  Text(
                      'Podium',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ), */
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
                              Text(
                                'Welcome to',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Text(
                                'Podium',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              space10,
                              CircularProgressIndicator(),
                              space10,
                              Text('Please wait...'),
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
                              child: Text(
                                'Where the attention Pay.',
                                style: TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ),
                          Text('Please log in to start using your account.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                              )),
                          space10,
                          space10,
                          Button(
                            onPressed: () {
                              controller.loginWithEmail(
                                ignoreIfNotLoggedIn: false,
                              );
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
                              controller.loginWithX(ignoreIfNotLoggedIn: false);
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
                              controller.loginWithGoogle(
                                  ignoreIfNotLoggedIn: false);
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
                          Center(
                            child: Text(
                              "Or login with other methods:",
                              style: TextStyle(
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
                                      controller.loginWithFaceBook(
                                        ignoreIfNotLoggedIn: false,
                                      );
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
                                    controller.loginWithApple(
                                      ignoreIfNotLoggedIn: false,
                                    );
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
                                    controller.loginWithLinkedIn(
                                      ignoreIfNotLoggedIn: false,
                                    );
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
                                    controller.loginWithGithub(
                                      ignoreIfNotLoggedIn: false,
                                    );
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
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
