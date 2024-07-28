import 'package:firebase_database/firebase_database.dart';
import 'package:podium/app/modules/global/utils/groupsParser.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/utils/logger.dart';

mixin AllGroupsFirebaseUtils {
  Future<Map<String, FirebaseGroup>> searchForGroupByName(
      String groupName) async {
    if (groupName.isEmpty) return {};
    try {
      final DatabaseReference _database = FirebaseDatabase.instance.ref();
      Query query = _database
          .child(FireBaseConstants.groupsRef)
          .orderByChild(FirebaseGroup.nameKey)
          .startAt(groupName)
          .endAt('$groupName\uf8ff');
      DataSnapshot snapshot = await query.get();
      if (snapshot.value != null) {
        try {
          return groupsParser(snapshot.value);
        } catch (e) {
          log.e(e);
          return {};
        }
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}
