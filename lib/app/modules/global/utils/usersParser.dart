import 'package:podium/app/modules/global/utils/pascalWords.dart';
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
    final evmInternalWalletAddress =
        value[UserInfoModel.evmInternalWalletAddressKey] ?? '';
    final referrer = value[UserInfoModel.referrerKey] ?? '';
    final evm_externalWalletAddress =
        value[UserInfoModel.evm_externalWalletAddressKey] ?? '';
    final internalAptosWalletAddress =
        value[UserInfoModel.aptosInternalWalletAddressKey] ?? '';
    final user = UserInfoModel(
      fullName: getPascalWords(name),
      email: email,
      id: id,
      avatar: avatar,
      isOver18: isOver18,
      referrer: referrer,
      evmInternalWalletAddress: evmInternalWalletAddress,
      aptosInternalWalletAddress: internalAptosWalletAddress,
      evm_externalWalletAddress: evm_externalWalletAddress,
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
