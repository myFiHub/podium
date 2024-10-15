import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:particle_auth_core/particle_auth_core.dart';
import 'package:particle_base/model/user_info.dart' as ParticleUser;
import 'package:particle_base/model/login_info.dart' as PLoginInfo;
import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';

import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/mixins/particleAuth.dart';
import 'package:podium/app/modules/global/utils/switchParticleChain.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_particle_user.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/models/starsArenaUser.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/loginType.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';
import 'package:uuid/uuid.dart';

class LoginParametersKeys {
  static const referrerId = 'referrerId';
}

class LoginController extends GetxController with ParticleAuthUtils {
  final globalController = Get.find<GlobalController>();
  final isLoggingIn = false.obs;
  final $isAutoLoggingIn = false.obs;
  final email = ''.obs;
  final password = ''.obs;
  Function? afterLogin = null;
  String referrerId = '';
  final referrer = Rxn<UserInfoModel>();
  final referrerIsFul = false.obs;
  final boughtPodiumDefinedEntryTicket = false.obs;
  final referralError = Rxn<String>(null);
  final starsArenaUsersToBuyEntryTicketFrom = Rx<List<StarsArenaUser>>([]);
  final loadingBuyTicketId = ''.obs;
  // used in referral prejoin page, to continue the process
  final temporaryLoginType = ''.obs;
  final temporaryParticleUserInfo = Rxn<ParticleUser.UserInfo>();
  final temporaryUserInfo = Rxn<UserInfoModel>();

  @override
  void onInit() async {
    super.onInit();
    referrerId = Get.parameters[LoginParametersKeys.referrerId] ?? '';
    log.i('deepLinkRoute: $referrerId');
    $isAutoLoggingIn.value = globalController.isAutoLoggingIn.value;
    globalController.isAutoLoggingIn.listen((v) {
      $isAutoLoggingIn.value = v;
    });
  }

  @override
  void onReady() async {
    initialReferral();
    globalController.deepLinkRoute.listen((v) {
      if (v.isNotEmpty) {
        initialReferral();
      }
    });

    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  buyTicket({required StarsArenaUser user}) async {
    if (loadingBuyTicketId.value.isNotEmpty) {
      return;
    }
    loadingBuyTicketId.value = user.id;
    try {
      final bought = await particle_buySharesWithReferrer(
          sharesSubject: user.address, chainId: avalancheChainId);
      if (bought) {
        Toast.success(
          message: 'Ticket bought successfully',
        );
        boughtPodiumDefinedEntryTicket.value = true;
        _continueWithUserToCreate();
      }
    } catch (e) {
      log.e('Error buying ticket: $e');
      Get.closeAllSnackbars();
      Toast.error(
        message: 'Error buying ticket',
      );
    } finally {
      loadingBuyTicketId.value = '';
    }
  }

  initialReferral() async {
    Future.delayed(Duration(seconds: 0), () async {
      final referrerId =
          _extractReferrerId(globalController.deepLinkRoute.value);
      if (referrerId.isNotEmpty) {
        final (referrerUser, allTheReferrals) = await (
          getUsersByIds([referrerId]),
          getAllTheUserReferals(userId: referrerId)
        ).wait;
        if (referrerUser.isNotEmpty) {
          referrer.value = referrerUser.first;
          globalController.deepLinkRoute.value = '';
          if (allTheReferrals.isNotEmpty) {
            final remainingReferrals = allTheReferrals.values
                .where((element) => element.usedBy == '')
                .toList();
            referrerIsFul.value = remainingReferrals.isEmpty;
          }
        }
      }
    });
  }

  String _extractReferrerId(String route) {
    final splited = route.split('referral/');
    if (splited.length < 2) {
      log.f("splited: $splited");
      return '';
    }
    return splited[1];
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
            // Toast.error(
            //   message: 'Already logged in',
            // );
            return;
          }
          particleUser = await ParticleAuthCore.getUserInfo();
          globalController.particleAuthUserInfo.value = particleUser;
        } catch (e) {
          log.e('Error logging in from signUp => particle auth: $e');
          Toast.error(
            message: 'Error logging in',
          );
          return;
        }
        Toast.success(
          message: 'Account created successfully, logging in',
        );
      } else {
        particleUser = await particleLogin(email.value);
        if (particleUser != null) {
          globalController.particleAuthUserInfo.value = particleUser;
        } else {
          Toast.error(
            message: 'Error logging in',
          );
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
          Toast.error(
            message: 'Error logging in',
          );
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
        // Navigate.toInitial();
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
      Toast.error(
        message: errorMessage ?? 'Error logging in',
      );
    } catch (e) {
      log.e('Error signing in: $e');
    } finally {
      isLoggingIn.value = false;
    }
  }

  loginWithEmail({
    required bool ignoreIfNotLoggedIn,
    String? email,
  }) async {
    isLoggingIn.value = true;
    await _checkForLoginType(LoginType.email);
    try {
      final particleUser = await particleSocialLogin(
        type: PLoginInfo.LoginType.email,
        email: email,
      );
      if (particleUser != null) {
        await _socialLogin(
          id: particleUser.uuid,
          name: particleUser.name ?? '',
          email: particleUser.email ?? '',
          avatar: particleUser.avatar ?? avatarPlaceHolder(particleUser.name),
          particleUser: particleUser,
          loginType: LoginType.email,
          loginTypeIdentifier: particleUser.email,
        );
      } else {
        if (ignoreIfNotLoggedIn == false) {
          Toast.error(
            message: 'Error logging in',
          );
        }
        return;
      }
    } catch (e) {
      log.e('Error logging in with Email: $e');
      Toast.error(
        message: 'Error logging in',
      );
      isLoggingIn.value = false;
      return;
    } finally {}
  }

  loginWithX({required bool ignoreIfNotLoggedIn}) async {
    isLoggingIn.value = true;
    await _checkForLoginType(LoginType.x);
    try {
      final particleUser = await particleSocialLogin(
        type: PLoginInfo.LoginType.twitter,
      );
      if (particleUser != null) {
        await _socialLogin(
          id: particleUser.uuid,
          name: particleUser.name!,
          email: particleUser.thirdpartyUserInfo!.userInfo.email ?? '',
          avatar: particleUser.avatar ?? avatarPlaceHolder(particleUser.name),
          particleUser: particleUser,
          loginType: LoginType.x,
          loginTypeIdentifier: particleUser.thirdpartyUserInfo?.userInfo.id,
        );
      } else {
        if (ignoreIfNotLoggedIn == false) {
          Toast.error(
            message: 'Error logging in',
          );
        }
        return;
      }
    } catch (e) {
      log.e('Error logging in with X: $e');
      Toast.error(
        message: 'Error logging in',
      );
      isLoggingIn.value = false;
      return;
    } finally {}
  }

  loginWithGoogle({required bool ignoreIfNotLoggedIn}) async {
    isLoggingIn.value = true;
    await _checkForLoginType(LoginType.google);
    try {
      final particleUser = await particleSocialLogin(
        type: PLoginInfo.LoginType.google,
      );
      if (particleUser != null) {
        await _socialLogin(
          id: particleUser.uuid,
          name: particleUser.name!,
          email: particleUser.googleEmail!,
          avatar: particleUser.avatar ?? avatarPlaceHolder(particleUser.name),
          particleUser: particleUser,
          loginType: LoginType.google,
          loginTypeIdentifier: particleUser.googleEmail,
        );
      } else {
        if (!ignoreIfNotLoggedIn) {
          Toast.error(
            message: 'Error logging in',
          );
        }
        return;
      }
    } catch (e) {
      log.e('Error logging in with Google: $e');
      isLoggingIn.value = false;
      Toast.error(
        message: 'Error logging in',
      );
      return;
    } finally {}
  }

  loginWithLinkedIn({required bool ignoreIfNotLoggedIn}) async {
    isLoggingIn.value = true;
    await _checkForLoginType(LoginType.linkedin);
    try {
      final particleUser = await particleSocialLogin(
        type: PLoginInfo.LoginType.linkedin,
      );
      if (particleUser != null) {
        _socialLogin(
          id: particleUser.uuid,
          name: particleUser.name!,
          email: particleUser.linkedinEmail ?? '',
          avatar: particleUser.thirdpartyUserInfo?.userInfo.picture ??
              particleUser.avatar ??
              avatarPlaceHolder(particleUser.name),
          particleUser: particleUser,
          loginType: LoginType.linkedin,
          loginTypeIdentifier: particleUser.thirdpartyUserInfo?.userInfo.id,
        );
      } else {
        Toast.error(
          message: 'Error logging in',
        );
        return;
      }
    } catch (e) {
      isLoggingIn.value = false;
      log.e('Error logging in with LinkedIn: $e');
      Toast.error(
        message: 'Error logging in',
      );
      return;
    } finally {}
  }

  loginWithFaceBook({required bool ignoreIfNotLoggedIn}) async {
    isLoggingIn.value = true;
    await _checkForLoginType(LoginType.facebook);
    try {
      final particleUser = await particleSocialLogin(
        type: PLoginInfo.LoginType.facebook,
      );
      if (particleUser != null) {
        _socialLogin(
          id: particleUser.uuid,
          name: particleUser.name!,
          email: particleUser.facebookEmail ?? '',
          avatar: particleUser.avatar ?? avatarPlaceHolder(particleUser.name),
          particleUser: particleUser,
          loginType: LoginType.facebook,
          loginTypeIdentifier: particleUser.thirdpartyUserInfo?.userInfo.id,
        );
      } else {
        Toast.error(
          message: 'Error logging in',
        );
        return;
      }
    } catch (e) {
      isLoggingIn.value = false;
      log.e('Error logging in with Facebook: $e');
      Toast.error(
        message: 'Error logging in',
      );
      return;
    } finally {}
  }

  loginWithApple({required bool ignoreIfNotLoggedIn}) async {
    isLoggingIn.value = true;
    await _checkForLoginType(LoginType.apple);
    try {
      final particleUser = await particleSocialLogin(
        type: PLoginInfo.LoginType.apple,
      );
      if (particleUser != null) {
        _socialLogin(
          id: particleUser.uuid,
          name: particleUser.name!,
          email: particleUser.appleEmail ?? '',
          avatar: particleUser.avatar ?? avatarPlaceHolder(particleUser.name),
          particleUser: particleUser,
          loginType: LoginType.apple,
          loginTypeIdentifier: particleUser.thirdpartyUserInfo?.userInfo.id,
        );
      } else {
        Toast.error(
          message: 'Error logging in',
        );
        return;
      }
    } catch (e) {
      isLoggingIn.value = false;
      log.e('Error logging in with Apple: $e');
      Toast.error(
        message: 'Error logging in',
      );
      return;
    } finally {}
  }

  loginWithGithub({required bool ignoreIfNotLoggedIn}) async {
    isLoggingIn.value = true;
    await _checkForLoginType(LoginType.github);
    try {
      final particleUser = await particleSocialLogin(
        type: PLoginInfo.LoginType.github,
      );
      if (particleUser != null) {
        _socialLogin(
          id: particleUser.uuid,
          name: particleUser.name!,
          email: particleUser.githubEmail ?? '',
          avatar: particleUser.avatar ?? avatarPlaceHolder(particleUser.name),
          particleUser: particleUser,
          loginType: LoginType.github,
          loginTypeIdentifier: particleUser.thirdpartyUserInfo?.userInfo.id,
        );
      } else {
        Toast.error(
          message: 'Error logging in',
        );
        return;
      }
    } catch (e) {
      isLoggingIn.value = false;
      log.e('Error logging in with Apple: $e');
      Toast.error(
        message: 'Error logging in',
      );
      return;
    } finally {}
  }

  _checkForLoginType(String loginType) async {
    final savedLoginType = GetStorage().read(StorageKeys.loginType);
    if (savedLoginType != LoginType.github) {
      try {
        await ParticleAuthCore.disconnect();
      } catch (e) {}
      return;
    }
  }

  _socialLogin({
    required String id,
    required String name,
    required String email,
    required String avatar,
    required ParticleUser.UserInfo particleUser,
    required String loginType,
    String? loginTypeIdentifier,
  }) async {
    final userId = id;
    if (email.isEmpty) {
      //this is just a placeholder, we use user id as jitsi email
      email = Uuid().v4().replaceAll('-', '') + '@gmail.com';
    }
    final walletsToSave = particleUser.wallets
        .map((e) =>
            ParticleAuthWallet(address: e.publicAddress, chain: e.chainName))
        .toList()
        .where((element) => element.chain == 'evm_chain')
        .toList();
    final particleWalletInfo = FirebaseParticleAuthUserInfo(
      uuid: userId,
      wallets: walletsToSave,
    );
    // this user will be saved, only if uuid of particle auth is not registered, so empty local wallet address is fine
    final userToCreate = UserInfoModel(
      id: userId,
      fullName: name,
      referrer: referrer.value?.id ?? '',
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
    try {
      await Evm.getAddress();
    } catch (e) {
      Toast.error(
        message: 'Error logging in, please try again, or use another method',
      );
      globalController.setLoggedIn(false);
      return;
    }

    isLoggingIn.value = true;

    temporaryLoginType.value = loginType;
    temporaryParticleUserInfo.value = particleUser;
    temporaryUserInfo.value = userToCreate;

    final canContinueAuthentication =
        await _canContinueAuthentication(userToCreate);
    if (!canContinueAuthentication) {
      final hasTicket = await _checkIfUserHasPodiumDefinedEntryTicket();
      if (!hasTicket) {
        // globalController.setLoggedIn(false);
        Navigate.to(
          route: Routes.PREJOIN_REFERRAL_PAGE,
          type: NavigationTypes.toNamed,
        );
        isLoggingIn.value = false;
        return;
      }
    }
    _continueWithUserToCreate();
  }

  _continueWithUserToCreate() async {
    isLoggingIn.value = true;
    final particleUser = temporaryParticleUserInfo.value;
    final userToCreate = temporaryUserInfo.value!;
    final loginType = temporaryLoginType.value;
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
        isLoggingIn.value = false;
      } finally {}
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
      globalController.particleAuthUserInfo.value = particleUser;
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

  Future<bool> _checkIfUserHasPodiumDefinedEntryTicket() async {
    bool bought = false;
    final listOfBuyableTickets = await getPodiumDefinedEntryAddresses();
    final List<StarsArenaUser> addressesToCheckForArena = [];
    for (var i = 0; i < listOfBuyableTickets.length; i++) {
      final ticket = listOfBuyableTickets[i];
      if (ticket.type == BuyableTicketTypes.onlyArenaTicketHolders) {
        if (ticket.handle != null) {
          final StarsArenaUser? user =
              await HttpApis.getUserFromStarsArenaByHandle(
            ticket.handle!,
          );
          if (user != null) {
            addressesToCheckForArena.add(user);
          }
        }
      }
    }
    starsArenaUsersToBuyEntryTicketFrom.value = addressesToCheckForArena;
    await temporarilyChangeParticleNetwork(avalancheChainId);
    final buyResults = await Future.wait(addressesToCheckForArena.map(
      (user) async {
        return particle_getMyShares_arena(
          sharesSubject: user.address,
          chainId: avalancheChainId,
        );
      },
    ));
    switchBackToSavedParticleNetwork();
    for (var i = 0; i < buyResults.length; i++) {
      final result = buyResults[i];
      if (result != null && result > BigInt.zero) {
        bought = true;
        break;
      }
    }
    boughtPodiumDefinedEntryTicket.value = bought;
    return bought;
  }

  Future<bool> _canContinueAuthentication(UserInfoModel user) async {
    final registeredUser = await getUserById(user.id);
    if (registeredUser != null) {
      final refers = await getAllTheUserReferals(userId: user.id);
      if (refers.isEmpty) {
        await initializeUseReferalCodes(userId: user.id);
      }
      return true;
    }
    if (registeredUser == null && referrer.value != null) {
      if (referrer.value == null) {
        referralError.value = 'Referrer not found';
        return false;
      }
      final allReferreReferrals =
          await getAllTheUserReferals(userId: referrer.value!.id);
      final remainingReferrals = allReferreReferrals.values.where(
        (element) => element.usedBy == '',
      );
      if (remainingReferrals.isEmpty) {
        referralError.value = 'Referrer has no more referral codes';
        return false;
      } else {
        final firstAvailableCode = allReferreReferrals.keys.firstWhere(
            (element) => allReferreReferrals[element]!.usedBy == '');
        final code = await setUsedByToReferral(
          userId: referrer.value!.id,
          referralCode: firstAvailableCode,
          usedById: user.id,
        );
        if (code == null) {
          referralError.value = 'Error setting used by to referral';
          return false;
        } else {
          return true;
        }
      }
    } else {
      referralError.value = 'You need a referrer to use Podium';
      return false;
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
