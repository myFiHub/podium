import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/groupsParser.dart';
import 'package:podium/app/modules/groupDetail/controllers/group_detail_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/constants/constantConfigs.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/models/firebase_Session_model.dart';

import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:uuid/uuid.dart';

class GroupsController extends GetxController with FireBaseUtils {
  final globalController = Get.find<GlobalController>();
  final joiningGroupId = ''.obs;
  final groups = Rxn<Map<String, FirebaseGroup>>({});
  final groupsImIn = Rxn<Map<String, FirebaseGroup>>({});
  StreamSubscription<DatabaseEvent>? subscription;

  @override
  void onInit() {
    super.onInit();

    globalController.loggedIn.listen((loggedIn) {
      getRealtimeGroups(loggedIn);
    });

    groups.listen((groups) {
      if (groups != null) {
        final myUser = globalController.currentUserInfo.value!;
        final groupsImInMap = groups.entries
            .where((element) => element.value.members.contains(myUser.id))
            .toList();
        final groupsImInMapConverted = Map<String, FirebaseGroup>.fromEntries(
          groupsImInMap,
        );
        groupsImIn.value = groupsImInMapConverted;
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  getAllGroupsFromFirebase() async {
    final databaseReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.groupsRef);
    final snapShot = await databaseReference.get();
    final data = snapShot.value as Map<dynamic, dynamic>?;
    if (data != null) {
      try {
        final Map<String, FirebaseGroup> groupsMap = groupsParser(data);
        if (globalController.currentUserInfo.value != null) {
          final myUser = globalController.currentUserInfo.value!;
          final myId = myUser.id;
          groups.value = getGroupsVisibleToMe(groupsMap, myId);
        }

        // groups.value = groupsMap;
      } catch (e) {
        log.e(e);
      }
    }
  }

  getRealtimeGroups(bool loggedIn) {
    if (loggedIn) {
      final databaseReference =
          FirebaseDatabase.instance.ref(FireBaseConstants.groupsRef);
      subscription = databaseReference.onValue.listen((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          try {
            final myUser = globalController.currentUserInfo.value!;
            final myId = myUser.id;
            final groupsMap = groupsParser(data);
            groups.value = getGroupsVisibleToMe(groupsMap, myId);

            // groups.value = groupsMap;
          } catch (e) {
            log.e(e);
          }
        }
      });
    } else {
      subscription?.cancel();
    }
  }

  createGroup({
    required String name,
    required String privacyType,
    required String speakerType,
    required String subject,
  }) async {
    final newGroupId = Uuid().v4();
    final firebaseGroupsReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.groupsRef + newGroupId);
    final firebaseSessionReference = FirebaseDatabase.instance
        .ref(FireBaseConstants.sessionsRef + newGroupId);
    final myUser = globalController.currentUserInfo.value!;
    final creator = FirebaseGroupCreator(
      id: myUser.id,
      fullName: myUser.fullName,
      email: myUser.email,
      avatar: myUser.avatar,
    );
    final group = FirebaseGroup(
      id: newGroupId,
      name: name,
      creator: creator,
      accessType: privacyType,
      speakerType: speakerType,
      members: [myUser.id],
      subject: subject,
      lowercasename: name.toLowerCase(),
    );
    try {
      await firebaseGroupsReference.set(group.toJson());
      groups.value![newGroupId] = group;
      final newFirebaseSession = FirebaseSession(
        name: name,
        createdBy: myUser.id,
        id: newGroupId,
        privacyType: group.accessType,
        speakerType: group.speakerType,
        subject: group.subject,
        members: {
          myUser.id: FirebaseSessionMember(
            avatar: myUser.avatar,
            id: myUser.id,
            name: myUser.fullName,
            initialTalkTime: double.maxFinite.toInt(),
            isMuted: true,
            remainingTalkTime: double.maxFinite.toInt(),
            present: false,
          )
        },
      );
      final jsoned = newFirebaseSession.toJson();
      await firebaseSessionReference.set(jsoned);
      joinGroupAndOpenGroupDetailPage(
        groupId: newGroupId,
      );
    } catch (e) {
      deleteGroup(groupId: newGroupId);
      Get.snackbar("Error", "Failed to create group");
      log.f("Error creating group: $e");
    }
  }

  deleteGroup({required String groupId}) {
    final firebaseGroupsReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.groupsRef + groupId);
    final firebaseSessionReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.sessionsRef + groupId);
    try {
      firebaseGroupsReference.remove();
      firebaseSessionReference.remove();
      groups.value!.remove(groupId);
    } catch (e) {
      Get.snackbar("Error", "Failed to delete group");
      log.f("Error deleting group: $e");
    }
  }

  joinGroupAndOpenGroupDetailPage({
    required String groupId,
    bool? joiningByLink,
  }) async {
    if (groupId.isEmpty) return;
    final firebaseGroupsReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.groupsRef + groupId);
    final firebaseSessionsReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.sessionsRef + groupId);
    final myUser = globalController.currentUserInfo.value!;
    final group = await getGroupInfoById(groupId);
    if (group == null) {
      Get.snackbar(
        "Error",
        "Failed to join the room, seems like the room is deleted",
        colorText: Colors.red,
      );
      Navigate.to(
        type: NavigationTypes.offAllNamed,
        route: Routes.HOME,
      );
      return;
    }

    final allowedToJoin = canJoin(group: group, joiningByLink: joiningByLink);
    log.e("allowedToJoin: $allowedToJoin");
    if (!allowedToJoin) return;

    final iAmGroupCreator = group.creator.id == myUser.id;
    final members = List.from([...group.members]);
    if (!members.contains(myUser.id)) {
      members.add(myUser.id);
      try {
        joiningGroupId.value = groupId;
        await firebaseGroupsReference
            .child(FirebaseGroup.membersKey)
            .set(members);
        final mySession = await getUserSessionData(
          groupId: groupId,
          userId: myUser.id,
        );
        if (mySession == null) {
          final newFirebaseSessionMember = FirebaseSessionMember(
            avatar: myUser.avatar,
            id: myUser.id,
            name: myUser.fullName,
            initialTalkTime: iAmGroupCreator
                ? double.maxFinite.toInt()
                : SessionConstants.initialTakTime,
            isMuted: true,
            remainingTalkTime: iAmGroupCreator
                ? double.maxFinite.toInt()
                : SessionConstants.initialTakTime,
            present: false,
          );
          await firebaseSessionsReference
              .child(FirebaseSession.membersKey)
              .child(myUser.id)
              .set(newFirebaseSessionMember.toJson());
        }
        _openGroup(group: group);
      } catch (e) {
        Get.snackbar("Error", "Failed to join group");
        log.f("Error joining group: $e");
        joiningGroupId.value = '';
      }
    } else {
      joiningGroupId.value = '';
      _openGroup(group: group);
    }
  }

  _openGroup({required FirebaseGroup group}) async {
    final groupDetainController = Get.put(GroupDetailController());
    groupDetainController.group.value = group;
    joiningGroupId.value = '';
    Navigate.to(
      type: NavigationTypes.toNamed,
      route: Routes.GROUP_DETAIL,
    );
  }

  bool canJoin({required FirebaseGroup group, bool? joiningByLink}) {
    final myUser = globalController.currentUserInfo.value!;
    final iAmGroupCreator = group.creator.id == myUser.id;
    if (iAmGroupCreator ||
        group.accessType == null ||
        group.accessType == RoomAccessTypes.public) return true;
    if (group.accessType == RoomAccessTypes.onlyLink && joiningByLink == true) {
      return true;
    }
    if (group.members.contains(myUser.id)) return true;
    if (group.accessType == RoomAccessTypes.onlyLink && joiningByLink != true) {
      Get.snackbar(
        "Error",
        "This is a private room, you need an invite to join",
        colorText: Colors.red,
      );
      return false;
    }
    return false;
  }
}

getGroupsVisibleToMe(Map<String, FirebaseGroup> groups, String myId) {
  return groups;
  // final filteredGroups = groups.entries.where((element) {
  //   if (element.value.privacyType == RoomPrivacyTypes.public ||
  //       element.value.members.contains(myId)) {
  //     return true;
  //   }
  //   return false;
  // }).toList();
  // final filteredGroupsConverted = Map<String, FirebaseGroup>.fromEntries(
  //   filteredGroups,
  // );
  // return filteredGroupsConverted;
}
