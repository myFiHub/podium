import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:particle_auth_core/particle_auth_core.dart';
import 'package:particle_base/model/user_info.dart' as ParticleUser;
import 'package:particle_base/model/login_info.dart' as PLoginInfo;

import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/mixins/particleAuth.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_particle_user.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/loginType.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:uuid/uuid.dart';

class LoginController extends GetxController
    with ParticleAuthUtils, FireBaseUtils {
  final globalController = Get.find<GlobalController>();
  final isLoggingIn = false.obs;
  final $isAutoLoggingIn = false.obs;
  final email = ''.obs;
  final password = ''.obs;

  @override
  void onInit() {
    $isAutoLoggingIn.value = globalController.isAutoLoggingIn.value;
    globalController.isAutoLoggingIn.listen((v) {
      $isAutoLoggingIn.value = v;
    });
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  login({String? manualEmail, String? manualPassword, bool? fromSignUp}) async {
    isLoggingIn.value = true;
    final enteredEmail = manualEmail == null ? email.value : manualEmail;
    final enteredPassword =
        manualPassword == null ? password.value : manualPassword;
    try {
      ParticleUser.UserInfo? particleUser;
      if (fromSignUp == true) {
        try {
          final isConnected = await ParticleAuthCore.isConnected();
          if (isConnected) {
            Get.snackbar('Error', 'Error logging in');
            return;
          }
          particleUser = await ParticleAuthCore.getUserInfo();
          globalController.particleAuthUserInfo.value = particleUser;
        } catch (e) {
          log.e('Error logging in from signUp => particle auth: $e');
          Get.snackbar('Error', 'Error logging in');
          return;
        }
        Get.snackbar('Success', 'Account created successfully, logging in');
      } else {
        particleUser = await particleLogin(email.value);
        if (particleUser != null) {
          globalController.particleAuthUserInfo.value = particleUser;
        } else {
          Get.snackbar('Error', 'Error logging in');
          return;
        }
      }
      UserCredential firebaseUserCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: enteredEmail.trim(),
        password: enteredPassword.trim(),
      );
      final user = FirebaseAuth.instance.currentUser;
      globalController.firebaseUser.value = user;
      try {
        final currentUserInfo =
            await globalController.getUserInfoById(user!.uid);
        if (currentUserInfo == null) {
          Get.snackbar('Error', 'Error logging in');
          return;
        }
        await saveParticleUserInfoToFirebaseIfNeeded(
          particleUser: particleUser!,
          myUserId: user.uid,
        );
        currentUserInfo.localParticleUserInfo = particleUser;
        globalController.currentUserInfo.value = currentUserInfo;
        final storage = GetStorage();
        storage.write(StorageKeys.userEmail, enteredEmail);
        globalController.firebaseUserCredential.value = firebaseUserCredential;
        globalController.setLoggedIn(true);
        LoginTypeService.setLoginType(LoginType.emailAndPassword);
        Navigate.to(
          type: NavigationTypes.offAllNamed,
          route: Routes.HOME,
        );
      } catch (e) {
        Navigate.to(
          type: NavigationTypes.offAllNamed,
          route: Routes.LOGIN,
        );
        return;
      }
    } on FirebaseAuthException catch (e) {
      // Handle errors, such as invalid email or password
      log.e('Error signing in: ${e.code}');
      final errorMessage = e.message == 'invalid-credential'
          ? 'Invalid email or password'
          : e.message;
      Get.snackbar('Error', errorMessage ?? 'Error logging in');
    } catch (e) {
      log.e('Error signing in: $e');
    } finally {
      isLoggingIn.value = false;
    }
  }

  loginWithX({required bool ignoreIfNotLoggedIn}) async {
    isLoggingIn.value = true;
    try {
      final particleUser = await particleSocialLogin(
        type: PLoginInfo.LoginType.twitter,
      );
      if (particleUser != null) {
        await _socialLogin(
          id: particleUser.uuid,
          name: particleUser.name!,
          email: particleUser.thirdpartyUserInfo!.userInfo.email ?? '',
          avatar: particleUser.avatar!,
          particleUser: particleUser,
          loginType: LoginType.x,
        );
      } else {
        if (ignoreIfNotLoggedIn == false) {
          Get.snackbar('Error', 'Error logging in');
        }
        return;
      }
    } catch (e) {
      log.e('Error logging in with X: $e');
      Get.snackbar('Error', 'Error logging in');
      return;
    } finally {
      isLoggingIn.value = false;
    }
  }

  loginWithGoogle({required bool ignoreIfNotLoggedIn}) async {
    isLoggingIn.value = true;
    try {
      final particleUser = await particleSocialLogin(
        type: PLoginInfo.LoginType.google,
      );
      if (particleUser != null) {
        await _socialLogin(
          id: particleUser.uuid,
          name: particleUser.name!,
          email: particleUser.googleEmail!,
          avatar: particleUser.avatar!,
          particleUser: particleUser,
          loginType: LoginType.google,
        );
      } else {
        if (!ignoreIfNotLoggedIn) {
          Get.snackbar('Error', 'Error logging in');
        }
        return;
      }
    } catch (e) {
      log.e('Error logging in with Google: $e');
      Get.snackbar('Error', 'Error logging in');
      return;
    } finally {
      isLoggingIn.value = false;
    }
  }

  loginWithLinkedIn({required bool ignoreIfNotLoggedIn}) async {
    isLoggingIn.value = true;
    try {
      final particleUser = await particleSocialLogin(
        type: PLoginInfo.LoginType.linkedin,
      );
      if (particleUser != null) {
        _socialLogin(
          id: particleUser.uuid,
          name: particleUser.name!,
          email: particleUser.linkedinEmail!,
          avatar: particleUser.avatar!,
          particleUser: particleUser,
          loginType: LoginType.linkedin,
        );
      } else {
        Get.snackbar('Error', 'Error logging in');
        return;
      }
    } catch (e) {
      log.e('Error logging in with LinkedIn: $e');
      Get.snackbar('Error', 'Error logging in');
      return;
    } finally {
      isLoggingIn.value = false;
    }
  }

  loginWithFaceBook({required bool ignoreIfNotLoggedIn}) async {
    isLoggingIn.value = true;
    try {
      final particleUser = await particleSocialLogin(
        type: PLoginInfo.LoginType.facebook,
      );
      if (particleUser != null) {
        _socialLogin(
          id: particleUser.uuid,
          name: particleUser.name!,
          email: particleUser.facebookEmail!,
          avatar: particleUser.avatar!,
          particleUser: particleUser,
          loginType: LoginType.facebook,
        );
      } else {
        Get.snackbar('Error', 'Error logging in');
        return;
      }
    } catch (e) {
      log.e('Error logging in with Facebook: $e');
      Get.snackbar('Error', 'Error logging in');
      return;
    } finally {
      isLoggingIn.value = false;
    }
  }

  loginWithApple({required bool ignoreIfNotLoggedIn}) async {
    isLoggingIn.value = true;
    try {
      final particleUser = await particleSocialLogin(
        type: PLoginInfo.LoginType.apple,
      );
      if (particleUser != null) {
        _socialLogin(
          id: particleUser.uuid,
          name: particleUser.name!,
          email: particleUser.appleEmail!,
          avatar: particleUser.avatar!,
          particleUser: particleUser,
          loginType: LoginType.apple,
        );
      } else {
        Get.snackbar('Error', 'Error logging in');
        return;
      }
    } catch (e) {
      log.e('Error logging in with Apple: $e');
      Get.snackbar('Error', 'Error logging in');
      return;
    } finally {
      isLoggingIn.value = false;
    }
  }

  _socialLogin({
    required String id,
    required String name,
    required String email,
    required String avatar,
    required ParticleUser.UserInfo particleUser,
    required String loginType,
  }) async {
    final userId = id;
    if (email.isEmpty) {
      //since email will be used in jitsi meet, we have to save something TODO: save user id in jitsi
      email = Uuid().v4().replaceAll('-', '') + '@gmail.com';
    }
    final walletsToSave = particleUser.wallets
        .map((e) =>
            ParticleAuthWallet(address: e.publicAddress, chain: e.chainName))
        .toList();
    final particleWalletInfo = FirebaseParticleAuthUserInfo(
      uuid: userId,
      wallets: walletsToSave,
    );
    // this user will be saved, only if uuid of particle auth is not registered, so empty local wallet address is fine
    final userToCreate = UserInfoModel(
      id: userId,
      fullName: name,
      email: email,
      avatar: avatar,
      localWalletAddress: '',
      savedParticleUserInfo: particleWalletInfo,
      following: [],
      numberOfFollowers: 0,
      lowercasename: name.toLowerCase(),
    );

    final user = await saveUserLoggedInWithSocialIfNeeded(user: userToCreate);
    if (user == null) {
      Get.snackbar('Error', 'Error logging in');
      return;
    }
    globalController.currentUserInfo.value = user;
    globalController.particleAuthUserInfo.value = particleUser;
    LoginTypeService.setLoginType(loginType);
    globalController.setLoggedIn(true);
    isLoggingIn.value = false;
    Navigate.to(
      type: NavigationTypes.offAllNamed,
      route: Routes.HOME,
    );
  }

  openSocialLoginBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        height: 340,
        width: Get.width,
        decoration: BoxDecoration(
          color: ColorName.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: <Widget>[
            Button(
              size: ButtonSize.MEDIUM,
              onPressed: () {
                loginWithX(ignoreIfNotLoggedIn: false);
                Get.back();
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
                loginWithGoogle(ignoreIfNotLoggedIn: false);
                Get.back();
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
                loginWithFaceBook(ignoreIfNotLoggedIn: false);
                Get.back();
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
                loginWithApple(ignoreIfNotLoggedIn: false);
                Get.back();
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
                loginWithLinkedIn(ignoreIfNotLoggedIn: false);
                Get.back();
              },
              text: 'LOGIN WITH LINKEDIN',
              type: ButtonType.transparent,
              icon: Assets.images.linkedin.image(
                height: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
