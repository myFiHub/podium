import 'package:firebase_database/firebase_database.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/models/firebase_group_model.dart';

mixin FirebaseTags {
  saveNewTagIfNeeded({required Tag tag, required FirebaseGroup group}) async {
    final databaseRef = FirebaseDatabase.instance.ref();
    final tagGroupIdsRef =
        databaseRef.child(FireBaseConstants.tags).child(Tag.groupIdsKey);
    final res = await tagGroupIdsRef.child(Tag.nameKey).get();
    final savedTag = res.value;
    if (savedTag == null) {
      await (tagGroupIdsRef.child(Tag.nameKey).set([group.id]));
    } else {
      final List<String> groupIds = (savedTag as List<dynamic>).cast<String>();
      if (!groupIds.contains(group.id)) {
        groupIds.add(group.id);
        await (tagGroupIdsRef.child(Tag.nameKey).set(groupIds));
      }
    }
  }
}
