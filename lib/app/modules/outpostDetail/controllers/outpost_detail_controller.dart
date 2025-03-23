import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/popUpsAndModals/setReminder.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/time.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/customLibs/omniDatePicker/src/enums/omni_datetime_picker_type.dart';
import 'package:podium/customLibs/omniDatePicker/src/omni_datetime_picker_dialogs.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/luma/models/eventModel.dart';
import 'package:podium/providers/api/luma/models/guest.dart';
import 'package:podium/providers/api/podium/models/outposts/inviteRequestModel.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';

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
  static const String outpostInfo = 'outpostInfo';
}

class OutpostDetailController extends GetxController {
  final groupsController = Get.find<OutpostsController>();
  final GlobalController globalController = Get.find<GlobalController>();
  final isGettingMembers = false.obs;
  final forceUpdateIndicator = false.obs;
  final outpost = Rxn<OutpostModel>();
  final outpostAccesses = Rxn<GroupAccesses>();
  final membersList = Rx<List<UserModel>>([]);
  final reminderTime = Rx<DateTime?>(null);
  final isGettingGroupInfo = false.obs;
  final jointButtonContentProps =
      Rx<JoinButtonProps>(JoinButtonProps(enabled: false, text: 'Join'));
  bool gotGroupInfo = false;

  final listOfSearchedUsersToInvite = Rx<List<UserModel>>([]);
  final liveInvitedMembers = Rx<Map<String, InviteModel>>({});
//parameters for the group detail page
  late String stringedOutpostInfo;
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

  StreamSubscription<int>? tickerListener;

  @override
  void onInit() async {
    super.onInit();
    final params = [
      GroupDetailsParametersKeys.outpostInfo,
      GroupDetailsParametersKeys.enterAccess,
      GroupDetailsParametersKeys.speakAccess,
      GroupDetailsParametersKeys.shouldOpenJitsiAfterJoining
    ];
    if (params.any((element) => Get.parameters[element] == null)) {
      l.e('Missing parameters');
      return;
    }
    stringedOutpostInfo =
        Get.parameters[GroupDetailsParametersKeys.outpostInfo]!;
    enterAccess = Get.parameters[GroupDetailsParametersKeys.enterAccess]!;
    speakAccess = Get.parameters[GroupDetailsParametersKeys.speakAccess]!;
    shouldOpenJitsiAfterJoining = Get.parameters[
            GroupDetailsParametersKeys.shouldOpenJitsiAfterJoining] ==
        'true';

    final outpostInfo = OutpostModel.fromJson(jsonDecode(stringedOutpostInfo));

    outpostAccesses.value = GroupAccesses(
      canEnter: enterAccess == 'true',
      canSpeak: speakAccess == 'true',
    );
    // final remoteGroup = await getGroupInfoById(groupId);
    outpost.value = outpostInfo;
    gotGroupInfo = true;
    getMembers(outpostInfo);
    fetchInvitedMembers();
    scheduleChecks();
    _getLumaData();

    tickerListener = globalController.ticker.listen((event) {
      if (outpost.value != null) {
        scheduleChecks();
      }
    });
    globalController.deepLinkRoute.value = '';

    if (shouldOpenJitsiAfterJoining) {
      startTheCall(accesses: outpostAccesses.value!);
    }
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    tickerListener?.cancel();
    super.onClose();
  }

  updateSingleUser(String userId) async {
    final userInfo = await HttpApis.podium.getUserData(userId);
    if (userInfo != null) {
      final index =
          membersList.value.indexWhere((element) => element.uuid == userId);
      if (index != -1) {
        membersList.value[index] = userInfo;
        membersList.refresh();
      }
    }
  }

  _getLumaData() async {
    if (outpost.value == null) return;
    if (outpost.value!.luma_event_id == null) return;
    try {
      isGettingLumaEventDetails.value = true;
      isGettingLumaEventGuests.value = true;
      final (event, guestsResponse) = await (
        HttpApis.lumaApi.getEvent(eventId: outpost.value!.luma_event_id!),
        HttpApis.lumaApi.getGuests(eventId: outpost.value!.luma_event_id!),
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

  scheduleChecks() async {
    final amICreator = outpost.value!.creator_user_uuid == myId;
    final isScheduled = outpost.value!.scheduled_for != 0;
    final passedScheduledTime =
        outpost.value!.scheduled_for < DateTime.now().millisecondsSinceEpoch;
    if (isScheduled) {
      if (passedScheduledTime) {
        if (amICreator && jointButtonContentProps.value.text != 'Start') {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: true, text: 'Start');
        } else if (outpost.value!.creator_joined &&
            jointButtonContentProps.value.text != 'Join') {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: true, text: 'Join');
        } else if (jointButtonContentProps.value.text !=
            'Waiting for creator') {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: false, text: 'Waiting for creator');
        }
      } else {
        final reminderT = await getReminderTime(outpost.value!.alarm_id);
        if (reminderT != null) {
          reminderTime.value = reminderT;
        }
        if (amICreator) {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: true, text: 'Enter the Outpost');
        } else {
          final remaining = remainintTimeUntilMilSecondsFormated(
              time: outpost.value!.scheduled_for);
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

  fetchInvitedMembers() async {
    if (outpost.value == null) return;
    final res = await HttpApis.podium.getOutpost(outpost.value!.uuid);
    if (res == null) return;
    Map<String, InviteModel> map = {};
    (res.invites ?? []).forEach((value) {
      map[value.invitee_uuid] = value;
    });

    liveInvitedMembers.value = map;
  }

  getOutpostInfo({required String id}) async {
    if (isGettingGroupInfo.value) return;
    isGettingGroupInfo.value = true;
    final globalController = Get.find<GlobalController>();
    final groupsController = Get.find<OutpostsController>();
    if (globalController.loggedIn.value) {
      groupsController.joinOutpostAndOpenOutpostDetailPage(
        outpostId: id,
      );
    } else {
      Get.offAllNamed(Routes.LOGIN);
      final loginController = Get.put(LoginController());
      loginController.afterLogin = () {
        groupsController.joinOutpostAndOpenOutpostDetailPage(
          outpostId: id,
        );
      };
    }
    isGettingGroupInfo.value = false;
  }

  getMembers(OutpostModel outpost) async {
    try {
      final memberIds = outpost.members?.map((e) => e.uuid).toList() ?? [];
      isGettingMembers.value = true;
      final list = await HttpApis.podium.getUsersByIds(memberIds);
      final myUserIndex = list.indexWhere((m) => m.uuid == myId);
      if (myUserIndex == -1) {
        list.insert(0, myUser);
      }
      membersList.value = list;
    } catch (e) {
      l.e(e);
    } finally {
      isGettingMembers.value = false;
    }
  }

  startTheCall({required GroupAccesses accesses}) {
    final groupCallController = Get.find<OutpostCallController>();
    groupCallController.startCall(
      outpostToJoin: outpost.value!,
      accessOverRides: accesses,
    );
  }

  searchUsers(String value) async {
    _deb.debounce(() async {
      if (value.isEmpty) {
        listOfSearchedUsersToInvite.value = [];
        return;
      }
      final users = await HttpApis.podium.searchUserByName(name: value);
      if (value.isEmpty) {
        membersList.value = [];
      } else {
        final list = users.values.toList();
        // remove the users that are already in the group
        final filteredList = list
            .where((element) => !(outpost.value!.members ?? [])
                .map((e) => e.uuid)
                .contains(element.uuid))
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

  inviteUserToJoinThisOutpost(
      {required String userId, required bool inviteToSpeak}) async {
    if (outpost.value == null) return;
    try {
      final request = InviteRequestModel(
        can_speak: inviteToSpeak,
        invitee_user_uuid: userId,
        outpost_uuid: outpost.value!.uuid,
      );
      final success = await HttpApis.podium.inviteUserToJoinOutpost(request);
      if (success) {
        Toast.success(message: 'Invite sent');
      } else {
        Toast.error(message: 'Failed to send invite');
      }
    } catch (e) {
      l.e(e);
    }
  }
}
