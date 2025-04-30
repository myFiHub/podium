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
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/auth/additionalDataForLogin.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/widgets/button/button.dart';
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
  // String Movement = '0.0';
  String movementAptos = '0.0';

  Balances({
    required this.Base,
    required this.Avalanche,
    // required this.Movement,
    required this.movementAptos,
  });
}

class MyProfileController extends GetxController {
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
  final balances = Rx(
    Balances(
      Base: '0.0',
      Avalanche: '0.0',
      // Movement: '0.0',
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
    _getMyProfile();
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
          color: Colors.red,
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
          print("target: $target");
          print(
              "clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
        },
        onClickOverlay: (target) {
          print('onClickOverlay: $target');
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
  _scrollIfNeeded() async {
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

  _getMyProfile() async {
    final profile = await HttpApis.podium
        .getMyUserData(additionalData: AdditionalDataForLogin());
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

  _createStep({
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
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
                if (hasNext)
                  Button(
                    size: ButtonSize.SMALL,
                    type: ButtonType.outline,
                    color: Colors.white,
                    onPressed: () async {
                      await _scrollIfNeeded();
                      tutorialCoachMark.next();
                    },
                    child: const Text(
                      "Next",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else
                  Button(
                    size: ButtonSize.SMALL,
                    type: ButtonType.outline,
                    color: Colors.white,
                    onPressed: () {
                      introFinished(true);
                    },
                    child: const Text(
                      "Finish",
                      style: TextStyle(color: Colors.white),
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

  getBalances() async {
    try {
      isGettingBalances.value = true;
      final baseClient = evmClientByChainId(baseChainId);
      final avalancheClient = evmClientByChainId(avalancheChainId);
      // final movementClient = evmClientByChainId(movementEVMChain.chainId);
      final myaddress = await web3AuthWalletAddress();
      final callMap = {
        'base': baseClient.getBalance(parseAddress(myaddress!)),
        'avalanche': avalancheClient.getBalance(parseAddress(myaddress)),
        // 'movement': movementClient.getBalance(parseAddress(myaddress)),
        'movementAptos': AptosMovement.balance,
      };
      final results = await allSettled(callMap);
      final baseBalance =
          results['base']!['status'] == AllSettledStatus.fulfilled
              ? results['base']!['value']
              : EtherAmount.zero();

      final avalancheBalance =
          results['avalanche']!['status'] == AllSettledStatus.fulfilled
              ? results['avalanche']!['value']
              : EtherAmount.zero();
      // final movementBalance =
      //     results['movement']!['status'] == AllSettledStatus.fulfilled
      //         ? results['movement']!['value']
      //         : EtherAmount.zero();
      final movementAptosBalance =
          results['movementAptos']!['status'] == AllSettledStatus.fulfilled
              ? results['movementAptos']!['value']
              : BigInt.zero;
      final reason = results['movementAptos']!['reason'];
      if (reason is DioException) {
        l.e(reason.response?.data);
      }

      balances.value = Balances(
        Base: weiToDecimalString(wei: baseBalance),
        Avalanche: weiToDecimalString(wei: avalancheBalance),
        // Movement: weiToDecimalString(wei: movementBalance),
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

  activateInternalWallet() async {
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

  activateExternalWallet() async {
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

  openFeedbackPage() {
    launchUrl(
      Uri.parse(
        'https://docs.google.com/forms/u/1/d/1yj3GC6-JkFnWo1UiWj36sMISave9529x2fpqzHv2hIo/edit',
      ),
    );
  }

  deactivateAccount() async {
    isDeactivatingAccount.value = true;
    Get.close();
    final success = await HttpApis.podium.deactivateAccount();
    if (success) {
      globalController.setLoggedIn(false);
    }
    isDeactivatingAccount.value = false;
  }

  void showDeactivationDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: ColorName.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: DeactivationForm(),
        ),
      ),
    );
  }

  void showPrivateKeyWarning() async {
    String privateKey = '';
    try {
      privateKey = await Web3AuthFlutter.getPrivKey();
    } catch (e) {
      Toast.error(
        title: 'Error',
        message: 'Private key not found',
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        backgroundColor: ColorName.cardBackground,
        title: const Text(
          '⚠️ WARNING: Private Key Access',
          style: TextStyle(
            color: Colors.red,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IMPORTANT: Your private key is the key to your account. Anyone with access to it can control your account and steal your assets.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '⚠️ NEVER share your private key with anyone',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '⚠️ NEVER enter it on any website',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '⚠️ NEVER store it in plain text',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.close(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: privateKey));
              Toast.success(
                title: 'Copied',
                message: 'Private key copied to clipboard',
              );
              Navigator.pop(Get.context!);
            },
            child: const Text('Copy Private Key'),
          ),
        ],
      ),
    );
  }

  void addAccount(Provider provider) {
    globalController.addAccount(provider);
  }
}

class DeactivationForm extends GetView<MyProfileController> {
  DeactivationForm({super.key});
  @override
  Widget build(BuildContext context) {
    final TextEditingController _deactivationController =
        TextEditingController();
    final _formKey = GlobalKey<FormState>();
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorName.white,
              ),
              children: [
                TextSpan(text: 'Delete Account'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                height: 1.5,
                fontSize: 14,
                color: ColorName.secondaryText,
              ),
              children: [
                TextSpan(
                  text:
                      'You are about to delete your account.\nYour account will be deactivated and \nyou will not be able to use it anymore. \nAre you sure you want to delete your account? This action cannot be undone. \n',
                ),
                TextSpan(
                  text: 'Type "delete" to confirm.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _deactivationController,
            decoration: const InputDecoration(
              hintText: 'Type "delete" to confirm',
              border: OutlineInputBorder(),
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 100,
                child: TextButton(
                  onPressed: () => Get.close(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Obx(() {
                final isDeactivatingAccount =
                    controller.isDeactivatingAccount.value;
                return Expanded(
                    child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      controller.deactivateAccount();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isDeactivatingAccount
                      ? const LoadingWidget()
                      : const Text('Delete Account'),
                ));
              }),
            ],
          ),
        ],
      ),
    );
  }
}
