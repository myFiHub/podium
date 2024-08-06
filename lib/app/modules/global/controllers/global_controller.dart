import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:particle_auth/particle_auth.dart' as ParticleAuth;
import 'package:particle_auth/model/user_info.dart' as ParticleUser;
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/lib/firebase.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/env.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

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

final w3mService = W3MService(
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
final _checkOptions = [
  // InternetCheckOption(uri: Uri.parse('https://one.one.one.one')),
  InternetCheckOption(uri: Uri.parse('https://api.web3modal.com')),
  InternetCheckOption(uri: Uri.parse(movementChain.rpcUrl))
];

class GlobalController extends GetxController {
  final appLifecycleState = Rx<AppLifecycleState>(AppLifecycleState.resumed);
  final w3serviceInitialized = false.obs;
  final connectedWalletAddress = "".obs;
  final userBalance = ''.obs;
  final connectedChainId = ''.obs;
  final jitsiServerAddress = '';
  final firebaseUserCredential = Rxn<UserCredential>();
  final particleAuthUserInfo = Rxn<ParticleUser.UserInfo>();
  final firebaseUser = Rxn<User>();
  final currentUserInfo = Rxn<UserInfoModel>();
  final activeRoute = AppPages.INITIAL.obs;
  final isAutoLoggingIn = true.obs;
  final isConnectedToInternet = true.obs;
  W3MService web3ModalService = w3mService;
  final loggedIn = false.obs;
  final initializedOnce = false.obs;
  final isLoggingOut = false.obs;

  final connectionCheckerInstance = InternetConnection.createInstance(
    checkInterval: const Duration(seconds: 5),
    customCheckOptions: _checkOptions,
    useDefaultOptions: false,
  );

  @override
  void onInit() async {
    super.onInit();
    // add movement chain to w3m chains, this should be the first thing to do, since it's needed all through app
    W3MChainPresets.chains.addAll({
      '30732': movementChain,
    });

    await Future.wait([
      initializeParticleAuth(),
      FirebaseInit.init(),
    ]);

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
    initializedOnce.value = true;
  }

  Future<void> initializeParticleAuth() async {
    try {
      final chainId = Env.chainId;
      final chainName = W3MChainPresets.chains[chainId]!.chainName;
      final particleChain = Env.chainId == '30732'
          ? movementChainOnParticle
          : ParticleAuth.ChainInfo.getChain(int.parse(chainId), chainName);
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
      final environment = Env.environment == DEV
          ? ParticleAuth.Env.dev
          : Env.environment == STAGE
              ? ParticleAuth.Env.staging
              : ParticleAuth.Env.production;

      log.i("##########initializing ParticleAuth");
      ParticleAuth.ParticleInfo.set(
        Env.particleProjectId,
        Env.particleClientKey,
      );
      ParticleAuth.ParticleAuth.init(
        particleChain,
        environment,
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

          if (!initializedOnce.value &&
              versionResolved &&
              serverAddress != null) {
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
      if (newAddress != '' && newAddress != null) {
        try {
          await saveUserWalletAddressOnFirebase(newAddress);
          log.d("new wallet address SAVED $newAddress");
          currentUserInfo.value!.localWalletAddress = newAddress;
          currentUserInfo.refresh();
          GetStorage().write(StorageKeys.connectedWalletAddress, newAddress);
        } catch (e) {
          log.e("error saving wallet address");
          Get.snackbar('Error', 'Error saving wallet address, try again');
        }
      }
    });
  }

  saveUserWalletAddressOnFirebase(String walletAddress) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;
    final firebaseUserDbReference = FirebaseDatabase.instance
        .ref(FireBaseConstants.usersRef)
        .child(userId + '/' + UserInfoModel.localWalletAddressKey);

    return await firebaseUserDbReference.set(walletAddress);
  }

  cleanStorage() {
    final storage = GetStorage();
    storage.remove(StorageKeys.userId);
    storage.remove(StorageKeys.userAvatar);
    storage.remove(StorageKeys.userFullName);
    storage.remove(StorageKeys.userEmail);
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
    final completer = Completer<bool>();
    final versionRef =
        FirebaseDatabase.instance.ref(FireBaseConstants.versionRef);
    // listen to version changes
    versionRef.onValue.listen((event) async {
      final data = event.snapshot.value as dynamic;
      final version = data as String?;
      if (version == null && completer.isCompleted == false) {
        log.e('version not found');
        return completer.complete(true);
      }
      final currentVersion = Env.VERSION.split('+')[0];
      if (version != currentVersion && ignoredOrAcceptedVersion != version) {
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
              TextButton(
                onPressed: () {
                  storage.write(StorageKeys.ignoredOrAcceptedVersion, version);
                  Get.back();
                  if (completer.isCompleted == false) {
                    completer.complete(true);
                  }
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
      } else {
        if (completer.isCompleted == false) {
          completer.complete(true);
        }
      }
    });
    return completer.future;
  }

  checkLogin() async {
    isAutoLoggingIn.value = true;
    try {
      final particleUserInfo = await ParticleAuth.ParticleAuth.isLoginAsync();
      particleAuthUserInfo.value = particleUserInfo;
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
    } catch (e) {
      isAutoLoggingIn.value = false;

      Navigate.to(
        type: NavigationTypes.offAllNamed,
        route: Routes.LOGIN,
      );
      return;
    }
  }

  setLoggedIn(bool value) {
    loggedIn.value = value;
    if (value == false) {
      log.f("logging out");
      _logout();
    }
  }

  _logout() async {
    isLoggingOut.value = true;
    try {
      await ParticleAuth.ParticleAuth.fastLogout();
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

  Future<UserInfoModel?> getUserInfoById(String userId) async {
    Completer<UserInfoModel> completer = Completer();
    final firebaseUserDbReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.usersRef).child(userId);
    firebaseUserDbReference.once().then((event) {
      final data = event.snapshot.value as dynamic;
      if (data != null) {
        final userId = data[UserInfoModel.idKey];
        final userFullName = data[UserInfoModel.fullNameKey];
        final userEmail = data[UserInfoModel.emailKey];
        final userAvatar = data[UserInfoModel.avatarUrlKey];
        final user = UserInfoModel(
          id: userId,
          fullName: userFullName,
          email: userEmail,
          avatar: userAvatar,
          localWalletAddress: data[UserInfoModel.localWalletAddressKey] ?? '',
          following: List.from(data[UserInfoModel.followingKey] ?? []),
          numberOfFollowers: data[UserInfoModel.numberOfFollowersKey] ?? 0,
        );
        completer.complete(user);
      } else {
        completer.completeError("User not found");
      }
    });
    return completer.future;
  }

  Future<W3MService?> initializeW3MService() async {
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
      await web3ModalService.openModal(Get.context!);
      final address = BlockChainUtils.retrieveConnectedWallet(web3ModalService);
      connectedWalletAddress.value = address;
      if (afterConnection != null && address != '') {
        afterConnection();
      }
    } catch (e) {
      if (e is W3MServiceException) {
        log.e(e.message);
      } else {
        log.e(e);
      }
    }
  }
}
