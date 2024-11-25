import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:particle_auth_core/particle_auth_core.dart';

import 'package:particle_base/model/login_info.dart' as PLoginInfo;

import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/mixins/particleAuth.dart';
import 'package:podium/app/modules/global/utils/web3AuthProviderToLoginTypeString.dart';
import 'package:podium/app/modules/web3Auth_redirected/controllers/web3Auth_redirected_controller.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_particle_user.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/loginType.dart';

import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';
import 'package:uuid/uuid.dart';
import 'package:web3auth_flutter/enums.dart';
import 'package:web3auth_flutter/input.dart';
import 'package:web3auth_flutter/output.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3dart/web3dart.dart';

class LoginController extends GetxController with ParticleAuthUtils {
  final globalController = Get.find<GlobalController>();
  final isLoggingIn = false.obs;
  final $isAutoLoggingIn = false.obs;
  final email = ''.obs;
  final password = ''.obs;
  final web3AuthLogintype = ''.obs;
  Function? afterLogin = null;

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

  socialLogin({
    required Provider loginMethod,
    ignoreIfNotLoggedIn = false,
  }) async {
    isLoggingIn.value = true;
    try {
      final userInfo = await Web3AuthFlutter.getUserInfo();
      final privateKey = await Web3AuthFlutter.getPrivKey();
      _continueSocialLoginWithUserInfoAndPrivateKey(
        privateKey: privateKey,
        userInfo: userInfo,
        loginMethod: loginMethod,
      );
    } catch (e) {
      if (ignoreIfNotLoggedIn) {
        isLoggingIn.value = false;
        return;
      }
      try {
        final res = await Web3AuthFlutter.login(
          LoginParams(
            loginProvider: loginMethod,
            mfaLevel: MFALevel.DEFAULT,
            // extraLoginOptions: ExtraLoginOptions(
            //   login_hint: "mhsnprvr@gmail.com",
            // ),
          ),
        );
        final privateKey = res.privKey;
        final userInfo = res.userInfo;
        if (privateKey == null || userInfo == null) {
          isLoggingIn.value = false;
          return;
        }
        _continueSocialLoginWithUserInfoAndPrivateKey(
          privateKey: privateKey,
          userInfo: userInfo,
          loginMethod: loginMethod,
        );
      } catch (e) {
        isLoggingIn.value = false;
        log.e(e);
        Toast.error(
          message: 'Error logging in, please try again, or use another method',
        );
      }
    }
  }

  _continueSocialLoginWithUserInfoAndPrivateKey(
      {required String privateKey,
      required TorusUserInfo userInfo,
      required Provider loginMethod}) {
    final ethereumKeyPair = EthPrivateKey.fromHex(privateKey);
    final publicAddress = ethereumKeyPair.address.hex;
    final uid = addressToUuid(publicAddress);
    final loginType = web3AuthProviderToLoginTypeString(loginMethod);
    final particleWalletInfo = FirebaseParticleAuthUserInfo(
      uuid: uid,
      wallets: [
        ParticleAuthWallet(
          address: publicAddress,
          chain: 'evm_chain',
        ),
      ],
    );
    _socialLogin(
      id: uid,
      name: userInfo.name ?? '',
      email: userInfo.email ?? '',
      avatar: userInfo.profileImage ?? '',
      particleWalletInfo: particleWalletInfo,
      loginType: loginType,
      loginTypeIdentifier: userInfo.verifierId,
    );
  }

  _socialLogin({
    required String id,
    required String name,
    required String email,
    required String avatar,
    required FirebaseParticleAuthUserInfo particleWalletInfo,
    required String loginType,
    String? loginTypeIdentifier,
  }) async {
    final userId = id;
    if (email.isEmpty) {
      //since email will be used in jitsi meet, we have to save something TODO: save user id in jitsi
      email = Uuid().v4().replaceAll('-', '') + '@gmail.com';
    }

    // this user will be saved, only if uuid of particle auth is not registered, so empty local wallet address is fine
    final userToCreate = UserInfoModel(
      id: userId,
      fullName: name,
      email: email,
      avatar: avatar,
      localWalletAddress: '',
      savedParticleWalletAddress: particleWalletInfo.wallets.first.address,
      savedParticleUserInfo: particleWalletInfo,
      following: [],
      numberOfFollowers: 0,
      loginType: loginType,
      loginTypeIdentifier: loginTypeIdentifier,
      lowercasename: name.toLowerCase(),
    );

    UserInfoModel? user = await saveUserLoggedInWithSocialIfNeeded(
      user: userToCreate,
    );

    if (user == null) {
      Toast.error(
        message: 'Error logging in',
      );
      return;
    }
    late String? savedName;
    // ignore: unnecessary_null_comparison
    if (user.fullName.isEmpty || user.fullName == null) {
      savedName = await forceSaveUserFullName(user: user);
      UserInfoModel? myUser;
      try {
        myUser = (await getUsersByIds([user.id])).first;
      } catch (e) {
        myUser = null;
      }
      user = myUser;
      if (user == null) {
        Toast.error(
          message: 'Error logging in',
        );
        globalController.setLoggedIn(false);
        isLoggingIn.value = false;
        return;
      }
    } else {
      savedName = user.fullName;
    }
    if (savedName != null) {
      globalController.currentUserInfo.value = user;
      // globalController.particleAuthUserInfo.value = particleUser;
      LoginTypeService.setLoginType(loginType);
      globalController.setLoggedIn(true);
      isLoggingIn.value = false;
      if (afterLogin != null) {
        afterLogin!();
        afterLogin = null;
      }
      // Navigate.toInitial();
    } else {
      globalController.setLoggedIn(false);
      Toast.error(
        message: 'A name is required',
      );
      isLoggingIn.value = false;
    }
  }

  Future<String?> forceSaveUserFullName({required UserInfoModel user}) async {
    final _formKey = GlobalKey<FormBuilderState>();
    String fullName = '';
    final name = await Get.bottomSheet(
      isDismissible: false,
      Container(
        width: Get.width,
        height: 300,
        color: ColorName.cardBackground,
        padding: EdgeInsets.all(12),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'the name you want to use in the platform',
                style: TextStyle(
                  color: ColorName.greyText,
                ),
              ),
              FormBuilderField(
                builder: (FormFieldState<String?> field) {
                  return Input(
                    hintText: 'Full Name',
                    onChanged: (value) => fullName = value,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'Name is required'),
                      FormBuilderValidators.minLength(3,
                          errorText: 'Name too short'),
                    ]),
                  );
                },
                name: 'fullName',
              ),
              Button(
                text: 'SUBMIT',
                blockButton: true,
                type: ButtonType.gradient,
                onPressed: () {
                  final re = _formKey.currentState?.saveAndValidate();
                  if (re == true) {
                    Navigator.pop(Get.context!, fullName);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
    final savedName = await saveNameForUserById(
      userId: user.id,
      name: name,
    );

    return savedName;
  }
}
