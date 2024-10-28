import 'package:firebase_database/firebase_database.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/utils/logger.dart';

mixin FirebaseTags {
  saveNewTagIfNeeded(
      {required String tag, required FirebaseGroup group}) async {
    final tagId = tag.toLowerCase();
    final databaseRef = FirebaseDatabase.instance.ref();
    final tagRef = databaseRef.child(FireBaseConstants.tags).child(tagId);
    final tagGroupIdsRef = tagRef.child(Tag.groupIdsKey);
    final currentTag = await tagRef.once();
    if (currentTag.snapshot.value == null) {
      final tmp = Tag(id: tagId, tagName: tag, groupIds: [group.id]);
      await tagRef.set(tmp.toJson());
    } else {
      final List<dynamic> groupIds =
          (currentTag.snapshot.value as dynamic)[Tag.groupIdsKey];
      final parsedGroupIds = groupIds.map((e) => e).toList().cast<String>();
      if (!parsedGroupIds.contains(group.id)) {
        parsedGroupIds.add(group.id);
        await tagGroupIdsRef.set(parsedGroupIds);
      }
    }
  }

  Future<Map<String, Tag>> searchTags(String tag) async {
    try {
      final DatabaseReference _database = FirebaseDatabase.instance.ref();
      final lowerCasedTag = tag.toLowerCase();
      final Query query = _database
          .child(FireBaseConstants.tags)
          .orderByChild(Tag.idKey)
          .startAt(lowerCasedTag)
          .endAt('$lowerCasedTag\uf8ff');
      final snapshot = await query.once();
      final tags = snapshot.snapshot.value;
      if (tags == null)
        return {};
      else {
        final parsedTags = tagsParser(tags);
        return parsedTags;
      }
    } catch (e) {
      log.e('Error searching for tags: $e');
      return {};
    }
  }
}

tagsParser(values) {
  final Map<String, Tag> parsedTags = {};
  values.forEach((key, value) {
    final groupIds = value[Tag.groupIdsKey] ?? [];
    final parsedGroupIds = groupIds.map((e) => e).toList().cast<String>();
    final tag = Tag(
      id: value[Tag.idKey],
      tagName: value[Tag.tagNameKey],
      groupIds: parsedGroupIds,
    );
    parsedTags[key] = tag;
  });
  return parsedTags;
}
