import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/models/user_info_model.dart';

class FirebaseGroupCreator {
  String id;
  String fullName;
  String email;
  String avatar;

  FirebaseGroupCreator({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatar,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[UserInfoModel.idKey] = id;
    data[UserInfoModel.fullNameKey] = fullName;
    data[UserInfoModel.emailKey] = email;
    data[UserInfoModel.avatarUrlKey] = avatar;
    return data;
  }
}

class FirebaseGroup {
  String name;
  String? lowercasename;
  String id;
  FirebaseGroupCreator creator;
  List<String> members;
  Map<String, InvitedMember> invitedMembers = {};
  String? accessType;
  String? speakerType;
  String? subject;
  List<UserTicket> ticketsRequiredToAccess = [];
  List<UserTicket> ticketsRequiredToSpeak = [];
  List<String> requiredAddressesToEnter = [];
  List<String> requiredAddressesToSpeak = [];
  List<String> tags = [];
  bool creatorJoined = false;
  bool archived = false;
  bool hasAdultContent = false;

  static String idKey = 'id';
  static String nameKey = 'name';
  static String creatorKey = 'creator';
  static String membersKey = 'members';
  static String lowercasenameKey = 'lowercasename';
  static String accessTypeKey = 'accessType';
  static String speakerTypeKey = 'speakerType';
  static String subjectKey = 'subject';
  static String invitedMembersKey = 'invitedMembers';
  static String creatorJoinedKey = 'creatorJoined';
  static String archivedKey = 'archived';
  static String hasAdultContentKey = 'hasAdultContent';
  static String ticketRequiredToAccessKey = 'ticketsRequiredToAccess';
  static String ticketsRequiredToSpeakKey = 'ticketsRequiredToSpeak';
  static String requiredAddressesToEnterKey = 'requiredAddressesToEnter';
  static String requiredAddressesToSpeakKey = 'requiredAddressesToSpeak';
  static String tagsKey = 'tags';

  FirebaseGroup({
    required this.name,
    required this.id,
    required this.creator,
    required this.members,
    this.accessType,
    this.speakerType,
    this.lowercasename,
    this.subject,
    this.invitedMembers = const {},
    this.creatorJoined = false,
    this.archived = false,
    this.hasAdultContent = false,
    this.ticketsRequiredToAccess = const [],
    this.ticketsRequiredToSpeak = const [],
    this.requiredAddressesToEnter = const [],
    this.requiredAddressesToSpeak = const [],
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[nameKey] = name;
    data[idKey] = id;
    data[creatorKey] = creator.toJson();
    data[membersKey] = members;
    data[accessTypeKey] = accessType ?? RoomAccessTypes.public;
    data[speakerTypeKey] = speakerType ?? RoomSpeakerTypes.everyone;
    data[subjectKey] = subject ?? defaultSubject;
    data[lowercasenameKey] = lowercasename ?? name.toLowerCase();
    data[invitedMembersKey] = invitedMembers;
    data[creatorJoinedKey] = creatorJoined;
    data[archivedKey] = archived;
    data[hasAdultContentKey] = hasAdultContent;
    data[ticketRequiredToAccessKey] =
        ticketsRequiredToAccess.map((e) => e.toJson()).toList();
    data[ticketsRequiredToSpeakKey] =
        ticketsRequiredToSpeak.map((e) => e.toJson()).toList();
    data[tagsKey] = tags.map((e) => e).toList();
    data[requiredAddressesToEnterKey] = requiredAddressesToEnter;
    data[requiredAddressesToSpeakKey] = requiredAddressesToSpeak;
    return data;
  }
}

class Tag {
  String id;
  List<String>? groupIds = [];
  String tagName;

  static String idKey = 'id';
  static String tagNameKey = 'tagName';
  static String groupIdsKey = 'groupIds';

  Tag({
    required this.id,
    required this.tagName,
    this.groupIds,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[idKey] = id;
    data[tagNameKey] = tagName;
    data[groupIdsKey] = groupIds;
    return data;
  }
}

class InvitedMember {
  String id;
  bool invitedToSpeak;

  static String idKey = 'id';
  static String invitedToSpeakKey = 'invitedToSpeak';

  InvitedMember({
    required this.id,
    required this.invitedToSpeak,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[idKey] = id;
    data[invitedToSpeakKey] = invitedToSpeak;
    return data;
  }

  factory InvitedMember.fromJson(Map<String, dynamic> json) {
    return InvitedMember(
      id: json[idKey],
      invitedToSpeak: json[invitedToSpeakKey],
    );
  }
}

class UserTicket {
  String userId;
  String userAddress;

  static String userIdKey = 'userId';
  static String userAddressKey = 'userAddress';

  UserTicket({
    required this.userId,
    required this.userAddress,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[userIdKey] = userId;
    data[userAddressKey] = userAddress;
    return data;
  }

  factory UserTicket.fromJson(dynamic json) {
    return UserTicket(
      userId: json[userIdKey],
      userAddress: json[userAddressKey],
    );
  }
}
