import 'dart:convert';

import 'package:aptos/aptos_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/web3AuthClient.dart';
import 'package:podium/app/modules/global/utils/web3AuthProviderToLoginTypeString.dart';
import 'package:podium/app/modules/global/utils/weiToDecimalString.dart';
import 'package:podium/app/modules/login/utils/signAndVerify.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/arena/models/user.dart';
import 'package:podium/providers/api/podium/models/auth/loginRequest.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
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
  final referrer = Rxn<UserModel>();
  final referrerIsFul = false.obs;
  final boughtPodiumDefinedEntryTicket = false.obs;
  final referralError = Rxn<String>(null);
  final starsArenaUsersToBuyEntryTicketFrom = Rx<List<StarsArenaUser>>([]);
  final loadingBuyTicketId = ''.obs;
  // used in referral prejoin page, to continue the process
  final temporaryLoginType = ''.obs;
  final temporaryUserInfo = Rxn<UserModel>();
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

  Future<void> buyTicket({required StarsArenaUser user}) async {
    final externalWalletAddress = globalController.connectedWalletAddress.value;

    if (loadingBuyTicketId.value.isNotEmpty) {
      return;
    }
    loadingBuyTicketId.value = user.id;
    bool bought = false;
    try {
      if (externalWalletAddress.isNotEmpty) {
        final selectedWallet = await choseAWallet(chainId: avalancheChainId);
        if (selectedWallet == null) {
          return;
        } else {
          if (selectedWallet == WalletNames.internal_EVM) {
            bought = await internal_buySharesWithReferrer(
              sharesSubject: user.mainAddress,
              chainId: avalancheChainId,
            );
          } else {
            bought = await ext_buySharesWithReferrer(
              sharesSubject: user.mainAddress,
              chainId: avalancheChainId,
            );
          }
        }
      } else {
        bought = await internal_buySharesWithReferrer(
          sharesSubject: user.mainAddress,
          chainId: avalancheChainId,
        );
      }
      if (bought) {
        Toast.success(
          message: 'Ticket bought successfully',
        );
        boughtPodiumDefinedEntryTicket.value = true;
        _continueWithUserToCreate(
          temporaryUserInfo.value!,
        );
      }
    } catch (e) {
      l.e('Error buying ticket: $e');
      Get.closeAllSnackbars();
      Toast.error(
        message: 'Error buying ticket',
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
        l.f('!!!!!!!!!!!!!!!!!!!!!!!! referrerId: $referrerId');
        // final (referrerUser, allTheReferrals) = await (
        //   HttpApis.podium.getUserData(referrerId),
        //   HttpApis.podium.getAllTheUserReferals(userId: referrerId)
        // ).wait;
        // if (referrerUser.isNotEmpty) {
        //   referrer.value = referrerUser.first;
        //   globalController.deepLinkRoute.value = '';
        //   if (allTheReferrals.isNotEmpty) {
        //     final remainingReferrals = allTheReferrals.values
        //         .where((element) => element.usedBy == '')
        //         .toList();
        //     referrerIsFul.value = remainingReferrals.isEmpty;
        //   }
        // }
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
    // aptos account
    final aptosAccount = AptosAccount.fromPrivateKey(privateKey);
    globalController.aptosAccount = aptosAccount;
    final aptosAddress = aptosAccount.address;
// end aptos account
    final loginType = web3AuthProviderToLoginTypeString(loginMethod);
    internalWalletAddress.value = publicAddress;
    final signature = signMessage(privateKey, publicAddress);
    if (signature == null) {
      l.e('Signature is not valid');
      return;
    }

    final loginResult = await HttpApis.podium.login(
      request: LoginRequest(
        signature: signature,
        username: publicAddress,
      ),
      aptosAddress: aptosAddress,
      email: userInfo.email == null || userInfo.email!.isEmpty
          ? const Uuid().v4().replaceAll('-', '') + '@gmail.com'
          : userInfo.email!,
      name: userInfo.name,
      image: userInfo.profileImage,
      loginType: loginType,
      loginTypeIdentifier: _fixLoginTypeIdentifier(userInfo.verifierId),
      refererUserUuid: referrer.value?.uuid ?? '',
    );
    if (loginResult == null) {
      Toast.error(
        message: 'Login failed',
      );
      removeLogingInState();
      return;
    }

    // this is a bit weird, but we have to reset the value here to false, because it will be used in the next step (_checkIfUserHasPodiumDefinedEntryTicket)
    isBeforeLaunchUser = false;

    temporaryLoginType.value = loginType;
    temporaryUserInfo.value = loginResult;
    bool canContinueAuthentication = false;
    try {
      canContinueAuthentication = await _canContinueAuthentication(loginResult);
    } catch (e) {
      removeLogingInState();
    }
    if (!canContinueAuthentication) {
      final hasTicket =
          true; // await _checkIfUserHasPodiumDefinedEntryTicket();
      if (!hasTicket) {
        try {
          final avalancheClient = evmClientByChainId(avalancheChainId);
          final res =
              await avalancheClient.getBalance(parseAddress(publicAddress));
          final balance = weiToDecimalString(wei: res);
          internalWalletBalance.value = balance;
        } catch (e) {
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
    _continueWithUserToCreate(loginResult);
  }

  String? _fixLoginTypeIdentifier(String? loginTypeIdentifier) {
    if (loginTypeIdentifier == null) return null;

    final providers = [
      LoginType.x,
      'twitter',
      LoginType.github,
      LoginType.google,
      LoginType.email,
      LoginType.apple,
      LoginType.facebook,
      LoginType.linkedin,
    ];

    for (final provider in providers) {
      final delimiter = '$provider|';
      if (loginTypeIdentifier.contains(delimiter)) {
        return loginTypeIdentifier.split(delimiter)[1];
      }
    }

    return loginTypeIdentifier;
  }

  _continueWithUserToCreate(UserModel user) async {
    final userToCreate = temporaryUserInfo.value!;
    final loginType = temporaryLoginType.value;
    late String? savedName;
    if ((user.name ?? '').isEmpty || user.name == user.email) {
      UserModel? myUser = await forceSaveUserFullName(user: user);

      if (myUser == null) {
        Toast.error(
          message: 'Error logging in',
        );
        globalController.setLoggedIn(false);
        isLoggingIn.value = false;
        return;
      }
    } else {
      savedName = user.name;
    }
    if (savedName != null) {
      globalController.currentUserInfo.value = user;
      globalController.currentUserInfo.refresh();

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

  Future<bool> _chackIfUserIsSignedUpBeforeLaunch(UserModel user) async {
    // String identifier = user.login_type_identifier!;
    // final DatabaseReference _database = FirebaseDatabase.instance.ref();
    // final snapshot = await _database.child('users');
    // final usersWithThisIdentifier = await snapshot
    //     .orderByChild(UserInfoModel.loginTypeIdentifierKey)
    //     .equalTo(identifier)
    //     .once();
    // final results = usersWithThisIdentifier.snapshot.value;
    // if (results == null) {
    //   return false;
    // }
    return true;
  }

  Future<bool> _checkIfUserHasPodiumDefinedEntryTicket() async {
    isBeforeLaunchUser = await _chackIfUserIsSignedUpBeforeLaunch(
      temporaryUserInfo.value!,
    );
    if (isBeforeLaunchUser) {
      return true;
    }
    bool bought = false;
    final listOfBuyableTickets = []; //await getPodiumDefinedEntryAddresses();
    final List<StarsArenaUser> addressesToCheckForArena = [];
    final List<Future> arenaCallArray = [];
    for (var i = 0; i < listOfBuyableTickets.length; i++) {
      final ticket = listOfBuyableTickets[i];
      if (ticket.type == BuyableTicketTypes.onlyArenaTicketHolders) {
        if (ticket.handle != null) {
          arenaCallArray.add(HttpApis.arenaApi.getUserFromStarsArenaByHandle(
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

  Future<bool> _canContinueAuthentication(UserModel user) async {
    l.f('!!!!!!!!!!!!!!!!!!!!!!!! user: ${user.uuid}');
    return true;
    // final registeredUser = await HttpApis.podium.getUserData(user.uuid);
    // if (registeredUser == null && referrer.value != null) {
    //   if (referrer.value == null) {
    //     referralError.value = 'Referrer not found';
    //     return false;
    //   }
    // final allReferreReferrals = await HttpApis.podium
    //     .getAllTheUserReferals(userId: referrer.value!.uuid);
    // final remainingReferrals = allReferreReferrals.values.where(
    //   (element) => element.usedBy == '',
    // );
    // if (remainingReferrals.isEmpty) {
    //   referralError.value = 'Referrer has no more referral codes';
    //   return false;
    // } else {
    //   if (referrer.value != null && user.uuid == referrer.value!.uuid) {
    //     return true;
    //   }
    //   final firstAvailableCode = allReferreReferrals.keys.firstWhere(
    //       (element) => allReferreReferrals[element]!.usedBy == '');
    // final code = await setUsedByToReferral(
    //   userId: referrer.value!.uuid,
    //   referralCode: firstAvailableCode,
    //   usedById: user.uuid,
    // );
    // if (code == null) {
    //   referralError.value = 'Error setting used by to referral';
    //   return false;
    // } else {
    //   return true;
    // }
  }
  // } else {
  //   referralError.value = 'You need a referrer to use Podium';
  //   return false;
  // }
}

Future<UserModel?> forceSaveUserFullName({required UserModel user}) async {
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
  final myUser = await HttpApis.podium.updateMyUserData(
    {
      'name': name,
    },
  );

  return myUser;
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
