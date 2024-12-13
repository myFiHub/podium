import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';

class FirebaseSession {
  late String name;
  late String createdBy;
  late String id;
  late Map<String, FirebaseSessionMember> members;
  late String? accessType;
  late String? speakerType;
  late String? subject;

  static String idKey = 'id';
  static String nameKey = 'name';
  static String createdByKey = 'createdBy';
  static String membersKey = 'members';
  static String accessTypeKey = 'accessType';
  static String speakerTypeKey = 'speakerType';
  static String subjectKey = 'subject';

  FirebaseSession({
    required this.name,
    required this.createdBy,
    required this.id,
    required this.members,
    this.accessType,
    this.speakerType,
    this.subject,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[nameKey] = name;
    data[createdByKey] = createdBy;
    data[subjectKey] = subject ?? defaultSubject;
    data[idKey] = id;
    data[accessTypeKey] = accessType ?? FreeGroupAccessTypes.public;
    data[speakerTypeKey] = speakerType ?? FreeGroupSpeakerTypes.everyone;
    // ignore: unnecessary_null_comparison
    if (members != null) {
      final membersList = members.values.map((v) => v.toJson()).toList();
      final mappedMembers = {};
      for (var i = 0; i < membersList.length; i++) {
        mappedMembers[membersList[i][FirebaseSessionMember.idKey]] =
            membersList[i];
      }
      data[membersKey] = mappedMembers;
    }
    return data;
  }
}

class FirebaseSessionMember {
  late String id;
  late String name;
  late String avatar;
  late int remainingTalkTime;
  late int initialTalkTime;
  late bool isMuted;
  late bool present;
  late bool isTalking = false;
  late int startedToTalkAt = 0;
  late int timeJoined = 0;

  static String idKey = 'id';
  static String nameKey = 'name';
  static String avatarKey = 'avatar';
  static String remainingTalkTimeKey = 'remainingTalkTime';
  static String initialTalkTimeKey = 'initialTalkTime';
  static String isMutedKey = 'isMuted';
  static String presentKey = 'present';
  static String isTalkingKey = 'isTalking';
  static String startedToTalkAtKey = 'startedToTalkAt';
  static String timeJoinedKey = 'timeJoined';

  FirebaseSessionMember({
    required this.id,
    required this.name,
    required this.avatar,
    required this.remainingTalkTime,
    required this.initialTalkTime,
    required this.isMuted,
    required this.present,
    required this.isTalking,
    required this.startedToTalkAt,
    required this.timeJoined,
  });

  FirebaseSessionMember.fromJson(dynamic json) {
    id = json[idKey];
    name = json[nameKey];
    avatar = json[avatarKey];
    initialTalkTime = json[initialTalkTimeKey];
    isMuted = json[isMutedKey];
    remainingTalkTime = json[remainingTalkTimeKey];
    present = json[presentKey] ?? false;
    isTalking = json[isTalkingKey] ?? false;
    startedToTalkAt = json[startedToTalkAtKey] ?? 0;
    timeJoined = json[timeJoinedKey] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[idKey] = id;
    data[nameKey] = name;
    data[avatarKey] = avatar;
    data[remainingTalkTimeKey] = remainingTalkTime;
    data[isMutedKey] = isMuted;
    data[initialTalkTimeKey] = initialTalkTime;
    // ignore: dead_null_aware_expression
    data[presentKey] = present ?? false;
    data[isTalkingKey] = isTalking;
    data[startedToTalkAtKey] = startedToTalkAt;
    data[timeJoinedKey] = timeJoined;
    return data;
  }
}
