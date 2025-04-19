import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/popUpsAndModals/setReminder.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/showConfirmPopup.dart';
import 'package:podium/app/modules/global/utils/time.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/app/services/image_service.dart';
import 'package:podium/customLibs/omniDatePicker/omni_datetime_picker.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/luma/models/eventModel.dart';
import 'package:podium/providers/api/luma/models/guest.dart';
import 'package:podium/providers/api/podium/models/outposts/inviteRequestModel.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/outposts/updateOutpostRequest.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/services/websocket/incomingMessage.dart';
import 'package:podium/services/websocket/outgoingMessage.dart';
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
  final outpost = Rxn<OutpostModel>();
  final outpostAccesses = Rxn<GroupAccesses>();
  final membersList = Rx<List<LiveMember>>([]);
  final isGettingGroupInfo = false.obs;
  final isSettingReminder = false.obs;
  final jointButtonContentProps =
      Rx<JoinButtonProps>(JoinButtonProps(enabled: false, text: 'Join'));
  bool gotOutpostInfo = false;

  final loadingInviteId = ''.obs;

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

// image
  // final ImagePicker _picker = ImagePicker();
  // final RxBool isUploadingImage = false.obs;
  // File? selectedFile;
  // final RxString fileLocalAddress = ''.obs;

  // Inject ImageService
  final OutpostImageService imageService = Get.find();

  //end
  // end of luma event

  StreamSubscription<int>? tickerListener;

  @override
  void onInit() {
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
    membersList.value = outpostInfo.members ?? [];
    outpostAccesses.value = GroupAccesses(
      canEnter: enterAccess == 'true',
      canSpeak: speakAccess == 'true',
    );
    // final remoteGroup = await getGroupInfoById(groupId);
    outpost.value = outpostInfo;
    gotOutpostInfo = true;
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
    final outpostData = outpost.value;
    if (outpostData != null &&
        // if the creator is not joined
        !outpostData.creator_joined &&
        // if the creator is not me
        outpostData.creator_user_uuid != myId) {
      sendOutpostEvent(
        outpostId: outpostData.uuid,
        eventType: OutgoingMessageTypeEnums.wait_for_creator,
      );
    }
    super.onReady();
  }

  @override
  void onClose() {
    tickerListener?.cancel();
    super.onClose();
  }

  Future<void> setReminderForOutpost() async {
    if (isSettingReminder.value) return;
    isSettingReminder.value = true;
    final outpostData = outpost.value;
    if (outpostData == null) return;
    await setReminder(
      uuid: outpostData.uuid,
      scheduledFor: outpostData.scheduled_for,
    );
    isSettingReminder.value = false;
  }

  openRescheduleOutpostDialog() async {
    final sure = await showConfirmPopup(
      cancelText: 'Cancel',
      confirmText: 'Confirm',
      confirmColor: Colors.red,
      cancelColor: Colors.white,
      title: 'Reschedule The Outpost',
      richMessage: RichText(
        text: TextSpan(
          children: [
            const TextSpan(
              text: 'Are you sure you want to reschedule the outpost?\n\n',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            TextSpan(
              text: '⚠️ Important: ',
              style: TextStyle(
                color: Colors.orange[300],
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const TextSpan(
              text: 'The outpost will be rescheduled to the new time.\n\n',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            TextSpan(
              text: 'All existing members will be notified of this change.',
              style: TextStyle(
                color: Colors.blue[200],
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );

    if (sure) {
      DateTime? dateTime = await showOmniDateTimePicker(
        context: Get.context!,
        is24HourMode: true,
        theme: ThemeData.dark(),
        type: OmniDateTimePickerType.dateAndTime,
        firstDate: DateTime.now().add(const Duration(minutes: 5)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        minutesInterval: 5,
      );
      if (dateTime != null) {
        final newTime = dateTime.millisecondsSinceEpoch;
        final res = await HttpApis.podium.updateOutpost(
          request: UpdateOutpostRequest(
            uuid: outpost.value!.uuid,
            scheduled_for: newTime,
          ),
        );
        if (res) {
          outpost.value = outpost.value!.copyWith.scheduled_for(newTime);
          final outpostsController = Get.find<OutpostsController>();
          outpostsController.updateOutpost_local(outpost.value!);
          Toast.success(message: 'Outpost rescheduled');
        }
      }
    }
  }

  // Add updateOutpostImage method
  Future<void> updateOutpostImage(String downloadUrl) async {
    if (outpost.value == null) return;
    outpost.value = outpost.value?.copyWith.image(downloadUrl);
  }

  onCreatorJoined(IncomingMessage incomingMessage) {
    final outpostData = outpost.value;
    if (incomingMessage.data.outpost_uuid != null &&
        incomingMessage.data.outpost_uuid == outpostData?.uuid) {
      outpost.value = outpostData?.copyWith(
        creator_joined: true,
      );
      outpost.refresh();
      scheduleChecks();
    }
  }

  updatedFollowDataForMember(String uuid) async {
    final userIndex =
        membersList.value.indexWhere((element) => element.uuid == uuid);
    if (userIndex != -1) {
      final userData = membersList.value[userIndex];
      final followed_by_me = userData.followed_by_me;
      final opposite = followed_by_me != null ? !followed_by_me : true;
      membersList.value[userIndex] =
          membersList.value[userIndex].copyWith.followed_by_me(opposite);
      outpost.value = outpost.value?.copyWith(members: membersList.value);
      membersList.refresh();
      outpost.refresh();
    }
  }

  onMembersUpdated(IncomingMessage incomingMessage) {
    final outpostData = outpost.value;
    if (incomingMessage.data.outpost_uuid != null &&
        incomingMessage.data.outpost_uuid == outpostData?.uuid) {
      refetchMembers();
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
    final outpostData = outpost.value;
    if (outpostData == null) return;
    final amICreator = outpostData.creator_user_uuid == myId;
    final isScheduled = outpostData.scheduled_for != 0;
    final passedScheduledTime =
        outpostData.scheduled_for < DateTime.now().millisecondsSinceEpoch;
    if (isScheduled) {
      if (passedScheduledTime) {
        final creatorJoined = outpostData.creator_joined;
        if (amICreator) {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: true, text: 'Start');
        } else if (creatorJoined) {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: true, text: 'Join');
        } else if (!creatorJoined) {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: false, text: 'Waiting for creator');
        }
      } else {
        if (amICreator) {
          jointButtonContentProps.value =
              JoinButtonProps(enabled: true, text: 'Enter the Outpost');
        } else {
          final remaining = remainintTimeUntilMilSecondsFormated(
              time: outpostData.scheduled_for);
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

  refetchMembers() async {
    final data = outpost.value;
    if (data == null) return;
    final outpostData = await HttpApis.podium.getOutpost(data.uuid);
    if (outpostData == null) return;
    membersList.value = outpostData.members ?? [];
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
    if (loadingInviteId.value == userId + inviteToSpeak.toString()) return;
    try {
      loadingInviteId.value = userId + inviteToSpeak.toString();
      final request = InviteRequestModel(
        can_speak: inviteToSpeak,
        invitee_user_uuid: userId,
        outpost_uuid: outpost.value!.uuid,
      );
      final success = await HttpApis.podium.inviteUserToJoinOutpost(request);
      if (success) {
        Toast.success(message: 'Invite sent');
        final newMap = {
          ...liveInvitedMembers.value,
          userId: InviteModel(
            invitee_uuid: userId,
            can_speak: inviteToSpeak,
          ),
        };
        liveInvitedMembers.value = newMap;
      } else {
        Toast.error(message: 'Failed to send invite');
      }
    } catch (e) {
      l.e(e);
    } finally {
      loadingInviteId.value = '';
    }
  }
}
