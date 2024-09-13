import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';

FirebaseGroup? singleGroupParser(value) {
  String groupId = '';
  try {
    groupId = value[FirebaseGroup.idKey];
    final name = value[FirebaseGroup.nameKey];
    final creator = value[FirebaseGroup.creatorKey];
    final members =
        ((value[FirebaseGroup.membersKey]) as List<dynamic>).cast<String>();
    final tmp = value[FirebaseGroup.invitedMembersKey] ?? {};
    final Map<String, InvitedMember> invitedMembers = {};
    tmp.forEach((key, value) {
      final invitedMember = InvitedMember(
        id: key,
        invitedToSpeak: value[InvitedMember.invitedToSpeakKey],
      );
      invitedMembers[key] = invitedMember;
    });
    final accessType =
        value[FirebaseGroup.accessTypeKey] ?? RoomAccessTypes.public;
    final speakerType =
        value[FirebaseGroup.speakerTypeKey] ?? RoomSpeakerTypes.everyone;
    final subject = value[FirebaseGroup.subjectKey] ?? defaultSubject;
    final creatorId = creator[UserInfoModel.idKey];
    final creatorName = creator[UserInfoModel.fullNameKey];
    final creatorEmail = creator[UserInfoModel.emailKey];
    final creatorAvatar = creator[UserInfoModel.avatarUrlKey];
    final creatorJoined = value[FirebaseGroup.creatorJoinedKey] ?? false;
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
      accessType: accessType,
      speakerType: speakerType,
      subject: subject,
      invitedMembers: invitedMembers,
      creatorJoined: creatorJoined,
    );
    return group;
  } catch (e) {
    log.e('Error parsing group: id:${groupId} $e');
    return null;
  }
}

groupsParser(data) {
  Map<String, FirebaseGroup> groupsMap = {};

  // Iterate through the data
  data.forEach((key, value) {
    final group = singleGroupParser(value);
    if (group != null) {
      groupsMap[group.id] = group;
    }
  });
  return groupsMap;
}
