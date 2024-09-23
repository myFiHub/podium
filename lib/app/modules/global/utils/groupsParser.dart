import 'package:get/get.dart';
import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
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
    final isArchived = value[FirebaseGroup.archivedKey] ?? false;
    final hasAdultContent = value[FirebaseGroup.hasAdultContentKey] ?? false;
    final ticketsRequiredToAccess =
        value[FirebaseGroup.ticketRequiredToAccessKey] ?? [];
    final ticketsRequiredToSpeak =
        value[FirebaseGroup.ticketsRequiredToSpeakKey] ?? [];
    final parsedTicketsRequiredToAccess = ticketsRequiredToAccess
        .map((e) => UserTicket(
            userId: e[UserTicket.userIdKey],
            userAddress: e[UserTicket.userAddressKey]))
        .toList()
        .cast<UserTicket>();
    final parsedTicketsRequiredToSpeak = ticketsRequiredToSpeak
        .map((e) => UserTicket(
            userId: e[UserTicket.userIdKey],
            userAddress: e[UserTicket.userAddressKey]))
        .toList()
        .cast<UserTicket>();

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
      archived: isArchived,
      hasAdultContent: hasAdultContent,
      ticketsRequiredToAccess: parsedTicketsRequiredToAccess,
      ticketsRequiredToSpeak: parsedTicketsRequiredToSpeak,
    );
    return group;
  } catch (e) {
    log.e('Error parsing group: id:${groupId} $e');
    return null;
  }
}

groupsParser(data) {
  final globalController = Get.find<GlobalController>();
  final myId = globalController.currentUserInfo.value!.id;
  Map<String, FirebaseGroup> groupsMap = {};
  // Iterate through the data
  data.forEach((key, value) {
    final group = singleGroupParser(value);
    if (group != null &&
        (group.archived == false || group.creator.id == myId)) {
      groupsMap[group.id] = group;
    }
  });
  return groupsMap;
}
