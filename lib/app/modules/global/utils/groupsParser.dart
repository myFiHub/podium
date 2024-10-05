import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';

import 'squads/groupsParser_squadran.dart';

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
        value[FirebaseGroup.accessTypeKey] ?? FreeRoomAccessTypes.public;
    final speakerType =
        value[FirebaseGroup.speakerTypeKey] ?? FreeRoomSpeakerTypes.everyone;
    final subject = value[FirebaseGroup.subjectKey] ?? defaultSubject;
    final creatorId = creator[UserInfoModel.idKey];
    final creatorName = creator[UserInfoModel.fullNameKey];
    final creatorEmail = creator[UserInfoModel.emailKey];
    final creatorAvatar = creator[UserInfoModel.avatarUrlKey];
    final imageUrl = value[FirebaseGroup.imageUrlKey] ?? name;
    final creatorJoined = value[FirebaseGroup.creatorJoinedKey] ?? false;
    final isArchived = value[FirebaseGroup.archivedKey] ?? false;
    final hasAdultContent = value[FirebaseGroup.hasAdultContentKey] ?? false;
    final List<String> requiredAddressesToEnter =
        (value[FirebaseGroup.requiredAddressesToEnterKey] ?? []).cast<String>();
    final List<String> requiredAddressesToSpeak =
        (value[FirebaseGroup.requiredAddressesToSpeakKey] ?? []).cast<String>();

    final ticketsRequiredToAccess =
        value[FirebaseGroup.ticketRequiredToAccessKey] ?? [];
    final parsedTicketsRequiredToAccess = ticketsRequiredToAccess
        .map((e) => UserTicket(
            userId: e[UserTicket.userIdKey],
            userAddress: e[UserTicket.userAddressKey]))
        .toList()
        .cast<UserTicket>();

    final ticketsRequiredToSpeak =
        value[FirebaseGroup.ticketsRequiredToSpeakKey] ?? [];
    final parsedTicketsRequiredToSpeak = ticketsRequiredToSpeak
        .map((e) => UserTicket(
            userId: e[UserTicket.userIdKey],
            userAddress: e[UserTicket.userAddressKey]))
        .toList()
        .cast<UserTicket>();
    final int scheduledFor = value[FirebaseGroup.scheduledForKey] ?? 0;
    final tags = value[FirebaseGroup.tagsKey] ?? [];
    final List<String> parsedTags = tags.map((e) => e).toList().cast<String>();
    final int alarmId = value[FirebaseGroup.alarmIdKey] ?? 0;

    final creatorUser = FirebaseGroupCreator(
      fullName: creatorName,
      email: creatorEmail,
      id: creatorId,
      avatar: creatorAvatar,
    );
    final group = FirebaseGroup(
      id: groupId,
      name: name,
      imageUrl: imageUrl,
      creator: creatorUser,
      members: members,
      accessType: accessType,
      speakerType: speakerType,
      subject: subject,
      invitedMembers: invitedMembers,
      creatorJoined: creatorJoined,
      archived: isArchived,
      hasAdultContent: hasAdultContent,
      requiredAddressesToEnter: requiredAddressesToEnter,
      requiredAddressesToSpeak: requiredAddressesToSpeak,
      tags: parsedTags,
      ticketsRequiredToAccess: parsedTicketsRequiredToAccess,
      ticketsRequiredToSpeak: parsedTicketsRequiredToSpeak,
      scheduledFor: scheduledFor,
      alarmId: alarmId,
    );
    return group;
  } catch (e) {
    log.e('Error parsing group: id:${groupId} $e',
        stackTrace: StackTrace.current);

    return null;
  }
}

Future<Map<String, FirebaseGroup>> groupsParser(data) async {
  final groupParserWorker = GroupsParserWorker();
  final groupsMap = await groupParserWorker.parseGroups(data, myId);
  groupParserWorker.stop();
  return groupsMap;
}
