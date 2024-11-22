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
          child: Container(
            child: FormBuilder(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'logo',
                    child: Container(
                      height: 200,
                      child: Assets.images.logo.image(),
                    ),
                  ),
                  Text(
                    'Podium',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Where attention pays.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      )),
                  Obx(() {
                    final isLoggingIn = controller.isLoggingIn.value ||
                        controller.globalController.isAutoLoggingIn.value;
                    if (isLoggingIn) {
                      return Column(
                        children: [
                          space10,
                          CircularProgressIndicator(),
                          space10,
                          Text('please wait...'),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Button(
                          onPressed: () {
                            controller.loginWithEmail(
                              ignoreIfNotLoggedIn: false,
                            );
                          },
                          text: 'Web3Auth login',
                          size: ButtonSize.LARGE,
                          type: ButtonType.solid,
                          color: ColorName.black,
                          blockButton: true,
                        ),
                        space10,
                        Button(
                          onPressed: () {
                            controller.loginWithEmail(
                              ignoreIfNotLoggedIn: false,
                            );
                          },
                          text: 'LOGIN WITH EMAIL',
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
                          text: 'LOGIN WITH X',
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
                          text: 'LOGIN WITH GOOGLE',
                          icon: Assets.images.gIcon.image(
                            width: 20,
                          ),
                          size: ButtonSize.LARGE,
                          type: ButtonType.solid,
                          color: ColorName.black,
                          blockButton: true,
                        ),
                        space10,
                        Text(
                          "Or login with other methods:",
                          style: TextStyle(
                            color: ColorName.greyText,
                            fontSize: 12,
                          ),
                        ),
                        space10,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: ColorName.black,
                                borderRadius: BorderRadius.circular(5),
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
                              decoration: BoxDecoration(
                                color: ColorName.black,
                                borderRadius: BorderRadius.circular(5),
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
                              decoration: BoxDecoration(
                                color: ColorName.black,
                                borderRadius: BorderRadius.circular(5),
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
                              decoration: BoxDecoration(
                                color: ColorName.black,
                                borderRadius: BorderRadius.circular(5),
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
                  Text(
                    "Version: " + Env.VERSION,
                    style: const TextStyle(
                      color: ColorName.greyText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
