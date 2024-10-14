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

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormBuilderState>();
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: Get.height,
              child: FormBuilder(
                key: _formKey,
                child: Center(
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
                                controller.loginWithX(
                                    ignoreIfNotLoggedIn: false);
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
                              Text(
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
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (referrerIsFul)
                            Text(
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
            })
          ],
        ),
      ),
    );
  }
}
