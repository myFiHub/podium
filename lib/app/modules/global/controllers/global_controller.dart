import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:particle_auth_core/particle_auth_core.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/lib/firebase.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/app/modules/global/utils/usersParser.dart';
import 'package:podium/app/modules/groupDetail/controllers/group_detail_controller.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/env.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/loginType.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:particle_base/model/user_info.dart' as ParticleUser;
import 'package:particle_base/model/chain_info.dart' as ChainInfo;
import 'package:particle_base/particle_base.dart' as ParticleBase;
import 'package:alarm/alarm.dart';

PairingMetadata _pairingMetadata = PairingMetadata(
  name: StringConstants.w3mPageTitleV3,
  description: StringConstants.w3mPageTitleV3,
  url: 'https://walletconnect.com/',
  icons: [
    'https://docs.walletconnect.com/assets/images/web3modalLogo-2cee77e07851ba0a710b56d03d4d09dd.png'
  ],
  redirect: Redirect(
    native: 'web3modalflutter://',
    universal: 'https://walletconnect.com/appkit',
  ),
);

final _checkOptions = [
  InternetCheckOption(uri: Uri.parse('https://one.one.one.one')),
  // InternetCheckOption(uri: Uri.parse('https://api.web3modal.com')),
  InternetCheckOption(uri: Uri.parse(movementChain.rpcUrl))
];

class GlobalUpdateIds {
  static const showArchivedGroups = 'showArchivedGroups';
  static const ticker = 'ticker';
}

class GlobalController extends GetxController with FireBaseUtils {
  static final storage = GetStorage();
  final appLifecycleState = Rx<AppLifecycleState>(AppLifecycleState.resumed);
  final w3serviceInitialized = false.obs;
  final connectedWalletAddress = "".obs;
  final jitsiServerAddress = '';
  final firebaseUserCredential = Rxn<UserCredential>();
  final particleAuthUserInfo = Rxn<ParticleUser.UserInfo>();
  final firebaseUser = Rxn<User>();
  final currentUserInfo = Rxn<UserInfoModel>();
  final activeRoute = AppPages.INITIAL.obs;
  final isAutoLoggingIn = true.obs;
  final isConnectedToInternet = true.obs;
  late ReownAppKitModal web3ModalService;
  final loggedIn = false.obs;
  final initializedOnce = false.obs;
  final isLoggingOut = false.obs;
  final isFirebaseInitialized = false.obs;
  final ticker = 0.obs;
  final showArchivedGroups =
      RxBool(storage.read(StorageKeys.showArchivedGroups) ?? false);
  String? deepLinkRoute = null;

  final particleWalletChainId = RxString(
      (storage.read(StorageKeys.particleWalletChainId) ??
          Env.initialParticleWalletChainId));
  final externalWalletChainId = RxString(
      (storage.read(StorageKeys.externalWalletChainId) ??
          Env.initialExternalWalletChainId));

  ChainInfo.ChainInfo? particleWalletChain(String? chainId) {
    final particleChain = ChainInfo.ChainInfo.getChain(
      int.parse(chainId ?? particleWalletChainId.value),
      ReownAppKitModalNetworks.getNetworkById(
        Env.chainNamespace,
        chainId ?? particleWalletChainId.value,
      )!
          .name,
    );
    return particleChain;
  }

  ReownAppKitModalNetworkInfo? get externalWalletChain {
    final chain = ReownAppKitModalNetworks.getNetworkById(
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
    ReownAppKitModalNetworks.addNetworks(Env.chainNamespace, [movementChain]);

    await Future.wait([
      initializeParticleAuth(),
      FirebaseInit.init(),
    ]);
    startTicker();
    isFirebaseInitialized.value = true;
    final res = await analytics.getSessionId();

    log.d('analytics session id: $res');
    bool result = await connectionCheckerInstance.hasInternetAccess;
    log.d("has internet access: $result");
    if (result) {
      initializeApp();
    } else {
      log.e(
          "one of the main apis can't be reached: ${_checkOptions.map((e) => e.uri)}");
    }
    initializeInternetConnectionChecker();
  }

  @override
  void onReady() async {
    web3ModalService = ReownAppKitModal(
      context: Get.context!,
      projectId: Env.projectId,
      logLevel: LogLevel.error,
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
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  initializeApp() async {
    checkLogin();
    initializeW3MService();
    listenToWalletAddressChange();
    Alarm.init();
    initializedOnce.value = true;
  }

  startTicker() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      ticker.value++;
      update([GlobalUpdateIds.ticker]);
    });
  }

  toggleShowArchivedGroups() {
    showArchivedGroups.value = !showArchivedGroups.value;
    storage.write(StorageKeys.showArchivedGroups, showArchivedGroups.value);
    update([GlobalUpdateIds.showArchivedGroups]);
  }

  Future<bool> switchExternalWalletChain(String chainId) async {
    bool success = false;
    final chain = ReownAppKitModalNetworks.getNetworkById(
      Env.chainNamespace,
      chainId,
    );
    if (chain == null) {
      log.e("chain not found");
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
          log.e("error switching chain");
          success = false;
        }
      }
    } catch (e) {
      log.e("error switching chain $e");
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

  Future<bool> switchParticleWalletChain(
    String chainId, {
    bool alsoSave = false,
  }) async {
    final chain = particleChainInfoByChainId(chainId);
    if (chain == null) {
      log.e("chain not found");
      if (alsoSave == true) {
        storage.remove(StorageKeys.particleWalletChainId);
      }
      return false;
    }
    final done = await ParticleBase.ParticleBase.setChainInfo(chain);
    if (!done) {
      log.e("error switching chain");
      if (alsoSave == true) {
        storage.remove(StorageKeys.particleWalletChainId);
      }
      return false;
    }
    if (alsoSave == true) {
      final selectedChainId = ParticleBase.ParticleBase.getChainId();
      particleWalletChainId.value = selectedChainId.toString();
      storage.write(
          StorageKeys.particleWalletChainId, selectedChainId.toString());
    }
    return true;
  }

  get particleEnvironment {
    return Env.environment == DEV
        ? ParticleBase.Env.dev
        : Env.environment == STAGE
            ? ParticleBase.Env.staging
            : ParticleBase.Env.production;
  }

  Future<void> initializeParticleAuth() async {
    try {
      final chainId = particleWalletChainId.value;
      final chainName =
          ReownAppKitModalNetworks.getNetworkById(Env.chainNamespace, chainId)!
              .name;
      final particleChain = particleWalletChainId == '30732'
          ? movementChainOnParticle
          : ChainInfo.ChainInfo.getChain(int.parse(chainId), chainName);
      if (particleChain == null) {
        log.f("${chainId} chain not found on particle");
        return Future.error("particle chain not initialized");
      }
      if (Env.environment != DEV &&
          Env.environment != STAGE &&
          Env.environment != PROD) {
        log.f("unhandled environment");
        log.f("particle auth not initialized");
        return Future.error("unhandled environment");
      }

      log.i("##########initializing ParticleAuth");
      ParticleBase.ParticleInfo.set(
        Env.particleProjectId,
        Env.particleClientKey,
      );

      ParticleBase.ParticleBase.init(
        particleChain,
        particleEnvironment,
      );
      log.i('##########particle auth initialized');
      return Future.value();
    } catch (e) {
      log.f('particle auth initialization failed');
      return Future.error(e);
    }
  }

  initializeInternetConnectionChecker() {
    connectionCheckerInstance.onStatusChange
        .listen((InternetStatus status) async {
      switch (status) {
        case InternetStatus.connected:
          isConnectedToInternet.value = true;
          log.i("Internet connected");
          final (versionResolved, serverAddress) = await (
            checkVersion(),
            getJitsiServerAddress(),
          ).wait;

          if (versionResolved && serverAddress != null) {
            await initializeApp();
          }

          break;
        case InternetStatus.disconnected:
          log.f("Internet disconnected");
          isConnectedToInternet.value = false;
          break;
      }
    });
  }

  listenToWalletAddressChange() async {
    connectedWalletAddress.listen((newAddress) async {
      // ignore: unnecessary_null_comparison
      if (newAddress != '' &&
          newAddress != null &&
          currentUserInfo.value != null) {
        _saveExternalWalletAddress(newAddress);
      }
    });
  }

  _saveExternalWalletAddress(String address) async {
    try {
      await saveUserWalletAddressOnFirebase(address);
      currentUserInfo.value!.localWalletAddress = address;
      currentUserInfo.refresh();
    } catch (e) {
      log.e("error saving wallet address $e");
      Get.snackbar('Error', 'Error saving wallet address, try again');
    }
  }

  saveUserWalletAddressOnFirebase(String walletAddress) async {
    // final user = FirebaseAuth.instance.currentUser;
    final userId = myId;
    final firebaseUserDbReference = FirebaseDatabase.instance
        .ref(FireBaseConstants.usersRef)
        .child(userId + '/' + UserInfoModel.localWalletAddressKey);
    final savedWalletAddress = await firebaseUserDbReference.get();
    if (savedWalletAddress.value == walletAddress || walletAddress.isEmpty) {
      return;
    }

    await firebaseUserDbReference.set(walletAddress);
    log.d("new wallet address SAVED $walletAddress");
    return;
  }

  openDeepLinkGroup(String route) async {
    if (route.contains(Routes.GROUP_DETAIL)) {
      Navigate.to(
        type: NavigationTypes.offAllNamed,
        route: Routes.HOME,
      );
      final splited = route.split(Routes.GROUP_DETAIL);
      if (splited.length < 2) {
        log.f("splited: $splited");
        return;
      }
      final groupId = splited[1];
      final groupsController = Get.put(GroupsController());
      Get.put(GroupDetailController());
      groupsController.joinGroupAndOpenGroupDetailPage(
        groupId: groupId,
        joiningByLink: true,
      );
      deepLinkRoute = null;
      activeRoute.value = Routes.HOME;
    }
  }

  setDeepLinkRoute(String route) async {
    deepLinkRoute = route;
    if (loggedIn.value) {
      log.e("logged in, opening deep link $route");
      openDeepLinkGroup(route);
    }
  }

  Future<bool> removeUserWalletAddressOnFirebase() async {
    try {
      final firebaseUserDbReference = FirebaseDatabase.instance
          .ref(FireBaseConstants.usersRef)
          .child(myId + '/' + UserInfoModel.localWalletAddressKey);
      await firebaseUserDbReference.set('');
      return true;
    } catch (e) {
      log.e("error removing wallet address $e");
      return false;
    }
  }

  cleanStorage() {
    final storage = GetStorage();
    storage.erase();
  }

  Future<String?> getJitsiServerAddress() {
    final completer = Completer<String?>();
    final serverAddressRef =
        FirebaseDatabase.instance.ref(FireBaseConstants.jitsiServerAddressRef);
    serverAddressRef.once().then((event) {
      final data = event.snapshot.value as dynamic;
      final serverAddress = data as String?;
      if (serverAddress == null) {
        log.e('server address not found');
        return completer.complete(null);
      }
      completer.complete(serverAddress);
    });
    return completer.future;
  }

  Future<bool> checkVersion() async {
    final storage = GetStorage();
    final ignoredOrAcceptedVersion =
        storage.read<String>(StorageKeys.ignoredOrAcceptedVersion) ?? '';
    final versionRef =
        FirebaseDatabase.instance.ref(FireBaseConstants.versionRef);
    final shouldCheckVersionRef =
        FirebaseDatabase.instance.ref(FireBaseConstants.versionCheckRef);
    final forceUpdateRef =
        FirebaseDatabase.instance.ref(FireBaseConstants.forceUpdate);
    final (
      shouldCheckVersionEvent,
      forceUpdateEvent,
      versionEvent,
    ) = await (
      shouldCheckVersionRef.get(),
      forceUpdateRef.get(),
      versionRef.get()
    ).wait;
    bool forcetToUpdate = false;
    if (forceUpdateEvent.value is bool) {
      forcetToUpdate = forceUpdateEvent.value as bool;
    }
    final shouldCheckVersion = shouldCheckVersionEvent.value as dynamic;
    if (shouldCheckVersion == false) {
      log.d('version check disabled');
      return true;
    }
    // listen to version changes
    final data = versionEvent.value as dynamic;
    final version = data as String?;
    if (version == null) {
      log.e('version not found');
      return (true);
    }
    final currentVersion = Env.VERSION.split('+')[0];
    final numberedLocalVersion = int.parse(currentVersion.replaceAll('.', ''));
    final numberedRemoteVersion = int.parse(version.replaceAll('.', ''));
    final isRemoteVersionGreater = numberedRemoteVersion > numberedLocalVersion;
    if (version != currentVersion &&
        ignoredOrAcceptedVersion != version &&
        isRemoteVersionGreater) {
      log.e('New version available');
      Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          title: const Text('New version available'),
          content: const Text('A new version of Podium is available',
              style: TextStyle(color: ColorName.black)),
          titleTextStyle: const TextStyle(
            color: ColorName.black,
          ),
          actions: [
            if (!forcetToUpdate)
              TextButton(
                onPressed: () {
                  storage.write(StorageKeys.ignoredOrAcceptedVersion, version);
                  Get.backLegacy();
                },
                child: const Text(
                  'Later',
                  style: TextStyle(color: ColorName.black),
                ),
              ),
            TextButton(
              onPressed: () {
                storage.write(StorageKeys.ignoredOrAcceptedVersion, version);
                launchUrl(
                  Uri.parse(
                    Env.appStoreUrl,
                  ),
                );
                SystemNavigator.pop();
                exit(0);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      );
      return true;
    } else {
      log.d('version is up to date');
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
      if (loginType == LoginType.emailAndPassword) {
        await _autoLoginWithEmailAndPassword();
        return;
      }
      final LoginController loginController = Get.put(LoginController());
      if (loginType == LoginType.email) {
        await loginController.loginWithEmail(ignoreIfNotLoggedIn: true);
        return;
      }
      if (loginType == LoginType.x) {
        await loginController.loginWithX(ignoreIfNotLoggedIn: true);
        return;
      }
      if (loginType == LoginType.google) {
        await loginController.loginWithGoogle(ignoreIfNotLoggedIn: true);
        return;
      }
      if (loginType == LoginType.facebook) {
        await loginController.loginWithFaceBook(ignoreIfNotLoggedIn: true);
        return;
      }
      if (loginType == LoginType.linkedin) {
        await loginController.loginWithLinkedIn(ignoreIfNotLoggedIn: true);
        return;
      }
      if (loginType == LoginType.apple) {
        await loginController.loginWithApple(ignoreIfNotLoggedIn: true);
        return;
      }
      if (loginType == LoginType.github) {
        await loginController.loginWithGithub(ignoreIfNotLoggedIn: true);
        return;
      }
    } catch (e) {
      isAutoLoggingIn.value = false;
      Navigate.to(
        type: NavigationTypes.offAllNamed,
        route: Routes.LOGIN,
      );
      return;
    }
  }

  _autoLoginWithEmailAndPassword() async {
    final isParticleLoggedIn = await ParticleAuthCore.isConnected();
    if (isParticleLoggedIn) {
      final particleUserInfo = await ParticleAuthCore.getUserInfo();
      particleAuthUserInfo.value = particleUserInfo;
    } else {
      log.e("particle not logged in");
      throw Exception("particle not logged in");
    }
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    if (isLoggedIn) {
      final user = FirebaseAuth.instance.currentUser;
      firebaseUser.value = user;
      final userId = user!.uid;
      final userInfo = await getUserInfoById(userId);
      currentUserInfo.value = userInfo;
      if (userInfo != null && userInfo.id.isNotEmpty) {
        final storage = GetStorage();
        storage.write(StorageKeys.userId, userInfo.id);
        storage.write(StorageKeys.userAvatar, userInfo.avatar);
        storage.write(StorageKeys.userFullName, userInfo.fullName);
        storage.write(StorageKeys.userEmail, userInfo.email);
        loggedIn.value = true;
        isAutoLoggingIn.value = false;
        Navigate.to(
          type: NavigationTypes.offAllNamed,
          route: Routes.HOME,
        );
      }
    } else {
      isAutoLoggingIn.value = false;
    }
  }

  setLoggedIn(bool value) {
    loggedIn.value = value;
    if (value == false) {
      log.f("logging out");
      _logout();
      analytics.logEvent(
        name: 'logout',
        parameters: {
          'user_id': currentUserInfo.value?.id ?? '',
        },
      );
    } else {
      Navigate.to(
        type: NavigationTypes.offAllNamed,
        route: Routes.HOME,
      );
      if (deepLinkRoute != null) {
        final route = deepLinkRoute!;
        openDeepLinkGroup(route);
        return;
      }
    }
  }

  _logout() async {
    isLoggingOut.value = true;
    isAutoLoggingIn.value = false;
    try {
      await ParticleAuthCore.disconnect();
    } catch (e) {
      log.e(e);
      isLoggingOut.value = false;
    }
    cleanStorage();
    try {
      await web3ModalService.disconnect();
    } catch (e) {
      log.e("error disconnecting wallet $e");
      isLoggingOut.value = false;
    }
    log.f('Navigating to login page');
    Navigate.to(
      type: NavigationTypes.offAllNamed,
      route: Routes.LOGIN,
    );
    firebaseUserCredential.value = null;
    try {
      await FirebaseAuth.instance.signOut();
      isLoggingOut.value = false;
    } catch (e) {
      log.e("error signing out from firebase $e");
      isLoggingOut.value = false;
    }
  }

  setIsMyUserOver18(bool value) {
    currentUserInfo.value!.isOver18 = value;
    currentUserInfo.refresh();
  }

  Future<UserInfoModel?> getUserInfoById(String userId) async {
    Completer<UserInfoModel> completer = Completer();
    final firebaseUserDbReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.usersRef).child(userId);
    firebaseUserDbReference.once().then((event) {
      final data = event.snapshot.value as dynamic;
      if (data != null) {
        final user = singleUserParser(data);
        completer.complete(user);
      } else {
        completer.completeError("User not found");
      }
    });
    return completer.future;
  }

  Future<ReownAppKitModal?> initializeW3MService() async {
    web3ModalService = ReownAppKitModal(
      context: Get.context!,
      projectId: Env.projectId,
      logLevel: LogLevel.error,
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

    try {
      final service = await BlockChainUtils.initializewm3Service(
        web3ModalService,
        connectedWalletAddress,
        w3serviceInitialized,
      );
      return service;
    } catch (e) {
      log.f("error starting w3m service");
    }

    return null;
  }

  connectToWallet({void Function()? afterConnection}) async {
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
        log.e(e.message);
      } else {
        log.e(e);
      }
    }
  }

  disconnect() async {
    final removed = await removeUserWalletAddressOnFirebase();
    if (removed) {
      try {
        web3ModalService.disconnect();
      } catch (e) {
        log.e(e);
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
