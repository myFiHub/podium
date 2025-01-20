import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/popUpsAndModals/setReminder.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/time.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/customLibs/omniDatePicker/src/enums/omni_datetime_picker_type.dart';
import 'package:podium/customLibs/omniDatePicker/src/omni_datetime_picker_dialogs.dart';
import 'package:podium/models/notification_model.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/luma/models/eventModel.dart';
import 'package:podium/providers/api/luma/models/guest.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
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
  final groupsController = Get.find<OutpostsController>();
  final GlobalController globalController = Get.find<GlobalController>();
  final isGettingMembers = false.obs;
  final forceUpdateIndicator = false.obs;
  final group = Rxn<OutpostModel>();
  final groupAccesses = Rxn<GroupAccesses>();
  final membersList = Rx<List<UserModel>>([]);
  final reminderTime = Rx<DateTime?>(null);
  final isGettingGroupInfo = false.obs;
  final jointButtonContentProps =
      Rx<JoinButtonProps>(JoinButtonProps(enabled: false, text: 'Join'));
  bool gotGroupInfo = false;

  final listOfSearchedUsersToInvite = Rx<List<UserModel>>([]);
  final liveInvitedMembers = Rx<Map<String, InvitedMember>>({});
//parameters for the group detail page
  late String stringedGroupInfo;
  late String enterAccess;
  late String speakAccess;
  late bool shouldOpenJitsiAfterJoining;

  //luma event
  final lumaEventDetails = Rxn<Luma_EventModel?>(null);
  final isGettingLumaEventDetails = false.obs;
  final isGettingLumaEventGuests = false.obs;
  final lumaEventGuests = Rx<List<GuestDataModel>>([]);
  final lumaHosts = Rx<List<Luma_HostModel>>([]);

  // end of luma event

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
      l.e('Missing parameters');
      return;
    }
    stringedGroupInfo = Get.parameters[GroupDetailsParametersKeys.groupInfo]!;
    enterAccess = Get.parameters[GroupDetailsParametersKeys.enterAccess]!;
    speakAccess = Get.parameters[GroupDetailsParametersKeys.speakAccess]!;
    shouldOpenJitsiAfterJoining = Get.parameters[
            GroupDetailsParametersKeys.shouldOpenJitsiAfterJoining] ==
        'true';

    final groupInfo = OutpostModel.fromJson(jsonDecode(stringedGroupInfo));

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
      _getLumaData();
      startListeningToGroup(groupInfo.uuid, onGroupUpdate);
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

  _getLumaData() async {
    if (group.value == null) return;
    if (group.value!.luma_event_id == null) return;
    try {
      isGettingLumaEventDetails.value = true;
      isGettingLumaEventGuests.value = true;
      final (event, guestsResponse) = await (
        HttpApis.lumaApi.getEvent(eventId: group.value!.luma_event_id!),
        HttpApis.lumaApi.getGuests(eventId: group.value!.luma_event_id!),
      ).wait;
      final guests = guestsResponse.map((e) => e.guest).toList();
      final hosts = event?.hosts ?? [];
      // filter the guests that exist in host list
      final filteredGuests = guests
          .where(
              (guest) => hosts.any((host) => host.api_id != guest.user_api_id))
          .toList();
      lumaEventDetails.value = event;
      lumaEventGuests.value = filteredGuests;
      lumaHosts.value = hosts;
    } catch (e) {
      Toast.error(message: 'Failed to get Luma event details');
      l.e(e);
    } finally {
      isGettingLumaEventDetails.value = false;
      isGettingLumaEventGuests.value = false;
    }
  }

  void forceUpdate() {
    forceUpdateIndicator.value = !forceUpdateIndicator.value;
  }

  reselectScheduleTime() async {
    DateTime? dateTime = await showOmniDateTimePicker(
      context: Get.context!,
      is24HourMode: true,
      theme: ThemeData.dark(),
      type: OmniDateTimePickerType.dateAndTime,
      firstDate: DateTime.now().add(const Duration(minutes: 5)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      minutesInterval: 5,
    );
    l.i(dateTime);
  }

  onGroupUpdate(DatabaseEvent data) {
    if (group.value == null) return;
    final newData = OutpostModel.fromJson(data.snapshot.value);
    if (newData != null) {
      if (newData.members.length != group.value!.members.length) {
        getMembers(newData);
      }
      if (newData.scheduled_for != group.value!.scheduled_for ||
          newData.creator_joined != group.value!.creator_joined ||
          newData.is_archived != group.value!.is_archived) {
        group.value = newData;
        scheduleChecks();
      }
    } else {
      Toast.error(message: 'Room is archived or deleted');
      Navigate.to(type: NavigationTypes.offAllNamed, route: Routes.HOME);
    }
  }

  scheduleChecks() async {
    final amICreator = group.value!.creator_user_uuid == myId;
    final isScheduled = group.value!.scheduled_for != 0;
    final passedScheduledTime =
        group.value!.scheduled_for < DateTime.now().millisecondsSinceEpoch;
    if (isScheduled) {
      if (passedScheduledTime) {
        if (amICreator) {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: true, text: 'Start');
        } else if (group.value!.creator_joined) {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: true, text: 'Join');
        } else {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: false, text: 'Waiting for creator');
        }
      } else {
        final reminderT = await getReminderTime(group.value!.alarm_id);
        if (reminderT != null) {
          reminderTime.value = reminderT;
        }
        if (amICreator) {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: true, text: 'Enter the Outpost');
        } else {
          final remaining = remainintTimeUntilMilSecondsFormated(
              time: group.value!.scheduled_for);
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
      groupId: group.value!.uuid,
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
    final groupsController = Get.find<OutpostsController>();
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

  getMembers(OutpostModel group) async {
    final memberIds = group.members.map((e) => e.uuid).toList();
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
            .where((element) =>
                !group.value!.members.any((e) => e.uuid == element.uuid))
            .toList();
        // // remove the users that are already invited
        // final filteredList2 = filteredList
        //     .where(
        //         (element) => !liveInvitedMemberIds.value.contains(element.id))
        //     .toList();
        // remove my user from the list
        final filteredList3 =
            filteredList.where((element) => element.uuid != myId).toList();
        listOfSearchedUsersToInvite.value = filteredList3;
      }
    });
  }

  inviteUserToJoinThisGroup(
      {required String userId, required bool inviteToSpeak}) async {
    if (group.value == null) return;
    try {
      await inviteUserToJoinGroup(
        groupId: group.value!.uuid,
        userId: userId,
        invitedToSpeak: inviteToSpeak,
      );
      await fetchInvitedMembers(userId: userId);
      final myUser = Get.find<GlobalController>().currentUserInfo.value;
      final notifId = const Uuid().v4();
      final subject = group.value!.subject;
      final invitationNotification = FirebaseNotificationModel(
        id: notifId,
        title:
            "${myUser!.name} invited you to ${inviteToSpeak ? 'speak' : 'listen'} in Outpost: ${group.value!.name}",
        body:
            "${subject != null && subject.isNotEmpty ? "talking about: " + subject : 'No subject'}",
        type: NotificationTypes.inviteToJoinGroup.toString(),
        targetUserId: userId,
        isRead: false,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        actionId: group.value!.uuid,
      );
      await sendNotification(
        notification: invitationNotification,
      );
    } catch (e) {
      l.e(e);
    }
  }
}
