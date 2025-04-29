import 'dart:async';

import 'package:aptos/aptos.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/lib/firebase.dart';
import 'package:podium/app/modules/global/services/oneSignal.dart';
import 'package:podium/app/modules/global/utils/getWeb3AuthWalletAddress.dart';
import 'package:podium/app/modules/global/utils/web3AuthProviderToLoginTypeString.dart';
import 'package:podium/app/modules/global/utils/web3auth_utils.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/app/modules/outpostDetail/controllers/outpost_detail_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/metadata/metadata.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/services/websocket/client.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/storage.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3auth_flutter/enums.dart';
import 'package:web3auth_flutter/input.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';

PairingMetadata _pairingMetadata = const PairingMetadata(
  name: StringConstants.w3mPageTitleV3,
  description: StringConstants.w3mPageTitleV3,
  url: 'https://walletconnect.com/',
  icons: [
    'https://docs.walletconnect.com/assets/images/web3modalLogo-2cee77e07851ba0a710b56d03d4d09dd.png'
  ],
  redirect: Redirect(
    native: 'podium://',
  ),
);

final _checkOptions = [
  // InternetCheckOption(uri: Uri.parse('https://one.one.one.one')),
  // InternetCheckOption(uri: Uri.parse('https://api.web3modal.com')),
  // InternetCheckOption(uri: Uri.parse('https://8.8.8.8'))
  InternetCheckOption(uri: Uri.parse(Env.jitsiServerUrl)),
];

class GlobalUpdateIds {
  static const showArchivedOutposts = 'showArchivedOutposts';
  static const ticker = 'ticker';
}

class GlobalController extends GetxController {
  static final storage = GetStorage();
  final oneSignalService =
      Get.put<OneSignalService>(OneSignalService(), permanent: true);

  final appLifecycleState = Rx<AppLifecycleState>(AppLifecycleState.resumed);
  final w3serviceInitialized = false.obs;
  final connectedWalletAddress = "".obs;
  String jitsiServerAddress = '';

  final myUserInfo = Rxn<UserModel>();
  final activeRoute = AppPages.INITIAL.obs;
  final isAutoLoggingIn = true.obs;
  final isConnectedToInternet = true.obs;
  late ReownAppKitModal web3ModalService;
  AptosAccount? aptosAccount;
  final loggedIn = false.obs;
  final initializedOnce = false.obs;
  final isLoggingOut = false.obs;
  final isFirebaseInitialized = false.obs;
  final ticker = 0.obs;
  final showArchivedOutposts =
      RxBool(storage.read(StorageKeys.showArchivedOutposts) ?? true);
  late PodiumAppMetadata appMetadata;
  late ReownAppKitModalNetworkInfo movementAptosNetwork;
  late String movementAptosPodiumProtocolAddress;
  late String movementAptosCheerBooAddress;

  final deepLinkRoute = ''.obs;

  final externalWalletChainId = RxString(
      (storage.read(StorageKeys.externalWalletChainId) ??
          Env.initialExternalWalletChainId));

  WebSocketService? ws_client;

  ReownAppKitModalNetworkInfo? get externalWalletChain {
    final chain = ReownAppKitModalNetworks.getNetworkInfo(
      Env.chainNamespace,
      externalWalletChainId.value,
    );
    return chain;
  }

  final connectionCheckerInstance = InternetConnection.createInstance(
    checkInterval: const Duration(seconds: 5),
    customCheckOptions: _checkOptions,
    useDefaultOptions: false,
  );

  @override
  void onInit() async {
    super.onInit();
    // add movement chain to w3m chains, this should be the first thing to do, since it's needed all through app

    try {
      await Future.wait<void>([
        initializeWeb3Auth(),
        _getAndSetMetadata(),
        FirebaseInit.init(),
      ]);
    } catch (e) {
      l.e("error initializing app $e");
    }
    await _addCustomNetworks();

    startTicker();
    isFirebaseInitialized.value = true;
    final res = await analytics.getSessionId();

    l.d('analytics session id: $res');
    bool result = await connectionCheckerInstance.hasInternetAccess;
    l.d("has internet access: $result");
    if (result) {
      initializeApp();
    } else {
      l.e("one of the main apis can't be reached: ${_checkOptions.map((e) => e.uri)}");
    }
    initializeInternetConnectionChecker();
  }

  @override
  void onReady() async {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  _getAndSetMetadata() async {
    final metadata = await HttpApis.podium.appMetadata();
    appMetadata = metadata;
    jitsiServerAddress = appMetadata.va;
  }

  _addCustomNetworks() async {
    final movementAptosMetadata = appMetadata.movement_aptos_metadata;
    movementAptosNetwork = ReownAppKitModalNetworkInfo(
      name: movementAptosMetadata.name,
      chainId: movementAptosMetadata.chain_id,
      chainIcon: movementIcon,
      currency: 'MOVE',
      rpcUrl: movementAptosMetadata.rpc_url,
      explorerUrl: 'https://explorer.movementlabs.xyz',
    );
    movementAptosPodiumProtocolAddress =
        movementAptosMetadata.podium_protocol_address;
    movementAptosCheerBooAddress =
        '0xd2f0d0cf38a4c64620f8e9fcba104e0dd88f8d82963bef4ad57686c3ee9ed7aa'; // movementAptosMetadata.cheer_boo_address;

    try {
      ReownAppKitModalNetworks.addSupportedNetworks(
        Env.chainNamespace,
        [
          movementEVMMainNetChain,
          movementEVMDevnetChain,
          movementAptosNetwork,
          movementAptosBardokChain,
          if (movementAptosNetwork.chainId != movementTestnet.chainId)
            movementTestnet,
        ],
      );
    } catch (e) {
      l.e("error ReownAppKitModalNetworks app $e");
    }
  }

  Future<void> initializeApp() async {
    checkLogin();
    initializeW3MService();
    listenToWalletAddressChange();
    initializedOnce.value = true;
  }

  void startTicker() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      ticker.value++;
      update([GlobalUpdateIds.ticker]);
    });
  }

  Future<void> toggleShowArchivedOutposts() async {
    showArchivedOutposts.value = !showArchivedOutposts.value;
    storage.write(StorageKeys.showArchivedOutposts, showArchivedOutposts.value);
    update([GlobalUpdateIds.showArchivedOutposts]);
  }

  Future<bool> switchExternalWalletChain(String chainId) async {
    bool success = false;
    final chain = ReownAppKitModalNetworks.getNetworkInfo(
      Env.chainNamespace,
      chainId,
    );
    if (chain == null) {
      l.e("chain not found");
      success = false;
    }
    try {
      final currentChainId = web3ModalService.selectedChain?.chainId;
      if (currentChainId == chainId) {
        success = true;
      } else {
        await web3ModalService.selectChain(
          chain,
          switchChain: true,
        );
        final selectedChainId = web3ModalService.selectedChain?.chainId;
        if (selectedChainId != null && selectedChainId.isNotEmpty) {
          success = true;
        } else {
          l.e("error switching chain");
          success = false;
        }
      }
    } catch (e) {
      l.e("error switching chain $e");
      success = false;
    }
    if (success) {
      storage.write(StorageKeys.externalWalletChainId, chainId);
      externalWalletChainId.value = chainId;
    } else {
      storage.remove(StorageKeys.externalWalletChainId);
    }
    return success;
  }

  Future<void> initializeWeb3Auth() async {
    // Initialize the Web3AuthFlutter instance.
    await Web3AuthFlutter.init(
      Web3AuthOptions(
        clientId:
            //
            // "BPi5PB_UiIZ-cPz1GtV5i1I2iOSOHuimiXBI0e-Oe_u6X3oVAbCiAZOTEBtTXw4tsluTITPqA8zMsfxIKMjiqNQ",
            Env.web3AuthClientId,
        sessionTime: 60 * 60 * 24 * 7,
        network: Network.sapphire_mainnet,
        redirectUrl: resolveRedirectUrl(),
        whiteLabel: WhiteLabelData(
          appName:
              //
              // "Web3Auth Flutter Playground",
              "Podium",
          mode: ThemeModes.dark,
        ),
      ),
    );
    try {
      await Web3AuthFlutter.initialize();
    } catch (e) {
      l.e("error initializing Web3AuthFlutter $e");
    }
    l.i('\$\$\$\$\$\$\$\$\$\$\$ Web3AuthFlutter initialized');
  }

  Future<void> initializeInternetConnectionChecker() async {
    connectionCheckerInstance.onStatusChange
        .listen((InternetStatus status) async {
      switch (status) {
        case InternetStatus.connected:
          isConnectedToInternet.value = true;
          l.i("Internet connected");
          final versionResolved = await checkVersion();
          if (versionResolved && !initializedOnce.value) {
            await initializeApp();
          }

          break;
        case InternetStatus.disconnected:
          l.f("Internet disconnected");
          isConnectedToInternet.value = false;
          break;
      }
    });
  }

  Future<void> listenToWalletAddressChange() async {
    connectedWalletAddress.listen((newAddress) async {
      // ignore: unnecessary_null_comparison
      if (newAddress != '' && myUserInfo.value != null) {
        _saveExternalWalletAddress(newAddress);
      }
    });
  }

  Future<void> _saveExternalWalletAddress(String address) async {
    try {
      await saveUserWalletAddressOnFirebase(address);
      myUserInfo.value!.external_wallet_address = address;
      myUserInfo.refresh();
    } catch (e) {
      l.e("error saving wallet address $e");
      Toast.error(message: "Error saving wallet address, try again");
    }
  }

  saveUserWalletAddressOnFirebase(String walletAddress) async {
    await HttpApis.podium.updateMyUserData({
      "external_wallet_address": walletAddress,
    });
    l.d("new wallet address SAVED $walletAddress");
    return;
  }

  Future<void> openDeepLinkOutpost(String route) async {
    if (route.contains(Routes.OUTPOST_DETAIL)) {
      Navigate.to(
        type: NavigationTypes.offAllNamed,
        route: Routes.HOME,
      );
      final splited = route.split(Routes.OUTPOST_DETAIL);
      if (splited.length < 2) {
        l.f("splited: $splited");
        return;
      }
      final outpostId = splited[1];
      final outpostsController = Get.put(OutpostsController());
      Get.put(OutpostDetailController());
      outpostsController.joinOutpostAndOpenOutpostDetailPage(
        outpostId: outpostId,
        joiningByLink: true,
      );
      deepLinkRoute.value = '';

      activeRoute.value = Routes.HOME;
    }
  }

  Future<void> setDeepLinkRoute(String route) async {
    deepLinkRoute.value = route;
    if (loggedIn.value) {
      l.e("logged in, opening deep link $route");
      if (route.contains(Routes.OUTPOST_DETAIL)) {
        openDeepLinkOutpost(route);
      } else {
        l.e("deep link not handled");
      }
    } else if (route.contains('referral')) {
      openLoginPageWithReferral(route);
    }
  }

  Future<void> openLoginPageWithReferral(String route) async {
    l.f("opening login page with referral");
    final referrerId = _extractReferrerId(route);
    if (loggedIn.value) {
      setLoggedIn(false);
      return;
    }
    Navigate.to(
      type: NavigationTypes.offAllNamed,
      route: Routes.LOGIN,
      parameters: {
        LoginParametersKeys.referrerId: referrerId ?? '',
      },
    );
  }

  cleanStorage() {
    final storage = GetStorage();
    final sawProfileIntro =
        storage.read<bool?>(IntroStorageKeys.viewedMyProfile);
    final sawCreateGroupIntro =
        storage.read<bool?>(IntroStorageKeys.viewedCreateOutpost);
    final sawOngoingCallIntro =
        storage.read<bool?>(IntroStorageKeys.viewedOngiongCall);
    final showArchivedOutposts =
        storage.read<bool?>(StorageKeys.showArchivedOutposts);
    storage.erase();

    storage.write(IntroStorageKeys.viewedMyProfile, sawProfileIntro);
    storage.write(StorageKeys.showArchivedOutposts, showArchivedOutposts);
    storage.write(IntroStorageKeys.viewedCreateOutpost, sawCreateGroupIntro);
    storage.write(IntroStorageKeys.viewedOngiongCall, sawOngoingCallIntro);
  }

  Future<bool> checkVersion() async {
    final storage = GetStorage();
    final ignoredOrAcceptedVersion =
        storage.read<String>(StorageKeys.ignoredOrAcceptedVersion) ?? '';

    final (
      shouldCheckVersion,
      forceUpdate,
      version,
    ) = (
      appMetadata.version_check,
      appMetadata.force_update,
      appMetadata.version
    );

    if (shouldCheckVersion == false) {
      l.d('version check disabled');
      return true;
    }

    final currentVersion = Env.VERSION.split('+')[0];

    // Skip if already ignored/accepted this version
    if (ignoredOrAcceptedVersion == version) {
      l.d('version already ignored/accepted');
      return true;
    }

    // Compare versions using semantic versioning
    final currentParts = currentVersion.split('.').map(int.parse).toList();
    final remoteParts = version.split('.').map(int.parse).toList();

    // Pad shorter version with zeros
    while (currentParts.length < remoteParts.length) {
      currentParts.add(0);
    }
    while (remoteParts.length < currentParts.length) {
      remoteParts.add(0);
    }

    bool isRemoteVersionGreater = false;
    for (int i = 0; i < currentParts.length; i++) {
      if (remoteParts[i] > currentParts[i]) {
        isRemoteVersionGreater = true;
        break;
      } else if (remoteParts[i] < currentParts[i]) {
        break;
      }
    }

    if (isRemoteVersionGreater) {
      l.e('New version available: $version (current: $currentVersion)');
      Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: const Text('New version available'),
          content: Text('A new version of Podium ($version) is available',
              style: const TextStyle(color: ColorName.black)),
          titleTextStyle: const TextStyle(
            color: ColorName.black,
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () {
                  storage.write(StorageKeys.ignoredOrAcceptedVersion, version);
                  Get.close();
                },
                child: const Text(
                  'Later',
                  style: TextStyle(color: ColorName.black),
                ),
              ),
            TextButton(
              onPressed: () async {
                if (!forceUpdate) {
                  storage.write(StorageKeys.ignoredOrAcceptedVersion, version);
                }
                try {
                  await launchUrl(
                    Uri.parse(
                      Env.appStoreUrl,
                    ),
                  );
                } catch (e) {
                  l.e("error launching url $e");
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      );
      return true;
    } else {
      l.d('version is up to date');
      return true;
    }
  }

  checkLogin() async {
    isAutoLoggingIn.value = true;
    try {
      final loginType = storage.read<String?>(StorageKeys.loginType);
      if (loginType == null) {
        isAutoLoggingIn.value = false;
        return;
      }
      final LoginController loginController = Get.put(LoginController());
      await loginController.socialLogin(
        loginMethod: loginTypeStringToWeb3AuthProvider(loginType),
        ignoreIfNotLoggedIn: true,
      );
    } catch (e) {
      isAutoLoggingIn.value = false;
      Navigate.to(
        type: NavigationTypes.offAllNamed,
        route: Routes.LOGIN,
      );
      return;
    }
  }

  void setLoggedIn(bool value) async {
    loggedIn.value = value;
    if (value == false) {
      l.f("logging out");
      _logout();
      analytics.logEvent(
        name: 'logout',
        parameters: {
          'user_id': myUserInfo.value?.uuid ?? '',
        },
      );
    } else {
      await Navigate.to(
        type: NavigationTypes.offAllNamed,
        route: Routes.HOME,
      );

      if (deepLinkRoute.value.isNotEmpty) {
        final route = deepLinkRoute;
        openDeepLinkOutpost(route.value);
      }
      isAutoLoggingIn.value = false;

      try {
        await oneSignalService.initialize();
        final initialized = oneSignalService.initialized;
        if (initialized) {
          await oneSignalService.login(myUserInfo.value?.uuid ?? '');
        }
      } catch (e) {
        l.e("error initializing oneSignal $e");
      }
    }
  }

  Future<bool> initializeWebSocket({
    required String token,
  }) async {
    ws_client = WebSocketService.instance;
    return await ws_client?.connect(token) ?? false;
  }

  String? _extractReferrerId(String route) {
    final splited = route.split('referral');
    if (splited.length < 2) {
      l.f("splited: $splited");
      return null;
    }
    return splited[1];
  }

  Future<void> _logout() async {
    isLoggingOut.value = true;
    isAutoLoggingIn.value = false;
    web3AuthAddress = '';
    oneSignalService.dismiss();
    try {
      await Web3AuthFlutter.logout();
    } catch (e) {
      l.e(e);
      isLoggingOut.value = false;
    }

    cleanStorage();
    try {
      await web3ModalService.disconnect();
    } catch (e) {
      l.e("error disconnecting wallet $e");
      isLoggingOut.value = false;
    }
    l.f('Navigating to login page');

    final rerouteWithReferral =
        deepLinkRoute.isNotEmpty && deepLinkRoute.contains('referral');
    String referrerId = '';
    if (rerouteWithReferral) {
      referrerId = _extractReferrerId(deepLinkRoute.value) ?? '';
    }
    Navigate.to(
        type: NavigationTypes.offAllNamed,
        route: Routes.LOGIN,
        parameters: {
          if (referrerId.isNotEmpty) LoginParametersKeys.referrerId: referrerId,
        });

    ws_client?.close();
    ws_client = null;
    isLoggingOut.value = false;
  }

  void setIsMyUserOver18(bool value) {
    myUserInfo.value!.is_over_18 = value;
    myUserInfo.refresh();
  }

  Future<ReownAppKitModal?> initializeW3MService() async {
    web3ModalService = ReownAppKitModal(
      context: Get.context!,
      projectId: Env.projectId,
      logLevel: LogLevel.error,
      enableAnalytics: false,
      metadata: _pairingMetadata,
      featuredWalletIds: {
        'fd20dc426fb37566d803205b19bbc1d4096b248ac04548e3cfb6b3a38bd033aa', // Coinbase
        '18450873727504ae9315a084fa7624b5297d2fe5880f0982979c17345a138277', // Kraken Wallet
        'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // Metamask
        '1ae92b26df02f0abca6304df07debccd18262fdf5fe82daa81593582dac9a369', // Rainbow
        'c03dfee351b6fcc421b4494ea33b9d4b92a984f87aa76d1663bb28705e95034a', // Uniswap
        '38f5d18bd8522c244bdd70cb4a68e0e718865155811c043f052fb9f1c51de662', // Bitget
      },
    );
    await web3ModalService.init();
    try {
      final service = await BlockChainUtils.initializewm3Service(
        web3ModalService,
        connectedWalletAddress,
        w3serviceInitialized,
      );
      return service;
    } catch (e) {
      l.f("error starting w3m service");
    }

    return null;
  }

  Future<void> connectToWallet({void Function()? afterConnection}) async {
    try {
      // web3ModalService.disconnect();
      await web3ModalService.init();
      await web3ModalService.openModalView();
      final address =
          await BlockChainUtils.retrieveConnectedWallet(web3ModalService);
      connectedWalletAddress.value = address;
      if (afterConnection != null && address != '') {
        afterConnection();
      }
      analytics.logEvent(
        name: 'wallet_connected',
        parameters: {'wallet_address': address},
      );
    } catch (e) {
      analytics.logEvent(
        name: 'wallet_connection_failed',
        parameters: {'error': e.toString()},
      );
      if (e is ReownAppKitModalException) {
        l.e(e.message);
      } else {
        l.e(e);
      }
    }
  }

  Future<void> disconnect() async {
    final removed = await HttpApis.podium
        .updateMyUserData({'external_wallet_address': null});
    if (removed != null) {
      try {
        web3ModalService.disconnect();
      } catch (e) {
        l.e(e);
      }
      storage.remove(StorageKeys.externalWalletChainId);
      storage.remove(StorageKeys.selectedWalletName);
      connectedWalletAddress.value = '';
    }
    analytics.logEvent(
      name: 'wallet_disconnected',
    );
  }
}
