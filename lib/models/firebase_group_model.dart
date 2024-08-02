import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';

class FirebaseGroup {
  String name;
  String id;
  UserInfoModel creator;
  List<String> members;

  static String idKey = 'id';
  static String nameKey = 'name';
  static String creatorKey = 'creator';
  static String membersKey = 'members';

  FirebaseGroup({
    required this.name,
    required this.id,
    required this.creator,
    required this.members,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[nameKey] = name;
    data[idKey] = id;
    data[creatorKey] = creator.toJson();
    data[membersKey] = members;
    return data;
  }
}
