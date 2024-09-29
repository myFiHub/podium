// file hello_world.dart
import 'dart:async';

import 'package:podium/app/modules/global/utils/groupsParser.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:squadron/squadron.dart';
import 'groupsParser_squadran.activator.g.dart';
part 'groupsParser_squadran.worker.g.dart';

@SquadronService(
    baseUrl: '~/workers',
    targetPlatform: TargetPlatform.vm | TargetPlatform.web)
base class GroupsParser {
  @SquadronMethod()
  Future<Map<String, FirebaseGroup>> parseGroups(
      [dynamic data, String? myId]) async {
    Map<String, FirebaseGroup> groupsMap = {};

    data.forEach((key, value) {
      final group = singleGroupParser(value);
      if (group != null &&
          (group.archived == false || group.creator.id == myId)) {
        groupsMap[group.id] = group;
      }
    });
    return groupsMap;
  }
}
