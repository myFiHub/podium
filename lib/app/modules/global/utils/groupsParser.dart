import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';

FirebaseGroup singleGroupParser(value) {
  final groupId = value[FirebaseGroup.idKey];
  final name = value[FirebaseGroup.nameKey];
  final creator = value[FirebaseGroup.creatorKey];
  final members =
      ((value[FirebaseGroup.membersKey]) as List<dynamic>).cast<String>();
  final privacyType =
      value[FirebaseGroup.privacyTypeKey] ?? RoomPrivacyTypes.public;
  final speakerType =
      value[FirebaseGroup.speakerTypeKey] ?? RoomSpeakerTypes.everyone;
  final subject = value[FirebaseGroup.subjectKey] ?? defaultSubject;
  final creatorId = creator[UserInfoModel.idKey];
  final creatorName = creator[UserInfoModel.fullNameKey];
  final creatorEmail = creator[UserInfoModel.emailKey];
  final creatorAvatar = creator[UserInfoModel.avatarUrlKey];
  final creatorUser = FirebaseGroupCreator(
    fullName: creatorName,
    email: creatorEmail,
    id: creatorId,
    avatar: creatorAvatar,
  );
  final group = FirebaseGroup(
    id: groupId,
    name: name,
    creator: creatorUser,
    members: members,
    privacyType: privacyType,
    speakerType: speakerType,
    subject: subject,
  );
  return group;
}

groupsParser(data) {
  Map<String, FirebaseGroup> groupsMap = {};

  // Iterate through the data
  data.forEach((key, value) {
    final group = singleGroupParser(value);
    groupsMap[group.id] = group;
  });
  return groupsMap;
}
