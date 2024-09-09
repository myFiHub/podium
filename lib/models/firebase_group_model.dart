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
  String? accessType;
  String? speakerType;
  String? subject;

  static String idKey = 'id';
  static String nameKey = 'name';
  static String creatorKey = 'creator';
  static String membersKey = 'members';
  static String lowercasenameKey = 'lowercasename';
  static String accessTypeKey = 'accessType';
  static String speakerTypeKey = 'speakerType';
  static String subjectKey = 'subject';

  FirebaseGroup({
    required this.name,
    required this.id,
    required this.creator,
    required this.members,
    this.accessType,
    this.speakerType,
    this.lowercasename,
    this.subject,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[nameKey] = name;
    data[idKey] = id;
    data[creatorKey] = creator.toJson();
    data[membersKey] = members;
    data[accessTypeKey] = accessType ?? RoomAccessTypes.public;
    data[speakerTypeKey] = speakerType ?? RoomSpeakerTypes.everyone;
    data[lowercasenameKey] = lowercasename ?? name.toLowerCase();
    return data;
  }
}
