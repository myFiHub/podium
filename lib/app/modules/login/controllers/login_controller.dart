import 'package:ably_flutter/ably_flutter.dart';
import 'package:aptos/aptos_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/aptosClient.dart';
import 'package:podium/app/modules/global/utils/web3AuthProviderToLoginTypeString.dart';
import 'package:podium/app/modules/login/utils/signAndVerify.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/auth/additionalDataForLogin.dart';
import 'package:podium/providers/api/podium/models/auth/loginRequest.dart';
import 'package:podium/providers/api/podium/models/teamMembers/constantMembers.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
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
  final referrer = Rxn<UserModel>();
  final referrerIsFul = false.obs;
  final boughtPodiumDefinedEntryTicket = false.obs;
  final referralError = Rxn<String>(null);
  final podiumUsersToBuyEntryTicketFrom = Rx<List<UserInfoModel>>([]);

  final loadingBuyTicketId = ''.obs;
  // used in referral prejoin page, to continue the process

  LoginRequest? temporaryLoginRequest = null;
  AdditionalDataForLogin? temporaryAdditionalData = null;

  bool isBeforeLaunchUser = false;

  @override
  void onInit() {
    super.onInit();
    referrerId = Get.parameters[LoginParametersKeys.referrerId] ?? '';
    l.i('deepLinkRoute: $referrerId');
    if (referrerId.isNotEmpty) {
      initializeReferral(referrerId);
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
        initializeReferral(null);
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
          message: 'Pass bought successfully, log in again',
        );
        boughtPodiumDefinedEntryTicket.value = true;
        _continueLogin(hasTicket: true);
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

  Future<void> initializeReferral(String? id) async {
    Future.delayed(const Duration(seconds: 0), () async {
      referrerId =
          id ?? _extractReferrerId(globalController.deepLinkRoute.value);
      if (referrerId.isNotEmpty) {
        referrer.value = await HttpApis.podium.getUserData(referrerId);
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

  Future<void> _continueSocialLoginWithUserInfoAndPrivateKey({
    required String privateKey,
    required TorusUserInfo userInfo,
    required Provider loginMethod,
  }) async {
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

    await _socialLogin(
      id: uid,
      name: userInfo.name ?? '',
      email: userInfo.email ?? '',
      avatar: userInfo.profileImage ?? '',
      internalEvmWalletAddress: publicAddress,
      internalAptosWalletAddress: aptosAddress,
      loginType: loginType,
      loginTypeIdentifier: userInfo.verifierId,
      privateKey: privateKey,
    );
  }

  String _fixLoginTypeIdentifier(String? loginTypeIdentifier) {
    if (loginTypeIdentifier == null) {
      return '';
    }

    final providers = [
      'x',
      'twitter',
      'github',
      'google',
      'email',
      'apple',
      'facebook',
      'linkedin'
    ];

    for (final provider in providers) {
      final delimiter = '$provider|';
      if (loginTypeIdentifier.contains(delimiter)) {
        return loginTypeIdentifier.split(delimiter)[1];
      }
    }

    return loginTypeIdentifier;
  }

  Future<void> _socialLogin({
    required String id,
    required String name,
    required String email,
    required String avatar,
    required String internalEvmWalletAddress,
    required String internalAptosWalletAddress,
    required String loginType,
    required String privateKey,
    String? loginTypeIdentifier,
  }) async {
    if (email.isEmpty) {
      //since email will be used in jitsi meet, we have to save something TODO: save user id in jitsi
      email = const Uuid().v4().replaceAll('-', '') + '@gmail.com';
    }
    // this is a bit weird, but we have to reset the value here to false, because it will be used in the next step (_checkIfUserHasPodiumDefinedEntryTicket)
    isBeforeLaunchUser = false;
    // this user will be saved, only if uuid of internal wallet is not registered, so empty local wallet address is fine
    final signature = signMessage(privateKey, internalEvmWalletAddress);
    if (signature == null) {
      l.e('Signature is not valid');
      Toast.error(
        message: 'Error logging in',
      );
      return;
    }

    final hasTicket = await _checkIfUserHasPodiumDefinedEntryTicket(
      myAptosAddress: internalAptosWalletAddress,
    );

    temporaryLoginRequest = LoginRequest(
      signature: signature,
      username: internalEvmWalletAddress,
      aptos_address: internalAptosWalletAddress,
      has_ticket: hasTicket,
      login_type_identifier: _fixLoginTypeIdentifier(loginTypeIdentifier),
      referrer_user_uuid: referrer.value?.uuid,
    );
    temporaryAdditionalData = AdditionalDataForLogin(
      email: email,
      name: name,
      image: avatar,
      loginType: loginType,
    );
    _continueLogin(hasTicket: hasTicket);
  }

  _continueLogin({
    required bool hasTicket,
  }) async {
    final (userLoginResponse, errorMessage) = await HttpApis.podium.login(
      request: LoginRequest(
        signature: temporaryLoginRequest!.signature,
        username: temporaryLoginRequest!.username,
        aptos_address: temporaryLoginRequest!.aptos_address,
        has_ticket: hasTicket,
        login_type_identifier: temporaryLoginRequest!.login_type_identifier,
        referrer_user_uuid: temporaryLoginRequest!.referrer_user_uuid,
      ),
      additionalData: temporaryAdditionalData!,
    );

    if (userLoginResponse == null) {
      if (errorMessage == 'referrer has reached its limit') {
        Toast.error(
          message: errorMessage,
        );
      }
      _redirectToBuyTicketPage();
      return;
    }

    //force to add name if field is empty
    String? savedName;
    if (temporaryAdditionalData != null ||
        temporaryAdditionalData!.name == email) {
      savedName = await forceSaveUserFullName();
      if (savedName == null) {
        Toast.error(
          title: 'Error logging in',
          message: 'Name is required',
        );
        await Web3AuthFlutter.logout();
        return;
      }
    } else {
      savedName = userLoginResponse.name;
    }
    // end force to add name if field is empty
  }

  _redirectToBuyTicketPage() async {
    try {
      await getBalance();
    } catch (e) {
      removeLogingInState();
    }
    Navigate.to(
      route: Routes.PREJOIN_REFERRAL_PAGE,
      type: NavigationTypes.toNamed,
    );
    removeLogingInState();
  }

  getBalance() async {
    final balance = await AptosMovement.balance;
    internalWalletBalance.value = bigIntCoinToMoveOnAptos(balance).toString();
  }

  Future<bool> _checkIfUserHasPodiumDefinedEntryTicket({
    required String myAptosAddress,
  }) async {
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

  Future<String?> forceSaveUserFullName() async {
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
    final user = await HttpApis.podium.updateMyUserData(
      {
        'name': fullName,
      },
    );
    if (user == null) {
      Toast.error(
        message: 'Error saving name',
      );
      return null;
    }
    return fullName;
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
