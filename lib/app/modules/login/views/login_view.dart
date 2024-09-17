import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';
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
                  Container(
                    height: 200,
                    child: Assets.images.logo.image(),
                  ),
                  Text('Welcome to',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.normal,
                      )),
                  Text(
                    'Podium',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                        space10,
                        Button(
                          size: ButtonSize.MEDIUM,
                          onPressed: () {
                            controller.loginWithEmail(
                              ignoreIfNotLoggedIn: false,
                            );
                          },
                          text: 'LOGIN WITH EMAIL',
                          type: ButtonType.transparent,
                          icon: Icon(
                            Icons.email_outlined,
                            color: ColorName.white,
                          ),
                        ),
                        Button(
                          size: ButtonSize.MEDIUM,
                          onPressed: () {
                            controller.loginWithX(ignoreIfNotLoggedIn: false);
                          },
                          text: 'LOGIN WITH X',
                          type: ButtonType.transparent,
                          icon: Assets.images.xPlatform.svg(
                            width: 20,
                            height: 20,
                            color: ColorName.white,
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Button(
                          size: ButtonSize.MEDIUM,
                          onPressed: () {
                            controller.loginWithGoogle(
                                ignoreIfNotLoggedIn: false);
                          },
                          text: 'LOGIN WITH GOOGLE',
                          type: ButtonType.transparent,
                          icon: Assets.images.gIcon.image(
                            width: 20,
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Button(
                          size: ButtonSize.MEDIUM,
                          onPressed: () {
                            controller.loginWithGithub(
                              ignoreIfNotLoggedIn: false,
                            );
                          },
                          text: 'LOGIN WITH GITHUB',
                          type: ButtonType.transparent,
                          icon: Assets.images.github.image(
                            color: ColorName.white,
                            height: 25,
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Button(
                          size: ButtonSize.MEDIUM,
                          onPressed: () {
                            controller.loginWithFaceBook(
                                ignoreIfNotLoggedIn: false);
                          },
                          text: 'LOGIN WITH FACEBOOK',
                          type: ButtonType.transparent,
                          icon: Assets.images.facebook.image(
                            height: 25,
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Button(
                          size: ButtonSize.MEDIUM,
                          onPressed: () {
                            controller.loginWithApple(
                                ignoreIfNotLoggedIn: false);
                          },
                          text: 'LOGIN WITH APPLE',
                          type: ButtonType.transparent,
                          icon: Assets.images.apple.image(
                            height: 25,
                            color: ColorName.white,
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Button(
                          size: ButtonSize.MEDIUM,
                          onPressed: () {
                            controller.loginWithLinkedIn(
                              ignoreIfNotLoggedIn: false,
                            );
                          },
                          text: 'LOGIN WITH LINKEDIN',
                          type: ButtonType.transparent,
                          icon: Assets.images.linkedin.image(
                            height: 20,
                          ),
                        ),
                        space10,
                      ],
                    );
                  }),
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
