import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/allGroups/controllers/all_groups_controller.dart';
import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/groupsParser.dart';
import 'package:podium/app/modules/groupDetail/controllers/group_detail_controller.dart';
import 'package:podium/app/modules/search/controllers/search_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/constants/constantConfigs.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_Session_model.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/analytics.dart';
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

  toggleArchive({required FirebaseGroup group}) async {
    final canContinue = await _showModalToToggleArchiveGroup(group: group);
    if (canContinue == null || canContinue == false) return;
    final archive = !group.archived;
    await toggleGroupArchive(groupId: group.id, archive: archive);
    Get.snackbar(
      "Success",
      "Group ${archive ? "archived" : "is available again"}",
      colorText: Colors.green,
    );
    final remoteGroup = await getGroupInfoById(group.id);
    if (remoteGroup != null) {
      groups.value![group.id] = remoteGroup;
      groups.refresh();
      if (Get.isRegistered<AllGroupsController>()) {
        final AllGroupsController allGroupsController = Get.find();
        allGroupsController.refreshSearchedGroup(remoteGroup);
      }
      if (Get.isRegistered<SearchPageController>()) {
        final SearchPageController searchPageController = Get.find();
        searchPageController.refreshSearchedGroup(remoteGroup);
      }
    }
    analytics.logEvent(
      name: "group_archive_toggled",
      parameters: {
        "group_id": group.id,
        "archive": archive,
      },
    );
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
          } catch (e) {
            log.e(e);
          }
        }
      });
    } else {
      subscription?.cancel();
    }
  }

  String? _extractActiveWalletAddressForUser({required UserInfoModel user}) {
    final walletAddress = user.localWalletAddress;
    if (walletAddress.isEmpty || walletAddress == null) {
      final firstParticleAddress =
          user.savedParticleUserInfo?.wallets.firstWhere(
        (w) => w.address.isNotEmpty && w.chain == 'evm_chain',
      );
      if (firstParticleAddress != null) {
        return firstParticleAddress.address;
      } else {
        return null;
      }
    }
    return walletAddress;
  }

  createGroup({
    required String name,
    required String accessType,
    required String speakerType,
    required String subject,
    required bool adultContent,
    required List<UserInfoModel> requiredTicketsToAccess,
    required List<UserInfoModel> requiredTicketsToSpeak,
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
      accessType: accessType,
      speakerType: speakerType,
      members: [myUser.id],
      subject: subject,
      hasAdultContent: adultContent,
      lowercasename: name.toLowerCase(),
      ticketsRequiredToAccess: requiredTicketsToAccess
          .map(
            (e) => UserTicket(
              userId: e.id,
              userAddress: _extractActiveWalletAddressForUser(user: e) ?? '',
            ),
          )
          .toList(),
      ticketsRequiredToSpeak: requiredTicketsToSpeak
          .map(
            (e) => UserTicket(
              userId: e.id,
              userAddress: _extractActiveWalletAddressForUser(user: e) ?? '',
            ),
          )
          .toList(),
    );
    final jsonedGroup = group.toJson();
    try {
      await firebaseGroupsReference.set(jsonedGroup);
      groups.value![newGroupId] = group;
      final newFirebaseSession = FirebaseSession(
        name: name,
        createdBy: myUser.id,
        id: newGroupId,
        accessType: group.accessType,
        speakerType: group.speakerType,
        subject: group.subject,
        members: {
          myUser.id: FirebaseSessionMember(
            avatar: myUser.avatar,
            id: myUser.id,
            isTalking: false,
            startedToTalkAt: 0,
            name: myUser.fullName,
            initialTalkTime: double.maxFinite.toInt(),
            isMuted: true,
            remainingTalkTime: double.maxFinite.toInt(),
            timeJoined: DateTime.now().millisecondsSinceEpoch,
            present: false,
          )
        },
      );
      final jsoned = newFirebaseSession.toJson();
      await firebaseSessionReference.set(jsoned);
      joinGroupAndOpenGroupDetailPage(
        groupId: newGroupId,
        openTheRoomAfterJoining: true,
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
    bool? openTheRoomAfterJoining,
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

    final allowedToJoin = await canJoin(
      group: group,
      joiningByLink: joiningByLink,
    );
    if (!allowedToJoin) return;

    final hasAgeVerified = await _showAreYouOver18Dialog(
      group: group,
      myUser: myUser,
    );
    if (!hasAgeVerified) {
      return;
    }

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
            isTalking: false,
            startedToTalkAt: 0,
            timeJoined: DateTime.now().millisecondsSinceEpoch,
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
        _openGroup(
          group: group,
          openTheRoomAfterJoining: openTheRoomAfterJoining ?? false,
        );
      } catch (e) {
        Get.snackbar("Error", "Failed to join group");
        log.f("Error joining group: $e");
        joiningGroupId.value = '';
      }
    } else {
      joiningGroupId.value = '';
      _openGroup(
        group: group,
        openTheRoomAfterJoining: openTheRoomAfterJoining ?? false,
      );
    }
  }

  _openGroup(
      {required FirebaseGroup group,
      required bool openTheRoomAfterJoining}) async {
    final groupDetainController = Get.put(GroupDetailController());
    groupDetainController.group.value = group;
    joiningGroupId.value = '';
    Navigate.to(
      type: NavigationTypes.toNamed,
      route: Routes.GROUP_DETAIL,
    );
    analytics.logEvent(
      name: "group_opened",
      parameters: {
        "group_id": group.id,
      },
    );
    if (openTheRoomAfterJoining) {
      groupDetainController.startTheCall();
    }
  }

  Future<bool> canJoin(
      {required FirebaseGroup group, bool? joiningByLink}) async {
    final myUser = globalController.currentUserInfo.value!;
    final iAmGroupCreator = group.creator.id == myUser.id;
    if (iAmGroupCreator) return true;
    if (group.archived) {
      Get.snackbar(
        "Error",
        "This group is archived, you can't join it",
        colorText: Colors.red,
      );
      return false;
    }
    if (group.members.contains(myUser.id)) return true;
    if (group.accessType == null || group.accessType == RoomAccessTypes.public)
      return true;
    if (group.accessType == RoomAccessTypes.onlyLink && joiningByLink == true) {
      return true;
    }
    if (group.accessType == RoomAccessTypes.onlyLink && joiningByLink != true) {
      Get.snackbar(
        "Error",
        "This is a private room, you need an invite link to join",
        colorText: Colors.red,
      );
      return false;
    }
    final invitedMembers = group.invitedMembers;
    if (group.accessType == RoomAccessTypes.invitees) {
      if (invitedMembers[myUser.id] != null)
        return true;
      else {
        Get.snackbar(
          "Error",
          "You are not invited to this room",
          colorText: Colors.red,
        );
      }
    }

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

  Future<bool> _showAreYouOver18Dialog({
    required FirebaseGroup group,
    required UserInfoModel myUser,
  }) async {
    final isGroupAgeRestricted = group.hasAdultContent;
    final iAmOwner = group.creator.id == myUser.id;
    final iAmMember = group.members.contains(myUser.id);
    final amIOver18 = myUser.isOver18 ?? false;
    if (iAmMember || iAmOwner || !isGroupAgeRestricted || amIOver18) {
      return true;
    }

    final result = await Get.dialog(
      AlertDialog(
        backgroundColor: ColorName.cardBackground,
        title: Text("Are you over 18?"),
        content: Text(
          "This group is for adults only, are you over 18?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(Get.overlayContext!).pop(false);
            },
            child: Text("No"),
          ),
          TextButton(
            onPressed: () {
              final over18Ref = FirebaseDatabase.instance
                  .ref(FireBaseConstants.usersRef + myUser.id)
                  .child(UserInfoModel.isOver18Key);
              over18Ref.set(true);
              globalController.setIsMyUserOver18(true);
              Navigator.of(Get.overlayContext!).pop(true);
            },
            child: Text("Yes"),
          ),
        ],
      ),
    );
    return result;
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

_showModalToToggleArchiveGroup({required FirebaseGroup group}) async {
  final isCurrentlyArchived = group.archived;
  final result = await Get.dialog(
    AlertDialog(
      backgroundColor: ColorName.cardBackground,
      title: Text("${isCurrentlyArchived ? "Un" : ""}Archive Group"),
      content: RichText(
        text: TextSpan(
          text: "Are you sure you want to ",
          children: [
            TextSpan(
              text: "${isCurrentlyArchived ? "un" : ""}archive",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: !isCurrentlyArchived ? Colors.red : Colors.green,
              ),
            ),
            TextSpan(text: " this group?"),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(false);
          },
          child: Text("No"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(true);
          },
          child: Text("Yes"),
        ),
      ],
    ),
  );
  return result;
}
