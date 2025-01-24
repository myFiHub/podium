import 'package:aptos/aptos_account.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/aptosClient.dart';
import 'package:podium/app/modules/global/utils/web3AuthClient.dart';
import 'package:podium/app/modules/global/utils/web3AuthProviderToLoginTypeString.dart';
import 'package:podium/app/modules/global/utils/weiToDecimalString.dart';
import 'package:podium/app/modules/login/utils/signAndVerify.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/arena/models/user.dart';
import 'package:podium/providers/api/podium/models/teamMembers/constantMembers.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/loginType.dart';
import 'package:podium/utils/navigation/navigation.dart';
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

addressToUuid(String address) {
  final uuid = const Uuid();
  final uid = uuid.v5(Namespace.url.value, address);
  return uid;
}

class LoginController extends GetxController {
  final globalController = Get.find<GlobalController>();
  final isLoggingIn = false.obs;
  final $isAutoLoggingIn = false.obs;
  final email = ''.obs;
  final password = ''.obs;
  final web3AuthLogintype = ''.obs;
  final internalWalletAddress = ''.obs;
  final internalWalletBalance = ''.obs;
  Function? afterLogin = null;

  String referrerId = '';
  final referrer = Rxn<UserInfoModel>();
  final referrerIsFul = false.obs;
  final boughtPodiumDefinedEntryTicket = false.obs;
  final referralError = Rxn<String>(null);
  final podiumUsersToBuyEntryTicketFrom = Rx<List<UserInfoModel>>([]);
  final loadingBuyTicketId = ''.obs;
  // used in referral prejoin page, to continue the process
  final temporaryLoginType = ''.obs;
  final temporaryUserInfo = Rxn<UserInfoModel>();
  bool isBeforeLaunchUser = false;

  @override
  void onInit() {
    super.onInit();
    referrerId = Get.parameters[LoginParametersKeys.referrerId] ?? '';
    l.i('deepLinkRoute: $referrerId');
    if (referrerId.isNotEmpty) {
      initialReferral(referrerId);
    }
    $isAutoLoggingIn.value = globalController.isAutoLoggingIn.value;
    globalController.isAutoLoggingIn.listen((v) {
      $isAutoLoggingIn.value = v;
    });
  }

  @override
  void onReady() {
    globalController.deepLinkRoute.listen((v) {
      if (v.isNotEmpty) {
        initialReferral(null);
      }
    });
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> buyTicket({required UserInfoModel user}) async {
    if (loadingBuyTicketId.value.isNotEmpty) {
      return;
    }
    loadingBuyTicketId.value = user.id;
    bool? bought;
    try {
      bought = await AptosMovement.buyTicketFromTicketSellerOnPodiumPass(
        sellerAddress: user.aptosInternalWalletAddress,
        sellerName: user.fullName,
      );
      if (bought != null && bought) {
        Toast.success(
          message: 'Pass bought successfully',
        );
        boughtPodiumDefinedEntryTicket.value = true;
        _continueWithUserToCreate();
      }
    } catch (e) {
      l.e('Error buying Pass: $e');
      Get.closeAllSnackbars();
      Toast.error(
        message: 'Error buying Pass',
      );
    } finally {
      loadingBuyTicketId.value = '';
    }
  }

  Future<void> initialReferral(String? id) async {
    Future.delayed(const Duration(seconds: 0), () async {
      final referrerId =
          id ?? _extractReferrerId(globalController.deepLinkRoute.value);
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
      l.f("splited: $splited");
      return '';
    }
    return splited[1];
  }

  void removeLogingInState() {
    isLoggingIn.value = false;
    globalController.isAutoLoggingIn.value = false;
  }

  Future<void> socialLogin({
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
        removeLogingInState();
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
            removeLogingInState();
            return;
          }
        } else {
          try {
            res = await Web3AuthFlutter.login(
              LoginParams(
                loginProvider: loginMethod,
                mfaLevel: MFALevel.DEFAULT,
              ),
            );
          } on UserCancelledException catch (e) {
            l.e(e);
            removeLogingInState();
          } catch (e) {
            l.e(e);
            Toast.error(
              message:
                  'Error logging in, please try again, or use another method',
            );
            removeLogingInState();
          }
        }
        if (res == null) {
          removeLogingInState();
          return;
        }
        final privateKey = res.privKey!;
        final userInfo = res.userInfo!;

        await _continueSocialLoginWithUserInfoAndPrivateKey(
          privateKey: privateKey,
          userInfo: userInfo,
          loginMethod: loginMethod,
        );
      } catch (e) {
        removeLogingInState();
        l.e(e);
        Toast.error(
          message: 'Error logging in, please try again, or use another method',
        );
      }
    }
  }

  Future<void> _continueSocialLoginWithUserInfoAndPrivateKey(
      {required String privateKey,
      required TorusUserInfo userInfo,
      required Provider loginMethod}) async {
    final ethereumKeyPair = EthPrivateKey.fromHex(privateKey);
    final publicAddress = ethereumKeyPair.address.hex;
    final signature = signMessage(privateKey, publicAddress);
    if (signature == null) {
      l.e('Signature is not valid');
      return;
    }

    final uid = addressToUuid(publicAddress);
// aptos account
    final aptosAccount = AptosAccount.fromPrivateKey(privateKey);
    globalController.aptosAccount = aptosAccount;
    final aptosAddress = aptosAccount.address;
// end aptos account
    final loginType = web3AuthProviderToLoginTypeString(loginMethod);
    internalWalletAddress.value = aptosAddress;

    // final loginRes = await HttpApis.podium.login(
    //   request: LoginRequest(signature: signature, username: publicAddress),
    //   aptosAddress: aptosAddress,
    //   email: userInfo.email,
    //   name: userInfo.name,
    //   image: userInfo.profileImage,
    // );
    // if (loginRes == null) {
    //   Toast.error(
    //     message: 'Login failed',
    //   );
    // }

    await _socialLogin(
      id: uid,
      name: userInfo.name ?? '',
      email: userInfo.email ?? '',
      avatar: userInfo.profileImage ?? '',
      internalEvmWalletAddress: publicAddress,
      internalAptosWalletAddress: aptosAddress,
      loginType: loginType,
      loginTypeIdentifier: userInfo.verifierId,
    );
  }

  UserInfoModel _fixUserData(UserInfoModel user) {
    UserInfoModel userToCreate = user;
    if (userToCreate.loginTypeIdentifier != null &&
        userToCreate.loginTypeIdentifier!.contains('twitter|')) {
      userToCreate.loginTypeIdentifier =
          userToCreate.loginTypeIdentifier!.split('twitter|')[1];
    }
    if (userToCreate.loginTypeIdentifier != null &&
        userToCreate.loginTypeIdentifier!.contains('github|')) {
      userToCreate.loginTypeIdentifier =
          userToCreate.loginTypeIdentifier!.split('github|')[1];
    }
    if (userToCreate.loginTypeIdentifier != null &&
        userToCreate.loginTypeIdentifier!.contains('google|')) {
      userToCreate.loginTypeIdentifier =
          userToCreate.loginTypeIdentifier!.split('google|')[1];
    }
    if (userToCreate.loginTypeIdentifier != null &&
        userToCreate.loginTypeIdentifier!.contains('email|')) {
      userToCreate.loginTypeIdentifier =
          userToCreate.loginTypeIdentifier!.split('email|')[1];
    }
    if (userToCreate.loginTypeIdentifier != null &&
        userToCreate.loginTypeIdentifier!.contains('apple|')) {
      userToCreate.loginTypeIdentifier =
          userToCreate.loginTypeIdentifier!.split('apple|')[1];
    }
    if (userToCreate.loginTypeIdentifier != null &&
        userToCreate.loginTypeIdentifier!.contains('facebook|')) {
      userToCreate.loginTypeIdentifier =
          userToCreate.loginTypeIdentifier!.split('facebook|')[1];
    }
    if (userToCreate.loginTypeIdentifier != null &&
        userToCreate.loginTypeIdentifier!.contains('linkedin|')) {
      userToCreate.loginTypeIdentifier =
          userToCreate.loginTypeIdentifier!.split('linkedin|')[1];
    }
    return userToCreate;
  }

  Future<void> _socialLogin({
    required String id,
    required String name,
    required String email,
    required String avatar,
    required String internalEvmWalletAddress,
    required String internalAptosWalletAddress,
    required String loginType,
    String? loginTypeIdentifier,
  }) async {
    final userId = id;
    if (email.isEmpty) {
      //since email will be used in jitsi meet, we have to save something TODO: save user id in jitsi
      email = const Uuid().v4().replaceAll('-', '') + '@gmail.com';
    }
    // this is a bit weird, but we have to reset the value here to false, because it will be used in the next step (_checkIfUserHasPodiumDefinedEntryTicket)
    isBeforeLaunchUser = false;
    // this user will be saved, only if uuid of internal wallet is not registered, so empty local wallet address is fine
    UserInfoModel userData = UserInfoModel(
      id: userId,
      fullName: name,
      email: email,
      avatar: avatar,
      evm_externalWalletAddress: '',
      evmInternalWalletAddress: internalEvmWalletAddress,
      aptosInternalWalletAddress: internalAptosWalletAddress,
      following: [],
      numberOfFollowers: 0,
      referrer: referrer.value?.id ?? '',
      loginType: loginType,
      loginTypeIdentifier: loginTypeIdentifier,
      lowercasename: name.toLowerCase(),
    );
    final UserInfoModel userToCreate = _fixUserData(userData);

    temporaryLoginType.value = loginType;
    temporaryUserInfo.value = userToCreate;
    bool canContinueAuthentication = false;
    try {
      final firebasRefForRefferrals = FirebaseDatabase.instance.ref(
        FireBaseConstants.referralsEnabled,
      );
      final isEnabled = await firebasRefForRefferrals.get();
      if (isEnabled.value == true) {
        canContinueAuthentication =
            await _canContinueAuthentication(userToCreate);
      } else {
        canContinueAuthentication = true;
      }
    } catch (e) {
      removeLogingInState();
    }
    if (!canContinueAuthentication) {
      final hasTicket = await _checkIfUserHasPodiumDefinedEntryTicket(
        myAptosAddress: internalAptosWalletAddress,
      );
      if (!hasTicket) {
        try {} catch (e) {
          removeLogingInState();
        }
        Navigate.to(
          route: Routes.PREJOIN_REFERRAL_PAGE,
          type: NavigationTypes.toNamed,
        );
        removeLogingInState();
        return;
      }
    }
    _continueWithUserToCreate();
  }

  getBalance() async {
    final balance = await AptosMovement.balance;
    internalWalletBalance.value = bigIntCoinToMoveOnAptos(balance).toString();
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
      await _initializeReferrals(
        user: userToCreate,
      );
      LoginTypeService.setLoginType(loginType);
      globalController.setLoggedIn(true);
      // newx line is commented because loginController is cleared from memory (offAllNamed in global controller)
      // removeLogingInState();
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

  Future<bool> _chackIfUserIsSignedUpBeforeLaunch(UserInfoModel user) async {
    String identifier = user.loginTypeIdentifier!;
    final DatabaseReference _database = FirebaseDatabase.instance.ref();
    final snapshot = await _database.child('users');
    final usersWithThisIdentifier = await snapshot
        .orderByChild(UserInfoModel.loginTypeIdentifierKey)
        .equalTo(identifier)
        .once();
    final results = usersWithThisIdentifier.snapshot.value;
    if (results == null) {
      return false;
    }
    return true;
  }

  Future<bool> _checkIfUserHasPodiumDefinedEntryTicket({
    required String myAptosAddress,
  }) async {
    isBeforeLaunchUser = await _chackIfUserIsSignedUpBeforeLaunch(
      temporaryUserInfo.value!,
    );
    if (isBeforeLaunchUser) {
      return true;
    }
    try {
      final users = await getUsersByIds(podiumTeamMembers);
      podiumUsersToBuyEntryTicketFrom.value = users;

      final aptosAddresses =
          users.map((user) => user.aptosInternalWalletAddress).toList();
      final callArray = aptosAddresses.map(
        (address) => AptosMovement.getMyBalanceOnPodiumPass(
          sellerAddress: address,
          myAddress: myAptosAddress,
        ),
      );
      final balances = await Future.wait(callArray);
      final hasTicket =
          balances.any((balance) => balance != null && balance > BigInt.zero);
      return hasTicket;
    } catch (e) {
      l.e(e);
      return false;
    }
  }

  Future<bool> _initializeReferrals({
    required UserInfoModel user,
  }) async {
    if (referrer.value != null && user.id == referrer.value!.id) {
      return true;
    }
    final refers = await getAllTheUserReferals(userId: user.id);
    if (refers.isEmpty) {
      await initializeUseReferalCodes(
        userId: user.id,
        isBeforeLaunchUser: isBeforeLaunchUser,
      );
    }
    return true;
  }

  Future<bool> _canContinueAuthentication(UserInfoModel user) async {
    final registeredUser = await getUserById(user.id);
    if (registeredUser != null) {
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
        Toast.error(
          message: 'Referrer has no more referral codes',
        );
        return false;
      } else {
        if (referrer.value != null && user.id == referrer.value!.id) {
          return true;
        }
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
        padding: const EdgeInsets.all(12),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              const Text(
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
            const Text(
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
