import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/notification_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';
import 'package:uuid/uuid.dart';

final _deb = Debouncing(duration: const Duration(seconds: 1));

class GroupDetailController extends GetxController with FireBaseUtils {
  final groupsController = Get.find<GroupsController>();
  final isGettingMembers = false.obs;
  final group = Rxn<FirebaseGroup>();
  final membersList = Rx<List<UserInfoModel>>([]);
  final isGettingGroupInfo = false.obs;
  final listOfSearchedUsersToInvite = Rx<List<UserInfoModel>>([]);
  final liveInvitedMembers = Rx<Map<String, InvitedMember>>({});

  @override
  void onInit() {
    super.onInit();
    group.listen((group) {
      if (group != null) {
        getMembers(group);
        fetchInvitedMembers();
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

  fetchInvitedMembers({String? userId}) async {
    if (group.value == null) return;
    final map = await getInvitedMembers(
      groupId: group.value!.id,
      userId: userId,
    );
    if (userId != null) {
      map.forEach((key, value) {
        liveInvitedMembers.value[key] = value;
      });
      liveInvitedMembers.refresh();
    } else {
      liveInvitedMembers.value = map;
    }
  }

  getGroupInfo({required String id}) async {
    if (isGettingGroupInfo.value) return;
    isGettingGroupInfo.value = true;
    final globalController = Get.find<GlobalController>();
    final groupsController = Get.find<GroupsController>();
    if (globalController.loggedIn.value) {
      groupsController.joinGroupAndOpenGroupDetailPage(
        groupId: id,
      );
    } else {
      Get.offAllNamed(Routes.LOGIN);
      final loginController = Get.put(LoginController());
      loginController.afterLogin = () {
        groupsController.joinGroupAndOpenGroupDetailPage(
          groupId: id,
        );
      };
    }
    isGettingGroupInfo.value = false;
  }

  getMembers(FirebaseGroup group) async {
    final memberIds = group.members;
    isGettingMembers.value = true;
    final list = await getUsersByIds(memberIds);
    membersList.value = list;
    isGettingMembers.value = false;
  }

  startTheCall() {
    final groupCallController = Get.find<GroupCallController>();
    groupCallController.startCall(
      groupToJoin: group.value!,
    );
  }

  searchUsers(String value) async {
    _deb.debounce(() async {
      if (value.isEmpty) {
        listOfSearchedUsersToInvite.value = [];
        return;
      }
      final users = await searchForUserByName(value);
      if (value.isEmpty) {
        membersList.value = [];
      } else {
        final list = users.values.toList();
        // remove the users that are already in the group
        final filteredList = list
            .where((element) => !group.value!.members.contains(element.id))
            .toList();
        // // remove the users that are already invited
        // final filteredList2 = filteredList
        //     .where(
        //         (element) => !liveInvitedMemberIds.value.contains(element.id))
        //     .toList();
        // remove my user from the list
        final filteredList3 = filteredList
            .where((element) =>
                element.id !=
                Get.find<GlobalController>().currentUserInfo.value!.id)
            .toList();
        listOfSearchedUsersToInvite.value = filteredList3;
      }
    });
  }

  inviteUserToJoinThisGroup(
      {required String userId, required bool inviteToSpeak}) async {
    if (group.value == null) return;
    try {
      await inviteUserToJoinGroup(
        groupId: group.value!.id,
        userId: userId,
        invitedToSpeak: inviteToSpeak,
      );
      await fetchInvitedMembers(userId: userId);
      final myUser = Get.find<GlobalController>().currentUserInfo.value;
      final notifId = Uuid().v4();
      final subject = group.value!.subject;
      final invitationNotification = FirebaseNotificationModel(
        id: notifId,
        title:
            "${myUser!.fullName} invited you to ${inviteToSpeak ? 'speak' : 'listen'} in room: ${group.value!.name}",
        body:
            "${subject != null && subject.isNotEmpty ? "talking about: " + subject : 'No subject'}",
        type: NotificationTypes.inviteToJoinGroup.toString(),
        targetUserId: userId,
        isRead: false,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        actionId: group.value!.id,
      );
      await sendNotification(
        notification: invitationNotification,
      );
    } catch (e) {
      log.e(e);
    }
  }
}
