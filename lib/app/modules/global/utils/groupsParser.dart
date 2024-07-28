import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';

groupsParser(data) {
  Map<String, FirebaseGroup> groupsMap = {};
  // Iterate through the data
  data.forEach((key, value) {
    final groupId = value[FirebaseGroup.idKey];
    final name = value[FirebaseGroup.nameKey];
    final creator = value[FirebaseGroup.creatorKey];
    final members =
        ((value[FirebaseGroup.membersKey]) as List<dynamic>).cast<String>();
    final creatorId = creator[UserInfoModel.idKey];
    final creatorName = creator[UserInfoModel.fullNameKey];
    final creatorEmail = creator[UserInfoModel.emailKey];
    final creatorAvatar = creator[UserInfoModel.avatarUrlKey];
    final creatorUser = UserInfoModel(
      fullName: creatorName,
      email: creatorEmail,
      id: creatorId,
      avatar: creatorAvatar,
      localWalletAddress: creator[UserInfoModel.localWalletAddressKey] ?? '',
      following: creator[UserInfoModel.followingKey] ?? [],
      numberOfFollowers: creator[UserInfoModel.numberOfFollowersKey] ?? 0,
    );
    final group = FirebaseGroup(
      id: groupId,
      name: name,
      creator: creatorUser,
      members: members,
    );
    groupsMap[group.id] = group;
  });
  return groupsMap;
}
