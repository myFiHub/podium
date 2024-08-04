import 'package:podium/models/user_info_model.dart';

class FirebaseGroup {
  String name;
  String? lowercasename;
  String id;
  UserInfoModel creator;
  List<String> members;

  static String idKey = 'id';
  static String nameKey = 'name';
  static String creatorKey = 'creator';
  static String membersKey = 'members';
  static String lowercasenameKey = 'lowercasename';

  FirebaseGroup({
    required this.name,
    required this.id,
    required this.creator,
    required this.members,
    this.lowercasename,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[nameKey] = name;
    data[idKey] = id;
    data[creatorKey] = creator.toJson();
    data[membersKey] = members;
    data[lowercasenameKey] = lowercasename ?? name.toLowerCase();
    return data;
  }
}
