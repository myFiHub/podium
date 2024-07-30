import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/lib/firebase.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/env.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/storage.dart';
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

class GlobalController extends GetxController {
  final w3serviceInitialized = false.obs;
  final connectedWalletAddress = "".obs;
  final userBalance = ''.obs;
  final connectedChainId = ''.obs;
  final firebaseUserCredential = Rxn<UserCredential>();
  final firebaseUser = Rxn<User>();
  final currentUserInfo = Rxn<UserInfoModel>();
  final activeRoute = AppPages.INITIAL.obs;
  final isAutoLoggingIn = true.obs;
  final isConnectedToInternet = true.obs;
  W3MService web3ModalService = w3mService;
  final loggedIn = false.obs;
  final initializedOnce = false.obs;

  final connectionCheckerInstance = InternetConnection.createInstance(
    checkInterval: const Duration(seconds: 5),
    customCheckOptions: [
      InternetCheckOption(uri: Uri.parse('https://one.one.one.one')),
      InternetCheckOption(uri: Uri.parse('https://icanhazip.com/')),
      InternetCheckOption(uri: Uri.parse('https://reqres.in/api/users/1')),
      InternetCheckOption(uri: Uri.parse('https://api.web3modal.com')),
    ],
    useDefaultOptions: false,
  );

  @override
  void onInit() async {
    super.onInit();
    await FirebaseInit.init();
    bool result = await connectionCheckerInstance.hasInternetAccess;
    if (result) {
      initializeApp();
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

  initializeInternetConnectionChecker() {
    connectionCheckerInstance.onStatusChange
        .listen((InternetStatus status) async {
      switch (status) {
        case InternetStatus.connected:
          isConnectedToInternet.value = true;
          log.i("Internet connected");
          if (!initializedOnce.value) {
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
      if (newAddress.isNotEmpty) {
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
    final firebaseUserDbReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.usersRef).child(userId);
    return await firebaseUserDbReference.update({
      UserInfoModel.localWalletAddressKey: walletAddress,
    });
  }

  cleanStorage() {
    final storage = GetStorage();
    storage.remove(StorageKeys.userId);
    storage.remove(StorageKeys.userAvatar);
    storage.remove(StorageKeys.userFullName);
    storage.remove(StorageKeys.userEmail);
  }

  checkLogin() async {
    isAutoLoggingIn.value = true;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    if (isLoggedIn) {
      final user = FirebaseAuth.instance.currentUser;
      firebaseUser.value = user;
      final userId = user!.uid;
      try {
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
      } catch (e) {
        isAutoLoggingIn.value = false;

        Navigate.to(
          type: NavigationTypes.offAllNamed,
          route: Routes.LOGIN,
        );
        return;
      }
    } else {
      isAutoLoggingIn.value = false;
    }
  }

  setLoggedIn(bool value) {
    loggedIn.value = value;
    if (value == false) {
      _logout();
    }
  }

  _logout() async {
    cleanStorage();
    try {
      web3ModalService.disconnect();
    } catch (e) {
      log.e("error disconnecting wallet $e");
    }
    Navigate.to(
      type: NavigationTypes.offAllNamed,
      route: Routes.LOGIN,
    );

    firebaseUserCredential.value = null;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {}
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

  connectToWallet() async {
    try {
      web3ModalService.disconnect();
      await web3ModalService.openModal(Get.context!);
      final address = BlockChainUtils.retrieveConnectedWallet(web3ModalService);
      connectedWalletAddress.value = address;
    } catch (e) {
      log.f(e);
    }
  }
}
