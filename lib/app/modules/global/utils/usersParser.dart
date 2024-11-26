import 'dart:convert';

import 'package:podium/models/firebase_Internal_wallet.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';

UserInfoModel? singleUserParser(dynamic value) {
  if (value[UserInfoModel.idKey] == null) return null;
  try {
    final name = value[UserInfoModel.fullNameKey];
    final email = value[UserInfoModel.emailKey];
    final String id = value[UserInfoModel.idKey];
    final avatar = value[UserInfoModel.avatarUrlKey];
    final isOver18 = value[UserInfoModel.isOver18Key] ?? false;
    final parsed =
        jsonDecode(value[UserInfoModel.savedParticleUserInfoKey] ?? "{}");
    final wallets =
        List.from(parsed[FirebaseInternalWalletInfo.walletsKey] ?? []);
    final List<InternalWallet> walletsList = [];
    wallets.forEach((element) {
      if (element['address'] != '' && element['chain'] == 'evm_chain') {
        walletsList.add(InternalWallet.fromMap(element));
      }
    });

    final user = UserInfoModel(
      fullName: name,
      email: email,
      id: id,
      avatar: avatar,
      isOver18: isOver18,
      savedParticleWalletAddress: parsed[FirebaseInternalWalletInfo.walletsKey]
              [0][InternalWallet.addressKey] ??
          '',
      localWalletAddress: value[UserInfoModel.localWalletAddressKey] ?? '',
      following: List.from(value[UserInfoModel.followingKey] ?? []),
      numberOfFollowers: value[UserInfoModel.numberOfFollowersKey] ?? 0,
      savedParticleUserInfo: FirebaseInternalWalletInfo(
        wallets: walletsList,
        uuid: parsed[FirebaseInternalWalletInfo.uuidKey],
      ),
      lowercasename:
          value[UserInfoModel.lowercasenameKey] ?? name.toLowerCase(),
    );
    return user;
  } catch (e) {
    log.e(value[UserInfoModel.idKey] + ' is causing problem');
    log.e(e);
    return null;
  }
}

usersParser(data) {
  Map<String, UserInfoModel> usersMap = {};
  data.forEach((key, value) {
    final parsedUser = singleUserParser(value);
    if (parsedUser != null) {
      final lowercasedId = parsedUser.id.toLowerCase();
      usersMap[lowercasedId] = parsedUser;
    }
  });
  return usersMap;
}
