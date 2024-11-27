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
    final savedInternalWalletAddress =
        value[UserInfoModel.savedInternalWalletAddressKey] ?? '';
    final localWalletAddress = value[UserInfoModel.localWalletAddressKey] ?? '';
    final user = UserInfoModel(
      fullName: name,
      email: email,
      id: id,
      avatar: avatar,
      isOver18: isOver18,
      savedInternalWalletAddress: savedInternalWalletAddress,
      localWalletAddress: localWalletAddress,
      following: List.from(value[UserInfoModel.followingKey] ?? []),
      numberOfFollowers: value[UserInfoModel.numberOfFollowersKey] ?? 0,
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
