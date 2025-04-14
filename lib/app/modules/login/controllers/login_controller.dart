import 'dart:async';

import 'package:aptos/aptos_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/aptosClient.dart';
import 'package:podium/app/modules/global/utils/web3AuthProviderToLoginTypeString.dart';
import 'package:podium/app/modules/login/utils/signAndVerify.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/auth/additionalDataForLogin.dart';
import 'package:podium/providers/api/podium/models/auth/loginRequest.dart';
import 'package:podium/providers/api/podium/models/pass/buy_sell_request.dart';
import 'package:podium/providers/api/podium/models/teamMembers/constantMembers.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
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

addressToUuid(String address) {
  final uuid = const Uuid();
  final uid = uuid.v5(Namespace.url.value, address);
  return uid;
}

class LoginController extends GetxController {
  final globalController = Get.find<GlobalController>();
  final storage = GetStorage();
  final isLoggingIn = false.obs;
  final $isAutoLoggingIn = false.obs;
  final email = ''.obs;
  final password = ''.obs;
  final web3AuthLogintype = ''.obs;
  final internalWalletAddress = ''.obs;
  final internalWalletBalance = ''.obs;
  Function? afterLogin = null;

  final isReferrerInputExpanded = false.obs;
  final referrerNotFound = false.obs;

  final textController = TextEditingController();

  toggleExpanded() {
    isReferrerInputExpanded.value = !isReferrerInputExpanded.value;
  }

  handlePaste() async {
    referrerNotFound.value = false;
    referrerIsFul.value = false;
    referrer.value = null;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final text = data!.text!.trim();
      textController.text = text;
      referrerId = text;
      if (temporaryLoginRequest != null) {
        temporaryLoginRequest!.referrer_user_uuid = referrerId;
      }
      initializeReferral(text);
    }
  }

  Future<void> handleConfirm() async {
    referrerNotFound.value = false;
    referrerIsFul.value = false;
    referrer.value = null;
    if (textController.text.isNotEmpty) {
      referrerId = textController.text.trim();
    }
    textController.clear();
    initializeReferral(referrerId);
  }

  String referrerId = '';
  final referrer = Rxn<UserModel>();
  final referrerIsFul = false.obs;
  final boughtPodiumDefinedEntryTicket = false.obs;
  final referralError = Rxn<String>(null);
  final podiumUsersToBuyEntryTicketFrom = Rx<List<UserModel>>([]);

  final loadingBuyTicketId = ''.obs;
  // used in referral prejoin page, to continue the process
  StreamSubscription<bool>? isLoggedInListener;
  StreamSubscription<String>? deeplinkRouteListener;

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
    isLoggedInListener = globalController.isAutoLoggingIn.listen((v) {
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
    isLoggedInListener?.cancel();
    deeplinkRouteListener?.cancel();
    super.onClose();
  }

  Future<void> buyTicket({required UserModel user}) async {
    if (loadingBuyTicketId.value.isNotEmpty) {
      return;
    }
    loadingBuyTicketId.value = user.uuid;
    bool? bought;
    try {
      final (success, hash) =
          await AptosMovement.buyTicketFromTicketSellerOnPodiumPass(
        sellerAddress: user.aptos_address!,
        sellerName: user.name!,
        sellerUuid: user.uuid,
      );
      bought = success;
      if (bought == true) {
        Toast.success(
          message: 'Pass bought successfully',
        );
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
    referrerNotFound.value = false;
    referrerIsFul.value = false;
    referrer.value = null;
    Future.delayed(const Duration(seconds: 0), () async {
      referrerId =
          id ?? _extractReferrerId(globalController.deepLinkRoute.value);
      if (referrerId.isNotEmpty) {
        referrer.value = await HttpApis.podium.getUserData(referrerId);
        storage.write(StorageKeys.referrerId, referrerId);

        if (referrer.value?.remaining_referrals_count == 0) {
          referrerIsFul.value = true;
          Toast.error(message: 'Referrer has reached its limit');
        } else if (referrer.value == null) {
          referrerNotFound.value = true;
          Toast.error(message: 'Referrer not found');
        } else {
          Toast.success(message: 'use ${referrer.value?.name} as referrer');

          if (temporaryLoginRequest != null) {
            isLoggingIn.value = true;
            _continueLogin(
              hasTicket: false,
              forcedReferrerID: referrerId,
            );
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
        storage.remove(StorageKeys.loginType);
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
            storage.remove(StorageKeys.loginType);
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
        storage.remove(StorageKeys.loginType);
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
      // just a placeholder for email
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
      name: name == email ? null : name,
      image: avatar,
      loginType: loginType,
    );
    _continueLogin(hasTicket: hasTicket);
  }

  _continueLogin({
    required bool hasTicket,
    String? forcedReferrerID,
  }) async {
    final storageReferreId = storage.read<String>(StorageKeys.referrerId);
    final request = LoginRequest(
      signature: temporaryLoginRequest!.signature,
      username: temporaryLoginRequest!.username,
      aptos_address: temporaryLoginRequest!.aptos_address,
      has_ticket: hasTicket,
      login_type_identifier: temporaryLoginRequest!.login_type_identifier,
      referrer_user_uuid: forcedReferrerID ??
          storageReferreId ??
          (referrerId.isEmpty ? null : referrerId) ??
          temporaryLoginRequest?.referrer_user_uuid,
    );

    storage.remove(StorageKeys.referrerId);
    l.d('request: ${request.toJson()}');
    final (userLoginResponse, errorMessage) = await HttpApis.podium.login(
      request: request,
      additionalData: temporaryAdditionalData!,
    );

    if (userLoginResponse == null) {
      if (errorMessage == 'referrer has reached its limit') {
        Toast.error(
          message: 'All the referral codes of the referrer have been used',
        );
        removeLogingInState();
      }
      if (errorMessage?.toLowerCase().contains('deactivated') ?? false) {
        Toast.error(
          message: 'Account has been deleted',
        );
        removeLogingInState();
        return;
      }
      if (errorMessage?.toLowerCase().contains('nor bought ticket') ?? false) {
        _redirectToBuyTicketPage();
      } else {
        Toast.error(
          title: 'Error logging in',
          message: errorMessage,
        );
        removeLogingInState();
      }
      return;
    }

    //force to add name if field is empty
    String? savedName = userLoginResponse.name;
    if (userLoginResponse.name == email || userLoginResponse.name == null) {
      savedName = await forceSaveUserFullName();
      if (savedName == null) {
        Toast.error(
          title: 'Error logging in',
          message: 'Name is required',
        );
        await Web3AuthFlutter.logout();
        removeLogingInState();
        return;
      }
    }
    // end force to add name if field is empty

    if (savedName != null) {
      userLoginResponse.name = savedName;
      globalController.myUserInfo.value = userLoginResponse;
      globalController.myUserInfo.refresh();

      LoginTypeService.setLoginType(temporaryAdditionalData?.loginType ?? '');
      globalController.setLoggedIn(true);
      // newx line is commented because loginController is cleared from memory (offAllNamed in global controller)
      // removeLogingInState();
      if (afterLogin != null) {
        afterLogin!();
        afterLogin = null;
      }
      // Navigate.toInitial();
    }
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
      final users = await HttpApis.podium.getUserByAptosAddresses(
        podiumTeamMembersAptosAddresses,
      );
      podiumUsersToBuyEntryTicketFrom.value = users;
      final aptosAddresses = users.map((user) => user.aptos_address!).toList();
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
    await Get.bottomSheet(
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
