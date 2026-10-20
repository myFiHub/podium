import 'dart:async';

import 'package:aptos/aptos.dart';
import 'package:dartx/dartx_io.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/lib/firebase.dart';
import 'package:podium/app/modules/global/services/app_version_checker.dart';
import 'package:podium/app/modules/global/services/connectivity_service.dart';
import 'package:podium/app/modules/global/services/deep_links.dart';
import 'package:podium/app/modules/global/services/oneSignal.dart';
import 'package:podium/app/modules/global/utils/web3auth_utils.dart';
import 'package:podium/app/modules/global/utils/web3AuthProviderToLoginTypeString.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/app/modules/login/utils/signAndVerify.dart';
import 'package:podium/app/modules/myProfile/controllers/my_profile_controller.dart';
import 'package:podium/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/env.dart';
import 'package:podium/providers/api/podium/models/auth/additionalDataForLogin.dart';
import 'package:podium/providers/api/podium/models/auth/loginRequest.dart';
import 'package:podium/providers/api/podium/models/metadata/metadata.dart';
import 'package:podium/providers/api/podium/models/users/connect_new_account_request.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/services/websocket/websocket_service.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/storage.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:web3auth_flutter/enums.dart';
import 'package:web3auth_flutter/input.dart';
import 'package:web3auth_flutter/output.dart';
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

class GlobalUpdateIds {
  static const showArchivedOutposts = 'showArchivedOutposts';
  static const ticker = 'ticker';
}

class GlobalController extends GetxController {
  final _authRepository = Get.find<AuthRepository>();
  final _userRepository = Get.find<UserRepository>();
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
  late final connectivity = ConnectivityService(
    onConnected: _onInternetConnected,
    onResumed: () => ws_client?.ensureConnected(),
  );
  RxBool get isConnectedToInternet => connectivity.isConnected;
  late ReownAppKitModal web3ModalService;
  AptosAccount? aptosAccount;
  final loggedIn = false.obs;
  final addingOrSwitchingAccount_provider = Rxn<Provider>();

  final initializedOnce = false.obs;
  final isLoggingOut = false.obs;
  bool isFirebaseInitialized = false;
  final ticker = 0.obs;
  Future<void> web3AuthReady = Future.value();
  Timer? _tickerTimer;
  final showArchivedOutposts =
      RxBool(storage.read(StorageKeys.showArchivedOutposts) ?? true);
  late PodiumAppMetadata appMetadata;
  late ReownAppKitModalNetworkInfo movementAptosNetwork;
  late String movementAptosPodiumProtocolAddress;
  late String movementAptosCheerBooAddress;

  late final deepLinks = DeepLinkHandler(
    isLoggedIn: () => loggedIn.value,
    logout: () => setLoggedIn(false),
  );
  RxString get deepLinkRoute => deepLinks.route;

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

  @override
  void onInit() async {
    super.onInit();
    // add movement chain to w3m chains, this should be the first thing to do, since it's needed all through app

    // Takes seconds (network session restore). Only a saved login must wait for
    // it here; socialLogin awaits web3AuthReady itself.
    web3AuthReady = initializeWeb3Auth().catchError((e) {
      l.e("error initializing Web3Auth $e");
    });
    final internetCheck = connectivity.hasInternetAccess();
    try {
      await Future.wait<void>([
        _getAndSetMetadata(),
        FirebaseInit.init(),
      ]);
    } catch (e) {
      l.e("error initializing app $e");
    }
    await _addCustomNetworks();

    startTicker();
    isFirebaseInitialized = true;
    analytics
        .getSessionId()
        .then((id) => l.d('analytics session id: $id'))
        .catchError((e) => l.e('analytics session id unavailable: $e'));
    if (storage.read<String?>(StorageKeys.loginType) != null) {
      await web3AuthReady;
    }
    final reachable = await internetCheck;
    l.d("has internet access: $reachable");
    if (reachable) {
      initializeApp();
    }
    connectivity.start(appLifecycleState);
  }

  @override
  void onClose() {
    _tickerTimer?.cancel();
    connectivity.dispose();
    _walletAddressSubscription?.cancel();
    super.onClose();
  }

  Future<void> _getAndSetMetadata() async {
    final metadata = await _authRepository.appMetadata();
    appMetadata = metadata;
    jitsiServerAddress = appMetadata.va;
  }

  Future<void> _addCustomNetworks() async {
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
    movementAptosCheerBooAddress = movementAptosMetadata.cheer_boo_address;

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
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      ticker.value++;
      // Countdowns read the clock when built, so skipping UI updates while
      // backgrounded loses nothing.
      if (appLifecycleState.value == AppLifecycleState.resumed) {
        update([GlobalUpdateIds.ticker]);
      }
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
        clientId: Env.web3AuthClientId,
        sessionTime: 60 * 60 * 24 * 7,
        network: Network.sapphire_mainnet,
        redirectUrl: resolveRedirectUrl(),
        whiteLabel: WhiteLabelData(
          appName: "Podium",
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

  StreamSubscription<String>? _walletAddressSubscription;

  Future<void> listenToWalletAddressChange() async {
    if (_walletAddressSubscription != null) return;
    _walletAddressSubscription =
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

  Future<void> saveUserWalletAddressOnFirebase(String walletAddress) async {
    await _userRepository.updateMyUserData({
      "external_wallet_address": walletAddress,
    });
    l.d("new wallet address SAVED $walletAddress");
    return;
  }

  void setDeepLinkRoute(String route) => deepLinks.handle(route);

  Future<void> _onInternetConnected() async {
    ws_client?.ensureConnected();
    AppVersionChecker().check(appMetadata);
    if (!initializedOnce.value) await initializeApp();
  }

  void cleanStorage() {
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

  Future<void> checkLogin() async {
    isAutoLoggingIn.value = true;
    try {
      final loginType = storage.read<String?>(StorageKeys.loginType);
      if (loginType == null) {
        isAutoLoggingIn.value = false;
        return;
      }
      final loginController = Get.isRegistered<LoginController>()
          ? Get.find<LoginController>()
          : Get.put(LoginController());
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

  Future<void> setLoggedIn(bool value) async {
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

      deepLinks.openPendingOutpost();
      isAutoLoggingIn.value = false;
      await _initializeOneSignal(myUserId: myUserInfo.value?.uuid ?? '');
    }
  }

  Future<void> _initializeOneSignal({required String myUserId}) async {
    try {
      await oneSignalService.initialize();
      final initialized = oneSignalService.initialized;
      if (initialized) {
        await oneSignalService.login(myUserId);
      }
    } catch (e) {
      l.e("error initializing oneSignal $e");
    }
  }

  Future<bool> initializeWebSocket({
    required String token,
  }) async {
    ws_client = WebSocketService.instance;
    return await ws_client?.connect(token) ?? false;
  }

  Future<void> _logout() async {
    isLoggingOut.value = true;
    isAutoLoggingIn.value = false;
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

    final referrerId = deepLinks.pendingReferrerId ?? '';
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
    final removed = await _userRepository
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

  Future<void> addOrSwitchAccount(Provider provider, {String? email}) async {
    try {
      final currentPrivateKey = await Web3AuthFlutter.getPrivKey();
      final currentAccountAddress = privateKeyToPublicKey(currentPrivateKey);
      addingOrSwitchingAccount_provider.value = provider;
      if (provider == Provider.email_passwordless) {
        email ??= await showDialogToGetTheEmail();
        if (email.isNullOrEmpty) {
          addingOrSwitchingAccount_provider.value = null;
          return;
        }
      }
      Web3AuthResponse? res;

      if (email.isNotNullOrEmpty) {
        res = await Web3AuthFlutter.login(
          LoginParams(
            loginProvider: provider,
            mfaLevel: MFALevel.DEFAULT,
            extraLoginOptions: ExtraLoginOptions(
              login_hint: email,
            ),
          ),
        );
      } else {
        res = await Web3AuthFlutter.login(
          LoginParams(
            loginProvider: provider,
            mfaLevel: MFALevel.DEFAULT,
          ),
        );
      }
      if (res.ed25519PrivKey != null) {
        final newAccountPrivateKey = await Web3AuthFlutter.getPrivKey();
        final newAccountAddress = privateKeyToPublicKey(newAccountPrivateKey);

        final accountAlreadyExists = myUserInfo.value!.accounts
            .any((account) => account.address == newAccountAddress);

        final currentAccountAddressSignedByNewAccount =
            signMessage(newAccountPrivateKey, currentAccountAddress)!;
        final newAccountAddressSignedByCurrentAccount =
            signMessage(currentPrivateKey, newAccountAddress)!;

        // aptos account
        final generatedAptosAccount =
            AptosAccount.fromPrivateKey(newAccountPrivateKey);
        aptosAccount = generatedAptosAccount;
        final newAccountAptosAddress = generatedAptosAccount.address;
        final newAccountLoginType = web3AuthProviderToLoginTypeString(provider);
        final newAccountImage = res.userInfo?.profileImage;
        final request = ConnectNewAccountRequest(
          aptos_address: newAccountAptosAddress,
          current_address_signature: currentAccountAddressSignedByNewAccount,
          image: newAccountImage ?? '',
          login_type: newAccountLoginType,
          login_type_identifier: res.userInfo?.verifierId ?? '',
          new_address: newAccountAddress,
          new_address_signature: newAccountAddressSignedByCurrentAccount,
        );
        final connected = await _authRepository.connectNewAccount(request);
        if (connected) {
          final (signature, timestamp) =
              signMessageWithTimestamp(newAccountPrivateKey, newAccountAddress);

          await _switchToAccount(
            timestamp: timestamp,
            newAddress: newAccountAddress,
            newWeb3AuthUserInfo: res.userInfo!,
            selfSignedNewWalletAddress: signature,
            newAptosAddress: newAccountAptosAddress,
            provider: provider,
          );
          Toast.success(
            message:
                'Account ${accountAlreadyExists ? 'switched' : 'connected'} successfully',
          );
        }
      }
    } on UserCancelledException catch (e) {
      l.e(e);
    } catch (e) {
      l.e(e);
    } finally {
      addingOrSwitchingAccount_provider.value = null;
    }
  }

  Future<UserModel?> _switchToAccount({
    required TorusUserInfo newWeb3AuthUserInfo,
    required String selfSignedNewWalletAddress,
    required String newAptosAddress,
    required String newAddress,
    required Provider provider,
    required int timestamp,
  }) async {
    await oneSignalService.dismiss();
    web3ModalService.disconnect();
    ws_client?.close();
    ws_client = null;
    final request = LoginRequest(
      signature: selfSignedNewWalletAddress,
      timestamp: timestamp,
      username: newAddress,
      aptos_address: newAptosAddress,
      has_ticket: false,
      login_type: web3AuthProviderToLoginTypeString(provider),
      login_type_identifier: newWeb3AuthUserInfo.verifierId ?? '',
      referrer_user_uuid: null,
    );
    final (loginResponse, error, statusCode) = await _authRepository.login(
      request: request,
      additionalData: AdditionalDataForLogin(),
    );
    if (loginResponse != null) {
      myUserInfo.value = loginResponse;
      await _initializeOneSignal(myUserId: loginResponse.uuid);
      final callArray = <Future<void>>[];

      final outpostsController = Get.find<OutpostsController>();
      outpostsController.clearOutposts();
      final isProfileRegistered = Get.isRegistered<MyProfileController>();

      final isNotificationsRegistered =
          Get.isRegistered<NotificationsController>();
      if (isNotificationsRegistered) {
        final notificationsController = Get.find<NotificationsController>();
        notificationsController.notifications.clear();
        notificationsController.numberOfUnreadNotifications.value = 0;
        callArray.add(notificationsController.getNotifications());
      }

      if (isProfileRegistered) {
        final myProfileController = Get.find<MyProfileController>();
        callArray.add(myProfileController.getMyProfile());
        callArray.add(myProfileController.getBalances());
      }
      await Future.wait<void>([
        ...callArray,
        outpostsController.fetchAllOutpostsPage(0),
        outpostsController.fetchMyOutpostsPage(0)
      ]);
    }
    return loginResponse;
  }
}
