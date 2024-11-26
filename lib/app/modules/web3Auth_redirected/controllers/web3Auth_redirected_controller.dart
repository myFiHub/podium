import 'package:get/get.dart';
import 'package:podium/models/firebase_Internal_wallet.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/loginType.dart';
import 'package:uuid/uuid.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3dart/credentials.dart';

class Web3AuthRedirectedController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() async {
    super.onReady();
    final userInfo = await Web3AuthFlutter.getUserInfo();
    final privateKey = await Web3AuthFlutter.getPrivKey();
    final ethereumKeyPair = EthPrivateKey.fromHex(privateKey);
    final publicAddress = ethereumKeyPair.address.hex;
    final uid = addressToUuid(publicAddress);

    final userToCreate = UserInfoModel(
      id: uid,
      fullName: userInfo.name ?? '',
      email: userInfo.email ?? '',
      avatar: userInfo.profileImage ?? '',
      localWalletAddress: '',
      savedParticleWalletAddress: publicAddress,
      savedParticleUserInfo: FirebaseInternalWalletInfo(
        uuid: uid,
        wallets: [
          InternalWallet(
            address: publicAddress,
            chain: 'evm_chain',
          ),
        ],
      ),
      following: [],
      numberOfFollowers: 0,
      loginType: LoginType.google,
      loginTypeIdentifier: userInfo.verifierId,
      lowercasename: userInfo.name?.toLowerCase(),
    );
  }

  @override
  void onClose() {
    super.onClose();
  }
}

addressToUuid(String address) {
  final uuid = Uuid();
  final uid = uuid.v5(Namespace.url.value, address);
  return uid;
}
