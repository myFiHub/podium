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
  bool creatorJoined = false;

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
