import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/allSetteled.dart';
import 'package:podium/app/modules/global/utils/aptosClient.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getWeb3AuthWalletAddress.dart';
import 'package:podium/app/modules/global/utils/web3AuthClient.dart';
import 'package:podium/app/modules/global/utils/weiToDecimalString.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3auth_flutter/enums.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';

class Payments {
  int numberOfCheersReceived = 0;
  int numberOfBoosReceived = 0;
  int numberOfCheersSent = 0;
  int numberOfBoosSent = 0;
  Map<String, double> income = {};
  Payments(
      {this.numberOfCheersReceived = 0,
      this.numberOfBoosReceived = 0,
      this.numberOfCheersSent = 0,
      this.numberOfBoosSent = 0,
      required this.income});
}

class Balances {
  String Base = '0.0';
  String Avalanche = '0.0';
  String movementAptos = '0.0';

  Balances({
    required this.Base,
    required this.Avalanche,
    required this.movementAptos,
  });
}

class MyProfileController extends GetxController {
  final _authRepository = Get.find<AuthRepository>();
  final _userRepository = Get.find<UserRepository>();
  BuildContext? contextForIntro;
  late TutorialCoachMark tutorialCoachMark;
  final GlobalKey referalSystemKey = GlobalKey();
  final GlobalKey internalWalletKey = GlobalKey();
  final GlobalKey walletConnectKey = GlobalKey();
  final GlobalKey statisticsKey = GlobalKey();
  final ScrollController scrollController = ScrollController();

  final storage = GetStorage();
  final globalController = Get.find<GlobalController>();
  final isInternalWalletActivatedOnFriendTech = false.obs;
  final isExternalWalletActivatedOnFriendTech = false.obs;
  final loadingInternalWalletActivation = false.obs;
  final loadingExternalWalletActivation = false.obs;
  final isGettingPayments = false.obs;
  final isGettingBalances = false.obs;
  final isDeactivatingAccount = false.obs;

  final addressThatIsBeningMadePrimary = Rxn<String>();

  final balances = Rx(
    Balances(
      Base: '0.0',
      Avalanche: '0.0',
      movementAptos: '0.0',
    ),
  );

  final payments = Rx(
    Payments(
      income: {},
    ),
  );

  StreamSubscription<String>? externalWalletAddressListener;

  @override
  void onInit() {
    super.onInit();
    externalWalletAddressListener =
        globalController.externalWalletChainId.listen((address) {
      if (address.isNotEmpty && externalWalletChianId == baseChainId) {
        checkExternalWalletActivation();
      }
    });
    getMyProfile();
    getBalances();
  }

  @override
  void onReady() async {
    super.onReady();
    final alreadyViewed = storage.read(IntroStorageKeys.viewedMyProfile);
    if (
        //
        // true
        alreadyViewed == null
        //
        ) {
      // wait for the context to be ready
      await Future.delayed(const Duration(seconds: 0));
      tutorialCoachMark = TutorialCoachMark(
        targets: _createTargets(),
        skipWidget: Button(
          size: ButtonSize.SMALL,
          type: ButtonType.outline,
          color: ColorName.danger,
          onPressed: () {
            introFinished(true);
          },
          child: const Text("Finish"),
        ),
        paddingFocus: 5,
        opacityShadow: 0.5,
        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        onFinish: () {
          saveIntroAsDone(true);
        },
        onClickTarget: (target) {
          l.d(target);
          _scrollIfNeeded();
        },
        onClickTargetWithTapPosition: (target, tapDetails) {
          l.d("target: $target");
          l.d("clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
        },
        onClickOverlay: (target) {
          l.d('onClickOverlay: $target');
          _scrollIfNeeded();
        },
        onSkip: () {
          saveIntroAsDone(true);
          return true;
        },
      );
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        tutorialCoachMark.show(context: contextForIntro!);
      } catch (e) {
        l.e(e);
      }
    }
  }

  int _currentStep = 0;
  Future<void> _scrollIfNeeded() async {
    _currentStep++;
    if (_currentStep == 1) {
      await scrollController.animateTo(
        200,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == 2) {
      await scrollController.animateTo(
        400,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == 3) {
      await scrollController.animateTo(
        500,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
    }
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];
    targets.add(
      _createStep(
        targetId: referalSystemKey,
        text: "you can share your referal link to your friends",
      ),
    );
    targets.add(
      _createStep(
        targetId: internalWalletKey,
        text: "here is your Podium wallet and assets balances",
      ),
    );

    targets.add(
      _createStep(
        targetId: walletConnectKey,
        text:
            "you can connect an External wallet like Metamask to your account, if connected, it will be used as default for your earnings",
      ),
    );
    targets.add(
      _createStep(
        targetId: statisticsKey,
        text: "this part shows your earnings in different chains ",
        hasNext: false,
      ),
    );

    return targets;
  }

  @override
  void onClose() {
    externalWalletAddressListener?.cancel();
    super.onClose();
  }

  Future<void> getMyProfile() async {
    final profile = await _userRepository.getMyUserData();
    if (profile == null) {
      return;
    }
    payments.value = Payments(
      income: profile.incomes ?? {},
      numberOfCheersReceived: profile.received_cheer_count,
      numberOfBoosReceived: profile.received_boo_count,
      numberOfCheersSent: profile.sent_cheer_count,
      numberOfBoosSent: profile.sent_boo_count,
    );
  }

  TargetFocus _createStep({
    required GlobalKey targetId,
    required String text,
    bool hasNext = true,
  }) {
    return TargetFocus(
      identify: targetId.toString(),
      keyTarget: targetId,
      alignSkip: Alignment.bottomRight,
      paddingFocus: 0,
      focusAnimationDuration: const Duration(milliseconds: 300),
      unFocusAnimationDuration: const Duration(milliseconds: 100),
      shape: ShapeLightFocus.RRect,
      color: Colors.black,
      enableOverlayTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  text,
                  style: TextStyle(
                    color: ColorName.white,
                  ),
                ),
                if (hasNext)
                  Button(
                    size: ButtonSize.SMALL,
                    type: ButtonType.outline,
                    color: ColorName.white,
                    onPressed: () async {
                      await _scrollIfNeeded();
                      tutorialCoachMark.next();
                    },
                    child: Text(
                      "Next",
                      style: TextStyle(color: ColorName.white),
                    ),
                  )
                else
                  Button(
                    size: ButtonSize.SMALL,
                    type: ButtonType.outline,
                    color: ColorName.white,
                    onPressed: () {
                      introFinished(true);
                    },
                    child: Text(
                      "Finish",
                      style: TextStyle(color: ColorName.white),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void saveIntroAsDone(bool? setAsFinished) {
    if (setAsFinished == true) {
      storage.write(IntroStorageKeys.viewedMyProfile, true);
    }
  }

  void introFinished(bool? setAsFinished) {
    saveIntroAsDone(setAsFinished);
    try {
      saveIntroAsDone(true);
      tutorialCoachMark.finish();
    } catch (e) {
      l.e(e);
    }
  }

  Future<void> getBalances() async {
    try {
      isGettingBalances.value = true;
      final baseClient = evmClientByChainId(baseChainId);
      final avalancheClient = evmClientByChainId(avalancheChainId);
      final myaddress = await web3AuthWalletAddress();
      final callMap = {
        'base': baseClient.getBalance(parseAddress(myaddress!)),
        'avalanche': avalancheClient.getBalance(parseAddress(myaddress)),
        'movementAptos': AptosMovement.balance,
      };
      final results = await allSettled(callMap, onProgress: (key, status) {
        l.d('Balance fetch for $key: ${status.name}');
      });

      final baseBalance =
          results['base']?.valueOr(EtherAmount.zero()) ?? EtherAmount.zero();
      final avalancheBalance =
          results['avalanche']?.valueOr(EtherAmount.zero()) ??
              EtherAmount.zero();
      final movementAptosBalance =
          results['movementAptos']?.valueOr(BigInt.zero) ?? BigInt.zero;

      // Log any errors for debugging
      results['movementAptos']?.ifRejected((reason) {
        if (reason is DioException) {
          l.e(reason.response?.data);
        }
      });

      // Log summary of results
      if (results.hasRejected) {
        l.w('Some balance fetches failed: ${results.rejectedCount}/${results.length} failed');
      }

      balances.value = Balances(
        Base: weiToDecimalString(wei: baseBalance),
        Avalanche: weiToDecimalString(wei: avalancheBalance),
        movementAptos: bigIntCoinToMoveOnAptos(movementAptosBalance).toString(),
      );
      isGettingBalances.value = false;
    } catch (e) {
      l.e(e);
      isGettingBalances.value = false;
    }
  }

  Future<bool> checkInternalWalletActivation({bool? silent}) async {
    if (silent != true) {
      loadingInternalWalletActivation.value = true;
    }
    final internalWalletAddress =
        await web3AuthWalletAddress(); // await Evm.getAddress();
    if (internalWalletAddress == null) {
      return false;
    }
    final activeWallets = await internal_friendTech_getActiveUserWallets(
      internalWalletAddress: internalWalletAddress,
      chainId: baseChainId,
    );

    final isActivated = activeWallets.isInternalWalletActive;
    isInternalWalletActivatedOnFriendTech.value = isActivated;

    if (silent != true) {
      loadingInternalWalletActivation.value = false;
    }

    return isActivated;
  }

  Future<void> activateInternalWallet() async {
    loadingInternalWalletActivation.value = true;
    final isAlreadyActivated = await checkInternalWalletActivation(
      silent: true,
    );
    l.d('isAlreadyActivated: $isAlreadyActivated');
    if (isAlreadyActivated) {
      return;
    }
    final activated =
        await internal_activate_friendtechWallet(chainId: baseChainId);
    loadingInternalWalletActivation.value = false;
    isInternalWalletActivatedOnFriendTech.value = activated;
  }

  Future<void> activateExternalWallet() async {
    loadingExternalWalletActivation.value = true;
    if (externalWalletChianId != baseChainId) {
      Toast.error(
        message:
            "Chain not supported, please switch to Base on the external wallet",
      );
      loadingExternalWalletActivation.value = false;
      return;
    }
    final isActivated = await checkExternalWalletActivation(silent: true);
    if (isActivated != false) {
      return;
    }
    final activated = await ext_activate_friendtechWallet(
      chainId: baseChainId,
    );
    loadingExternalWalletActivation.value = false;
    isExternalWalletActivatedOnFriendTech.value = activated;
  }

  Future<bool?> checkExternalWalletActivation({bool? silent}) async {
    if (loadingExternalWalletActivation.value) return null;
    if (externalWalletChianId != baseChainId) {
      isExternalWalletActivatedOnFriendTech.value = false;
      return false;
    }

    if (silent != true) {
      loadingExternalWalletActivation.value = true;
    }

    final internalWalletAddress =
        await web3AuthWalletAddress(); // Evm.getAddress();
    if (internalWalletAddress == null) {
      isExternalWalletActivatedOnFriendTech.value = false;
      if (silent != true) {
        loadingExternalWalletActivation.value = false;
      }
      return false;
    }
    final externalWalletAddress = globalController.connectedWalletAddress.value;
    if (externalWalletAddress.isEmpty) {
      isExternalWalletActivatedOnFriendTech.value = false;
      if (silent != true) {
        loadingExternalWalletActivation.value = false;
      }
      return false;
    } else {
      final activeWallets = await internal_friendTech_getActiveUserWallets(
        internalWalletAddress: internalWalletAddress,
        externalWalletAddress: externalWalletAddress,
        chainId: baseChainId,
      );
      final isActivated = activeWallets.isExternalWalletActive;
      isExternalWalletActivatedOnFriendTech.value = isActivated;
      if (silent != true) {
        loadingExternalWalletActivation.value = false;
      }
      return isActivated;
    }
  }

  void openFeedbackPage() {
    launchUrl(
      Uri.parse(
        'https://docs.google.com/forms/u/1/d/1yj3GC6-JkFnWo1UiWj36sMISave9529x2fpqzHv2hIo/edit',
      ),
    );
  }

  Future<void> deactivateAccount() async {
    isDeactivatingAccount.value = true;
    Get.close();
    final success = await _authRepository.deactivateAccount();
    if (success) {
      globalController.setLoggedIn(false);
    }
    isDeactivatingAccount.value = false;
  }

  void showDeactivationDialog() {
    Get.dialog(
      const DeactivationForm(),
    );
  }

  Future<void> _copyPrivateKey() async {
    final String privateKey;
    try {
      privateKey = await Web3AuthFlutter.getPrivKey();
    } catch (e) {
      Toast.error(
        message: 'Private key not found',
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: privateKey));
    Toast.success(
      title: 'Copied',
      message:
          'Private key copied. The clipboard will be cleared in 60 seconds.',
    );
    Future.delayed(const Duration(seconds: 60), () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == privateKey) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  void showPrivateKeyWarning() {
    Get.dialog(
      AppDialog(
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.danger,
        urgent: true,
        title: 'WARNING: Private Key Access',
        message:
            'IMPORTANT: Your private key is the key to your account. Anyone with access to it can control your account and steal your assets.',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCallout(
              text: 'NEVER share your private key with anyone',
              color: AppColors.danger,
              icon: Icons.block_rounded,
            ),
            const SizedBox(height: 8),
            AppCallout(
              text: 'NEVER enter it on any website',
              color: AppColors.danger,
              icon: Icons.block_rounded,
            ),
            const SizedBox(height: 8),
            AppCallout(
              text: 'NEVER store it in plain text',
              color: AppColors.danger,
              icon: Icons.block_rounded,
            ),
          ],
        ),
        stackActions: true,
        actions: [
          AppPrimaryButton(
            label: 'Copy Private Key',
            icon: Icons.copy_rounded,
            color: AppColors.danger,
            onPressed: () {
              Navigator.pop(Get.context!);
              _copyPrivateKey();
            },
          ),
          AppSecondaryButton(
            label: 'Cancel',
            onPressed: () => Get.close(),
          ),
        ],
      ),
    );
  }

  void addOrSwitchAccount(Provider provider, {String? email}) {
    globalController.addOrSwitchAccount(provider, email: email);
  }

  Future<void> setAccountAsPrimary(String address) async {
    addressThatIsBeningMadePrimary.value = address;
    try {
      final res = await _authRepository.setAccountAsPrimary(address: address);
      if (res) {
        final myAccounts = globalController.myUserInfo.value?.accounts ?? [];
        final updatedAccounts = myAccounts.map((account) {
          if (account.address == address) {
            return account.copyWith(is_primary: true);
          }
          return account.copyWith(is_primary: false);
        }).toList();
        final updatedUser = globalController.myUserInfo.value?.copyWith(
          accounts: updatedAccounts,
        );
        globalController.myUserInfo.value = updatedUser;
        Toast.success(message: 'Account is set as primary');
      }
    } catch (e) {
      // toast is handled in the api call
      l.e(e);
    } finally {
      addressThatIsBeningMadePrimary.value = null;
    }
  }
}

class DeactivationForm extends StatefulWidget {
  const DeactivationForm({super.key});

  @override
  State<DeactivationForm> createState() => _DeactivationFormState();
}

class _DeactivationFormState extends State<DeactivationForm> {
  final controller = Get.find<MyProfileController>();
  final _deactivationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _deactivationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AppDialog(
        icon: Icons.delete_outline_rounded,
        iconColor: AppColors.danger,
        urgent: true,
        title: 'Delete Account',
        message:
            'You are about to delete your account. Your account will be deactivated and you will not be able to use it anymore. Are you sure you want to delete your account? This action cannot be undone.',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Type "delete" to confirm.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _deactivationController,
              style: AppText.body,
              decoration: const InputDecoration(
                hintText: 'Type "delete" to confirm',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter "delete" to confirm';
                }
                if (value.toLowerCase() != 'delete') {
                  return 'Please enter exactly "delete"';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          AppSecondaryButton(
            label: 'Cancel',
            onPressed: () => Get.close(),
          ),
          Obx(() {
            final isDeactivatingAccount =
                controller.isDeactivatingAccount.value;
            return AppPrimaryButton(
              label: 'Delete',
              color: AppColors.danger,
              loading: isDeactivatingAccount,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  controller.deactivateAccount();
                }
              },
            );
          }),
        ],
      ),
    );
  }
}
