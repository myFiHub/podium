import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/web3AuthProviderToLoginTypeString.dart';
import 'package:podium/app/modules/web3Auth_redirected/controllers/web3Auth_redirected_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_Internal_wallet.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/models/starsArenaUser.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/loginType.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/utils/styles.dart';

import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';
import 'package:uuid/uuid.dart';
import 'package:web3auth_flutter/enums.dart';
import 'package:web3auth_flutter/input.dart';
import 'package:web3auth_flutter/output.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3dart/web3dart.dart';

class LoginParametersKeys {
  static const referrerId = 'referrerId';
}

class LoginController extends GetxController {
  final globalController = Get.find<GlobalController>();
  final isLoggingIn = false.obs;
  final $isAutoLoggingIn = false.obs;
  final email = ''.obs;
  final password = ''.obs;
  final web3AuthLogintype = ''.obs;
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
  final temporaryUserInfo = Rxn<UserInfoModel>();

  @override
  void onInit() {
    referrerId = Get.parameters[LoginParametersKeys.referrerId] ?? '';
    log.i('deepLinkRoute: $referrerId');

    $isAutoLoggingIn.value = globalController.isAutoLoggingIn.value;
    globalController.isAutoLoggingIn.listen((v) {
      $isAutoLoggingIn.value = v;
    });
    super.onInit();
  }

  @override
  void onReady() {
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
      final bought = await internal_buySharesWithReferrer(
        sharesSubject: user.mainAddress,
        chainId: avalancheChainId,
      );
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

  // _checkForLoginType(String loginType) async {
  //   final savedLoginType = GetStorage().read(StorageKeys.loginType);
  //   if (savedLoginType != LoginType.github) {
  //     try {
  //       await Web3AuthFlutter.logout();
  //     } catch (e) {}
  //     return;
  //   }
  // }

  socialLogin({
    required Provider loginMethod,
    ignoreIfNotLoggedIn = false,
  }) async {
    isLoggingIn.value = true;
    // in case user is backed from referral page(not auto logging in and clickes on a button in login page)
    if (!ignoreIfNotLoggedIn) {
      try {
        await Web3AuthFlutter.logout();
      } catch (e) {}
    }
    // await _checkForLoginType(web3AuthProviderToLoginTypeString(loginMethod));
    try {
      final (userInfo, privateKey) = await (
        Web3AuthFlutter.getUserInfo(),
        Web3AuthFlutter.getPrivKey()
      ).wait;
      _continueSocialLoginWithUserInfoAndPrivateKey(
        privateKey: privateKey,
        userInfo: userInfo,
        loginMethod: loginMethod,
      );
    } catch (e) {
      if (ignoreIfNotLoggedIn) {
        globalController.isAutoLoggingIn.value = false;
        isLoggingIn.value = false;
        return;
      }

      Web3AuthResponse? res;
      try {
        if (loginMethod == Provider.email_passwordless) {
          final String? email = await showDialogToGetTheEmail();
          if (email != null && email.isNotEmpty) {
            res = await Web3AuthFlutter.login(
              LoginParams(
                loginProvider: loginMethod,
                mfaLevel: MFALevel.DEFAULT,
                extraLoginOptions: ExtraLoginOptions(
                  login_hint: email,
                ),
              ),
            );
          } else {
            isLoggingIn.value = false;
            globalController.isAutoLoggingIn.value = false;

            return;
          }
        } else {
          res = await Web3AuthFlutter.login(
            LoginParams(
              loginProvider: loginMethod,
              mfaLevel: MFALevel.DEFAULT,
              // extraLoginOptions: ExtraLoginOptions(
              //   login_hint: "mhsnprvr@gmail.com",
              // ),
            ),
          );
        }
        if (res == null) {
          isLoggingIn.value = false;
          globalController.isAutoLoggingIn.value = false;

          return;
        }
        final privateKey = res.privKey;
        final userInfo = res.userInfo;
        if (privateKey == null || userInfo == null) {
          isLoggingIn.value = false;
          globalController.isAutoLoggingIn.value = false;

          return;
        }
        await _continueSocialLoginWithUserInfoAndPrivateKey(
          privateKey: privateKey,
          userInfo: userInfo,
          loginMethod: loginMethod,
        );
      } catch (e) {
        isLoggingIn.value = false;
        globalController.isAutoLoggingIn.value = false;

        log.e(e);
        Toast.error(
          message: 'Error logging in, please try again, or use another method',
        );
      } finally {
        isLoggingIn.value = false;
        globalController.isAutoLoggingIn.value = false;
      }
    } finally {
      isLoggingIn.value = false;
      globalController.isAutoLoggingIn.value = false;
    }
  }

  _continueSocialLoginWithUserInfoAndPrivateKey(
      {required String privateKey,
      required TorusUserInfo userInfo,
      required Provider loginMethod}) async {
    final ethereumKeyPair = EthPrivateKey.fromHex(privateKey);
    final publicAddress = ethereumKeyPair.address.hex;
    final uid = addressToUuid(publicAddress);
    final loginType = web3AuthProviderToLoginTypeString(loginMethod);

    await _socialLogin(
      id: uid,
      name: userInfo.name ?? '',
      email: userInfo.email ?? '',
      avatar: userInfo.profileImage ?? '',
      internalWalletAddress: publicAddress,
      loginType: loginType,
      loginTypeIdentifier: userInfo.verifierId,
    );
  }

  _socialLogin({
    required String id,
    required String name,
    required String email,
    required String avatar,
    required String internalWalletAddress,
    required String loginType,
    String? loginTypeIdentifier,
  }) async {
    final userId = id;
    if (email.isEmpty) {
      //since email will be used in jitsi meet, we have to save something TODO: save user id in jitsi
      email = Uuid().v4().replaceAll('-', '') + '@gmail.com';
    }

    // this user will be saved, only if uuid of internal wallet is not registered, so empty local wallet address is fine
    final userToCreate = UserInfoModel(
      id: userId,
      fullName: name,
      email: email,
      avatar: avatar,
      localWalletAddress: '',
      savedInternalWalletAddress: internalWalletAddress,
      following: [],
      numberOfFollowers: 0,
      referrer: referrer.value?.id ?? '',
      loginType: loginType,
      loginTypeIdentifier: loginTypeIdentifier,
      lowercasename: name.toLowerCase(),
    );

    temporaryLoginType.value = loginType;
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
    if (user.fullName.isEmpty || user.fullName == user.email) {
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
      globalController.currentUserInfo.refresh();
      await _initializeReferrals(userToCreate);
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
    final List<Future> arenaCallArray = [];
    for (var i = 0; i < listOfBuyableTickets.length; i++) {
      final ticket = listOfBuyableTickets[i];
      if (ticket.type == BuyableTicketTypes.onlyArenaTicketHolders) {
        if (ticket.handle != null) {
          arenaCallArray.add(HttpApis.getUserFromStarsArenaByHandle(
            ticket.handle!,
          ));
        }
      }
    }
    final arenaUsers = await Future.wait(arenaCallArray);
    for (var i = 0; i < arenaUsers.length; i++) {
      final user = arenaUsers[i];
      if (user != null) {
        addressesToCheckForArena.add(user);
      }
    }
    // update the price for each user
    final List<Future> SCcallArray = [];
    for (var i = 0; i < addressesToCheckForArena.length; i++) {
      final user = addressesToCheckForArena[i];
      SCcallArray.add(getBuyPriceForArenaTicket(
        sharesSubject: user.mainAddress,
        chainId: avalancheChainId,
      ));
    }
    final prices = await Future.wait(SCcallArray);
    for (var i = 0; i < addressesToCheckForArena.length; i++) {
      final user = addressesToCheckForArena[i];
      final price = prices[i].toString();
      user.lastKeyPrice = price;
      user.keyPrice = price;
    }

    starsArenaUsersToBuyEntryTicketFrom.value = addressesToCheckForArena;
    final buyResults = await Future.wait(addressesToCheckForArena.map(
      (user) async {
        return getMyShares_arena(
          sharesSubject: user.mainAddress,
          chainId: avalancheChainId,
        );
      },
    ));
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

  _initializeReferrals(UserInfoModel user) async {
    final refers = await getAllTheUserReferals(userId: user.id);
    if (refers.isEmpty) {
      await initializeUseReferalCodes(userId: user.id);
    }
    return true;
  }

  Future<bool> _canContinueAuthentication(UserInfoModel user) async {
    final registeredUser = await getUserById(user.id);
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

Future<String?> showDialogToGetTheEmail() async {
  final _formKey = GlobalKey<FormBuilderState>();
  String email = '';
  final String? enteredEmail = await Get.bottomSheet(
    Container(
      height: 400,
      color: ColorName.cardBackground,
      child: FormBuilder(
        key: _formKey,
        child: Column(
          children: [
            space10,
            Text(
              'Please enter your email address',
              style: TextStyle(
                color: ColorName.greyText,
              ),
            ),
            FormBuilderField(
              name: 'email',
              builder: (FormFieldState<String?> field) {
                return Input(
                  hintText: 'Email',
                  onChanged: (value) => email = value,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: 'Email is required'),
                    FormBuilderValidators.email(errorText: 'Invalid email'),
                  ]),
                );
              },
            ),
            Button(
              text: 'SUBMIT',
              blockButton: true,
              type: ButtonType.gradient,
              onPressed: () {
                final re = _formKey.currentState?.saveAndValidate();
                if (re == true) {
                  Navigator.pop(Get.context!, email);
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
  return (enteredEmail ?? "").trim();
}
