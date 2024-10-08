import 'dart:convert';

/**
 {participantId=baed24ca, name=mohsen 2, role=moderator, avatarUrl=https://firebasestorage.googleapis.com/v0/b/podium-fbb5b.appspot.com/o/users%2FwpNKlkedLNa4oW7msPSjW0w3NA23?alt=media&token=971c5877-1010-4c4c-861b-e78f6179b509, email=aaa@aaa.aaa, isLocal=true}
 */

List<JitsiMember> convertJitsiMembersResponseToReadableJson(String res) {
  String result = res.replaceAll('api/?name=', '********************');
  result = result.replaceAll('=', '":"');
  result = result.replaceAll('********************', 'api/?name=');
  result = result.replaceAll('{', '{"');
  result = result.replaceAll('}', '"}');
  result = result.replaceAll(', ', '", "');
  result = result.replaceAll('}"', '}');
  result = result.replaceAll('"{', '{');
  result = result.replaceAll('alt":"', 'alt=');
  result = result.replaceAll('token":"', 'token=');
  final dataList = json.decode(result);
  List<JitsiMember> members = [];
  for (var item in dataList) {
    members.add(JitsiMember.fromJson(item));
  }
  return members;
}

class JitsiMember {
  late String participantId;
  late String name;
  late String role;
  late String avatarUrl;
  late String email;
  late String isLocal;

  static String participantIdKey = 'participantId';
  static String nameKey = 'name';
  static String roleKey = 'role';
  static String avatarUrlKey = 'avatarUrl';
  static String emailKey = 'email';
  static String isLocalKey = 'isLocal';

  JitsiMember({
    required this.participantId,
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.email,
    required this.isLocal,
  });

  JitsiMember.fromJson(Map<String, dynamic> json) {
    participantId = json[participantIdKey];
    name = json[nameKey];
    role = json[roleKey];
    avatarUrl = json[avatarUrlKey];
    email = json[emailKey];
    isLocal = json[isLocalKey];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[participantIdKey] = participantId;
    data[nameKey] = name;
    data[roleKey] = role;
    data[avatarUrlKey] = avatarUrl;
    data[emailKey] = email;
    data[isLocalKey] = isLocal;
    return data;
  }
}
