import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';

usersParser(data) {
  Map<String, UserInfoModel> usersMap = {};
  // Iterate through the data
  data.forEach((key, value) {
    if (value[UserInfoModel.idKey] == null) return;
    try {
      final name = value[UserInfoModel.fullNameKey];
      final email = value[UserInfoModel.emailKey];
      final String id = value[UserInfoModel.idKey];
      final avatar = value[UserInfoModel.avatarUrlKey];
      final user = UserInfoModel(
        fullName: name,
        email: email,
        id: id,
        avatar: avatar,
        localWalletAddress: value[UserInfoModel.localWalletAddressKey] ?? '',
        following: List.from(value[UserInfoModel.followingKey] ?? []),
        numberOfFollowers: value[UserInfoModel.numberOfFollowersKey] ?? 0,
        lowercasename:
            value[UserInfoModel.lowercasenameKey] ?? name.toLowerCase(),
      );
      final lowercasedId = id.toLowerCase();
      usersMap[lowercasedId] = user;
    } catch (e) {
      log.e(e);
    }
  });
  return usersMap;
}
