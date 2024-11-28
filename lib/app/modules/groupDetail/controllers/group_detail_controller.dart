import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/groupsParser.dart';
import 'package:podium/app/modules/global/utils/time.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/notification_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';
import 'package:uuid/uuid.dart';

final _deb = Debouncing(duration: const Duration(seconds: 1));

class JoinButtonProps {
  final bool enabled;
  final String text;
  JoinButtonProps({required this.enabled, required this.text});
}

class GroupDetailsParametersKeys {
  static const String enterAccess = 'enterAccess';
  static const String speakAccess = 'speakAccess';
  static const String shouldOpenJitsiAfterJoining =
      'shouldOpenJitsiAfterJoining';
  static const String groupInfo = 'groupInfo';
}

class GroupDetailController extends GetxController {
  final groupsController = Get.find<GroupsController>();
  final GlobalController globalController = Get.find<GlobalController>();
  final isGettingMembers = false.obs;
  final forceUpdateIndicator = false.obs;
  final group = Rxn<FirebaseGroup>();
  final groupAccesses = Rxn<GroupAccesses>();
  final membersList = Rx<List<UserInfoModel>>([]);
  final isGettingGroupInfo = false.obs;
  final jointButtonContentProps =
      Rx<JoinButtonProps>(JoinButtonProps(enabled: false, text: 'Join'));
  bool gotGroupInfo = false;

  final listOfSearchedUsersToInvite = Rx<List<UserInfoModel>>([]);
  final liveInvitedMembers = Rx<Map<String, InvitedMember>>({});
//parameters for the group detail page
  late String stringedGroupInfo;
  late String enterAccess;
  late String speakAccess;
  late bool shouldOpenJitsiAfterJoining;

  @override
  void onInit() async {
    super.onInit();
    final params = [
      GroupDetailsParametersKeys.groupInfo,
      GroupDetailsParametersKeys.enterAccess,
      GroupDetailsParametersKeys.speakAccess,
      GroupDetailsParametersKeys.shouldOpenJitsiAfterJoining
    ];
    if (params.any((element) => Get.parameters[element] == null)) {
      log.e('Missing parameters');
      return;
    }
    stringedGroupInfo = Get.parameters[GroupDetailsParametersKeys.groupInfo]!;
    enterAccess = Get.parameters[GroupDetailsParametersKeys.enterAccess]!;
    speakAccess = Get.parameters[GroupDetailsParametersKeys.speakAccess]!;
    shouldOpenJitsiAfterJoining = Get.parameters[
            GroupDetailsParametersKeys.shouldOpenJitsiAfterJoining] ==
        'true';

    final groupInfo = singleGroupParser(jsonDecode(stringedGroupInfo));
    groupAccesses.value = GroupAccesses(
      canEnter: enterAccess == 'true',
      canSpeak: speakAccess == 'true',
    );
    // final remoteGroup = await getGroupInfoById(groupId);
    if (groupInfo != null) {
      group.value = groupInfo;
      gotGroupInfo = true;
      getMembers(groupInfo);
      fetchInvitedMembers();
      scheduleChecks();
      startListeningToGroup(groupInfo.id, onGroupUpdate);
    }

    globalController.ticker.listen((event) {
      if (group.value != null) {
        scheduleChecks();
      }
    });
    globalController.deepLinkRoute.value = '';

    if (shouldOpenJitsiAfterJoining) {
      startTheCall(accesses: groupAccesses.value!);
    }
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void forceUpdate() {
    forceUpdateIndicator.value = !forceUpdateIndicator.value;
  }

  onGroupUpdate(DatabaseEvent data) {
    if (group.value == null) return;
    final newData = singleGroupParser(data.snapshot.value);
    if (newData != null) {
      if (newData.members.length != group.value!.members.length) {
        getMembers(newData);
      }
      if (newData.scheduledFor != group.value!.scheduledFor ||
          newData.creatorJoined != group.value!.creatorJoined ||
          newData.archived != group.value!.archived) {
        group.value = newData;
        scheduleChecks();
      }
    } else {
      Toast.error(message: 'Room is archived or deleted');
      Navigate.to(type: NavigationTypes.offAllNamed, route: Routes.HOME);
    }
  }

  scheduleChecks() {
    final amICreator = group.value!.creator.id == myId;
    final isScheduled = group.value!.scheduledFor != 0;
    final passedScheduledTime =
        group.value!.scheduledFor < DateTime.now().millisecondsSinceEpoch;
    if (isScheduled) {
      if (passedScheduledTime) {
        if (amICreator) {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: true, text: 'Start');
        } else if (group.value!.creatorJoined) {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: true, text: 'Join');
        } else {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: false, text: 'Waiting for creator');
        }
      } else {
        if (amICreator) {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: true, text: 'Enter room');
        } else {
          final remaining = remainintTimeUntilMilSecondsFormated(
              time: group.value!.scheduledFor);
          jointButtonContentProps.value = JoinButtonProps(
              enabled: false,
              text: 'Scheduled for:\n ${remaining.replaceAll(' ', '')}');
        }
      }
    } else {
      if (amICreator) {
        jointButtonContentProps.value =
            JoinButtonProps(enabled: true, text: 'Start');
      } else {
        jointButtonContentProps.value =
            JoinButtonProps(enabled: true, text: 'Join');
      }
    }
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

  startTheCall({required GroupAccesses accesses}) {
    final groupCallController = Get.find<GroupCallController>();
    groupCallController.startCall(
      groupToJoin: group.value!,
      accessOverRides: accesses,
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
        final filteredList3 =
            filteredList.where((element) => element.id != myId).toList();
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
