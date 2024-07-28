class FirebaseSession {
  late String name;
  late String createdBy;
  late String id;
  late Map<String, FirebaseSessionMember> members;

  static String idKey = 'id';
  static String nameKey = 'name';
  static String createdByKey = 'createdBy';
  static String membersKey = 'members';

  FirebaseSession({
    required this.name,
    required this.createdBy,
    required this.id,
    required this.members,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[nameKey] = name;
    data[createdByKey] = createdBy;
    data[idKey] = id;
    if (members != null) {
      final membersList = members!.values.map((v) => v.toJson()).toList();
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

  static String idKey = 'id';
  static String nameKey = 'name';
  static String avatarKey = 'avatar';
  static String remainingTalkTimeKey = 'remainingTalkTime';
  static String initialTalkTimeKey = 'initialTalkTime';
  static String isMutedKey = 'isMuted';
  static String presentKey = 'present';

  FirebaseSessionMember({
    required this.id,
    required this.name,
    required this.avatar,
    required this.remainingTalkTime,
    required this.initialTalkTime,
    required this.isMuted,
    required this.present,
  });

  FirebaseSessionMember.fromJson(dynamic json) {
    id = json[idKey];
    name = json[nameKey];
    avatar = json[avatarKey];
    initialTalkTime = json[initialTalkTimeKey];
    isMuted = json[isMutedKey];
    remainingTalkTime = json[remainingTalkTimeKey];
    present = json[presentKey] ?? false;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[idKey] = id;
    data[nameKey] = name;
    data[avatarKey] = avatar;
    data[remainingTalkTimeKey] = remainingTalkTime;
    data[isMutedKey] = isMuted;
    data[initialTalkTimeKey] = initialTalkTime;
    data[presentKey] = present ?? false;
    return data;
  }
}
