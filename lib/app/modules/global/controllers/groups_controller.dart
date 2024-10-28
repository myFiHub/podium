import 'dart:async';
import 'dart:convert';

import 'package:ably_flutter/ably_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/allGroups/controllers/all_groups_controller.dart';
import 'package:podium/app/modules/chechTicket/controllers/checkTicket_controller.dart';
import 'package:podium/app/modules/chechTicket/views/checkTicket_view.dart';
import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/global/mixins/firbase_tags.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
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
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:podium/env.dart';
import 'package:podium/utils/throttleAndDebounce/throttle.dart';

final realtimeInstance = ably.Realtime(key: Env.albyApiKey);
// detect presence time (groups that were active this milliseconds ago will be considered active)
int dpt = 0;

class eventNames {
  static const String enter = "enter";
  static const String leave = "leave";
  static const String talking = "talking";
  static const String notTalking = "notTalking";
  // interactions
  static const String like = "like";
  static const String dislike = "dislike";
  static const String cheer = "cheer";
  static const String boo = "boo";
  static isInteraction(String eventName) {
    return [
      like,
      dislike,
      cheer,
      boo,
    ].contains(eventName);
  }
}

sendGroupPeresenceEvent(
    {required String groupId,
    required String eventName,
    Map<String, dynamic>? eventData}) async {
  try {
    if (dpt == 0) {
      return;
    }
    final channel = realtimeInstance.channels.get(groupId);
    if (eventName == eventNames.leave) {
      channel.presence.leave(groupId);
      return;
    }
    if (eventName == eventNames.talking || eventName == eventNames.notTalking) {
      channel.presence.update(eventName);
      return;
    } else if (eventNames.isInteraction(eventName)) {
      channel.presence.update(eventData);
      return;
    }
    if (eventName == eventNames.enter) {
      channel.presence.enter(groupId);
      return;
    }
  } catch (e) {
    log.f(e);
    analytics.logEvent(name: "send_group_presence_event_failed");
  }
}

class GroupsController extends GetxController with FirebaseTags {
  // final _presentUsersRefreshThrottle =
  //     Throttling(duration: const Duration(seconds: 2));
  // final _takingUsersRefreshThrottle =
  //     Throttling(duration: const Duration(seconds: 2));
  bool _shouldUpdatePresentUsers = false; // This is the flag you'll be checking
  late Timer _timerForPresentUsers;
  late Timer _timerForTakingUsers;
  bool _shouldUpdateTakingUsers = false;

  final globalController = Get.find<GlobalController>();
  final joiningGroupId = ''.obs;
  final groupChannels = Rx<Map<String, ably.RealtimeChannel>>({});
  final groups = Rx<Map<String, FirebaseGroup>>({});
  final presentUsersInGroupsMap = Rx<Map<String, List<String>>>({});
  final takingUsersInGroupsMap = Rx<Map<String, List<String>>>({});
  final tmpPresentUsersInGroupsMap = <String, List<String>>{};
  final tmpTakingUsersInGroupsMap = <String, List<String>>{};
  final enterListenersMap = {};
  final updateListenersMap = {};
  final leaveListenersMap = {};
  final gettingAllGroups = true.obs;
  bool initializedChannels = false;
  bool gotDetectPresenceTime = false;
  StreamSubscription<DatabaseEvent>? subscription;

  @override
  void onInit() {
    super.onInit();

    _timerForPresentUsers = Timer.periodic(Duration(seconds: 2), (timer) {
      if (_shouldUpdatePresentUsers) {
        presentUsersInGroupsMap.value = tmpPresentUsersInGroupsMap;
        presentUsersInGroupsMap.refresh();
        _shouldUpdatePresentUsers = false;
      }
    });
    _timerForTakingUsers = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_shouldUpdateTakingUsers) {
        takingUsersInGroupsMap.value = tmpTakingUsersInGroupsMap;
        takingUsersInGroupsMap.refresh();
        _shouldUpdateTakingUsers = false;
      }
    });

    realtimeInstance.connection
        .on(ably.ConnectionEvent.connected)
        .listen((ably.ConnectionStateChange stateChange) async {
      switch (stateChange.current) {
        case ably.ConnectionState.connected:
          log.d('Connected to Ably!');
          break;
        case ably.ConnectionState.failed:
          log.d('The connection to Ably failed.');
          // Failed connection
          break;
        default:
          break;
      }
    });

    globalController.loggedIn.listen((loggedIn) {
      getRealtimeGroups(loggedIn);
      if (loggedIn) {
        realtimeInstance.options.clientId = myId;
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
    subscription?.cancel();
    _timerForPresentUsers.cancel();
    _timerForTakingUsers.cancel();
  }

  toggleArchive({required FirebaseGroup group}) async {
    final canContinue = await _showModalToToggleArchiveGroup(group: group);
    if (canContinue == null || canContinue == false) return;
    final archive = !group.archived;
    await toggleGroupArchive(groupId: group.id, archive: archive);
    Toast.success(
      title: "Success",
      message: "Room ${archive ? "archived" : "is available again"}",
    );
    final remoteGroup = await getGroupInfoById(group.id);
    if (remoteGroup != null) {
      groups.value[group.id] = remoteGroup;
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
        "archive": archive.toString(),
      },
    );
  }

  final _getAllGroupsthrottle =
      Throttling(duration: const Duration(seconds: 5));
  getAllGroups() async {
    _getAllGroupsthrottle.throttle(() async {
      gettingAllGroups.value = true;
      final databaseReference =
          FirebaseDatabase.instance.ref(FireBaseConstants.groupsRef);
      final results = await databaseReference.once();
      final data = results.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        try {
          await _parseAndSetGroups(data);
        } catch (e) {
          log.e(e);
        } finally {
          gettingAllGroups.value = false;
        }
      }
    });
  }

  _parseAndSetGroups(Map<dynamic, dynamic> data) async {
    final Map<String, FirebaseGroup> groupsMap = await groupsParser(data);
    if (globalController.currentUserInfo.value != null) {
      final myUser = globalController.currentUserInfo.value!;
      final myId = myUser.id;
      final unsorted = getGroupsVisibleToMe(groupsMap, myId);
      // sort groups by last active time
      final sorted = unsorted.entries.toList()
        ..sort((a, b) {
          final aTime = a.value.lastActiveAt;
          final bTime = b.value.lastActiveAt;
          return bTime.compareTo(aTime);
        });
      final sortedMap = Map<String, FirebaseGroup>.fromEntries(sorted);
      groups.value = sortedMap;

      initializeChannels();
    }
  }

  initializeChannels() async {
    // if (initializedChannels) return;
    final groupsMap = groups.value;
    // readt detectPresenceTime from firebase
    try {
      if (!gotDetectPresenceTime) {
        final detectPresenceTimeRef =
            FirebaseDatabase.instance.ref(FireBaseConstants.detectPresenceTime);
        final detectPresenceTimeSnapshot = await detectPresenceTimeRef.once();
        final detectPresenceTime = detectPresenceTimeSnapshot.snapshot.value;
        if (detectPresenceTime != null) {
          gotDetectPresenceTime = true;
          dpt = detectPresenceTime as int;
        }
      }
    } catch (e) {}
    if (dpt == 0) {
      return;
    }
    log.d("Detect presence time: $dpt");

    final groupsThatWereActiveRecently = groupsMap.entries.where((element) {
      final group = element.value;
      final lastActiveAt = group.lastActiveAt;
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = now - lastActiveAt;
      final isActive = diff < (1 * dpt);
      if (isActive) {
        log.d(
            "Group ${group.name} was active at ${DateTime.fromMillisecondsSinceEpoch(lastActiveAt)}");
      }
      return isActive;
    }).toList();
    final currentChannels = groupChannels.value;
    groupsThatWereActiveRecently.forEach((element) {
      final groupId = element.key;
      if (currentChannels[groupId] == null) {
        final channel = realtimeInstance.channels.get(groupId);
        currentChannels[groupId] = channel;
      }
    });
    groupChannels.value = currentChannels;
    await _getCurrentNumberOfPresentUsers();
    _startListeners();
  }

  _getCurrentNumberOfPresentUsers() async {
    final allChannels = groupChannels.value;
    final List<Future<List<PresenceMessage>>> arrayToCall = [];
    allChannels.entries.forEach((element) async {
      arrayToCall.add(element.value.presence.get());
    });
    final results = await Future.wait(arrayToCall);
    final Map<String, List<String>> tmpMap = {};
    for (var i = 0; i < results.length; i++) {
      final groupId = allChannels.entries.elementAt(i).key;
      final currentPresentUsers = results[i].map((e) => e.clientId!).toList();
      tmpMap[groupId] = currentPresentUsers;
    }
    tmpPresentUsersInGroupsMap.addAll(tmpMap);
    _shouldUpdatePresentUsers = true;
  }

  _startListeners() {
    groupChannels.value.entries.forEach((element) {
      final channel = element.value;
      if (enterListenersMap[element.key] == null) {
        enterListenersMap[element.key] = element;
        channel.presence
            .subscribe(action: PresenceAction.enter)
            .listen((message) {
          _handleNewEnterMessage(groupId: element.key, message: message);
        });
      }
      if (leaveListenersMap[element.key] == null) {
        leaveListenersMap[element.key] = element;
        channel.presence
            .subscribe(action: PresenceAction.leave)
            .listen((message) {
          _handleLeaveEvent(groupId: element.key, clientId: message.clientId!);
        });
      }
      if (updateListenersMap[element.key] == null) {
        updateListenersMap[element.key] = element;
        channel.presence
            .subscribe(action: PresenceAction.update)
            .listen((message) {
          _hanldeNewUpdateMessage(groupId: element.key, message: message);
        });
      }
    });
    initializedChannels = true;
  }

  _handleNewEnterMessage(
      {required String groupId, required PresenceMessage message}) {
    final currentListForThisGroup = tmpPresentUsersInGroupsMap[groupId] ?? [];
    currentListForThisGroup.add(message.clientId!);
    tmpPresentUsersInGroupsMap[groupId] = currentListForThisGroup;
    _shouldUpdatePresentUsers = true;
  }

  _hanldeNewUpdateMessage(
      {required String groupId, required PresenceMessage message}) {
    if (message.data is String) {
      if (message.data == eventNames.talking) {
        final currentListForThisGroup =
            tmpTakingUsersInGroupsMap[groupId] ?? [];
        currentListForThisGroup.add(message.clientId!);
        tmpTakingUsersInGroupsMap[groupId] = currentListForThisGroup;
        log.d("Talking users: $currentListForThisGroup");
        _shouldUpdateTakingUsers = true;
      } else if (message.data == eventNames.notTalking) {
        final currentListForThisGroup =
            tmpTakingUsersInGroupsMap[groupId] ?? [];
        currentListForThisGroup.remove(message.clientId!);
        tmpTakingUsersInGroupsMap[groupId] = currentListForThisGroup;
        log.d("Talking users: $currentListForThisGroup");
        _shouldUpdateTakingUsers = true;
      }
    } else {
      log.d("Interaction: ${message.data}");
    }
  }

  _handleLeaveEvent({required String groupId, required String clientId}) {
    final currentListForThisGroup = tmpPresentUsersInGroupsMap[groupId] ?? [];
    if (currentListForThisGroup.contains(clientId)) {
      currentListForThisGroup.remove(clientId);
      tmpPresentUsersInGroupsMap[groupId] = currentListForThisGroup;
      _shouldUpdatePresentUsers = true;
    }
    final currentTakingListForThisGroup =
        tmpTakingUsersInGroupsMap[groupId] ?? [];
    if (currentTakingListForThisGroup.contains(clientId)) {
      currentTakingListForThisGroup.remove(clientId);
      tmpTakingUsersInGroupsMap[groupId] = currentTakingListForThisGroup;

      _shouldUpdateTakingUsers = true;
    }
  }

  List<String> getPresentUsersInGroup(String groupId) {
    return tmpPresentUsersInGroupsMap[groupId] ?? [];
  }

  getRealtimeGroups(bool loggedIn) {
    final liveThrottle = Throttling(duration: const Duration(seconds: 5));
    if (loggedIn) {
      gettingAllGroups.value = true;
      final databaseReference =
          FirebaseDatabase.instance.ref(FireBaseConstants.groupsRef);
      subscription = databaseReference.onValue.listen((event) async {
        liveThrottle.throttle(() async {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data != null) {
            try {
              await _parseAndSetGroups(data);
            } catch (e) {
              log.e(e);
            } finally {
              gettingAllGroups.value = false;
            }
          }
        });
      });
    } else {
      // subscription?.cancel();
    }
  }

  createGroup({
    required String name,
    required String id,
    required String accessType,
    required String speakerType,
    required String subject,
    required bool adultContent,
    required List<TicketSellersListMember> requiredTicketsToAccess,
    required List<TicketSellersListMember> requiredTicketsToSpeak,
    required List<String> requiredAddressesToEnter,
    required List<String> requiredAddressesToSpeak,
    required List<String> tags,
    required int scheduledFor,
    required int alarmId,
    String? imageUrl,
  }) async {
    final firebaseGroupsReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.groupsRef + id);
    final firebaseSessionReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.sessionsRef + id);
    final myUser = globalController.currentUserInfo.value!;
    final creator = FirebaseGroupCreator(
      id: myUser.id,
      fullName: myUser.fullName,
      email: myUser.email,
      avatar: myUser.avatar,
    );
    final group = FirebaseGroup(
      id: id,
      imageUrl: imageUrl,
      name: name,
      creator: creator,
      accessType: accessType,
      speakerType: speakerType,
      members: [myUser.id],
      subject: subject,
      hasAdultContent: adultContent,
      lowercasename: name.toLowerCase(),
      tags: tags.map((e) => e).toList(),
      alarmId: alarmId,
      creatorJoined: false,
      lastActiveAt: DateTime.now().millisecondsSinceEpoch,
      requiredAddressesToEnter: requiredAddressesToEnter,
      requiredAddressesToSpeak: requiredAddressesToSpeak,
      ticketsRequiredToAccess: requiredTicketsToAccess
          .map(
            (e) => UserTicket(
              userId: e.user.id,
              userAddress: e.activeAddress,
            ),
          )
          .toList(),
      ticketsRequiredToSpeak: requiredTicketsToSpeak
          .map(
            (e) => UserTicket(
              userId: e.user.id,
              userAddress: e.activeAddress,
            ),
          )
          .toList(),
      scheduledFor: scheduledFor,
    );
    final jsonedGroup = group.toJson();
    try {
      await Future.wait([
        firebaseGroupsReference.set(jsonedGroup),
        ...tags.map((tag) => saveNewTagIfNeeded(tag: tag, group: group)),
      ]);

      groups.value[id] = group;
      final newFirebaseSession = FirebaseSession(
        name: name,
        createdBy: myUser.id,
        id: id,
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
      GroupsController groupsController = Get.find();
      groupsController.groups.value.addAll(
        {id: group},
      );
      joinGroupAndOpenGroupDetailPage(
        groupId: id,
        openTheRoomAfterJoining: group.scheduledFor == 0 ||
            group.scheduledFor < DateTime.now().millisecondsSinceEpoch,
      );
      await Future.delayed(Duration(seconds: 1));
      groupsController.groups.refresh();
    } catch (e) {
      deleteGroup(groupId: id);
      Toast.error(
        title: "Error",
        message: "Failed to create room",
      );
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
      groups.value.remove(groupId);
    } catch (e) {
      Toast.error(
        title: "Error",
        message: "Failed to delete room",
      );
      log.f("Error deleting group: $e");
    }
  }

  joinGroupAndOpenGroupDetailPage({
    required String groupId,
    bool? openTheRoomAfterJoining,
    bool? joiningByLink,
  }) async {
    if (groupId.isEmpty) return;
    if (joiningGroupId != '') {
      return;
    }
    final firebaseGroupsReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.groupsRef + groupId);
    final firebaseSessionsReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.sessionsRef + groupId);
    final myUser = globalController.currentUserInfo.value!;

    final group = await getGroupInfoById(groupId);
    if (group == null) {
      Toast.error(
        title: "Error",
        message: "Failed to join the room, room not found",
      );
      Navigate.to(
        type: NavigationTypes.offAllNamed,
        route: Routes.HOME,
      );
      joiningGroupId.value = '';
      return;
    }

    final accesses = await getGroupAccesses(
      group: group,
      joiningByLink: joiningByLink,
    );
    log.d("Accesses: ${accesses.canEnter} ${accesses.canSpeak}");
    if (accesses.canEnter == false) {
      joiningGroupId.value = '';
      return;
    }

    final hasAgeVerified = await _showAreYouOver18Dialog(
      group: group,
      myUser: myUser,
    );
    if (!hasAgeVerified) {
      joiningGroupId.value = '';
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
          accesses: accesses,
        );
      } catch (e) {
        Toast.error(
          title: "Error",
          message: "Failed to join the room",
        );
        log.f("Error joining group: $e");
      } finally {
        joiningGroupId.value = '';
      }
    } else {
      joiningGroupId.value = '';
      _openGroup(
        group: group,
        openTheRoomAfterJoining: openTheRoomAfterJoining ?? false,
        accesses: accesses,
      );
    }
  }

  _openGroup({
    required FirebaseGroup group,
    required bool openTheRoomAfterJoining,
    required GroupAccesses accesses,
  }) async {
    final isAlreadyRegistered = Get.isRegistered<GroupDetailController>();
    if (isAlreadyRegistered) {
      Get.delete<GroupDetailController>();
    }

    Navigate.to(
        type: NavigationTypes.toNamed,
        route: Routes.GROUP_DETAIL,
        parameters: {
          GroupDetailsParametersKeys.enterAccess: accesses.canEnter.toString(),
          GroupDetailsParametersKeys.speakAccess: accesses.canSpeak.toString(),
          GroupDetailsParametersKeys.shouldOpenJitsiAfterJoining:
              openTheRoomAfterJoining.toString(),
          GroupDetailsParametersKeys.groupInfo: jsonEncode(group.toJson()),
        });
    analytics.logEvent(
      name: "group_opened",
      parameters: {
        "group_id": group.id,
      },
    );
  }

  Future<GroupAccesses> getGroupAccesses(
      {required FirebaseGroup group, bool? joiningByLink}) async {
    final myUser = globalController.currentUserInfo.value!;
    final iAmGroupCreator = group.creator.id == myUser.id;
    if (iAmGroupCreator) return GroupAccesses(canEnter: true, canSpeak: true);
    if (accessIsBuyableByTicket(group) || speakIsBuyableByTicket(group)) {
      final results = await checkTicket(group: group);
      if (results?.canEnter == false) {
        Toast.error(
          title: "Error",
          message: "You need a ticket to join this room",
        );
        return GroupAccesses(canEnter: false, canSpeak: false);
      } else {
        return results != null
            ? results
            : GroupAccesses(canEnter: false, canSpeak: false);
      }
    }

    if (group.archived) {
      Toast.error(
        title: "Error",
        message: "This room is archived",
      );
      return GroupAccesses(canEnter: false, canSpeak: false);
    }
    if (group.members.contains(myUser.id))
      return GroupAccesses(
          canEnter: true, canSpeak: canISpeakWithoutTicket(group: group));
    if (group.accessType == null ||
        group.accessType == FreeRoomAccessTypes.public)
      return GroupAccesses(
          canEnter: true, canSpeak: canISpeakWithoutTicket(group: group));
    if (group.accessType == FreeRoomAccessTypes.onlyLink) {
      if (joiningByLink == true) {
        return GroupAccesses(
            canEnter: true, canSpeak: canISpeakWithoutTicket(group: group));
      } else {
        Toast.error(
          title: "Error",
          message: "This is a private room, you need an invite link to join",
        );

        return GroupAccesses(canEnter: false, canSpeak: false);
      }
    }

    final invitedMembers = group.invitedMembers;
    if (group.accessType == FreeRoomAccessTypes.invitees) {
      if (invitedMembers[myUser.id] != null) {
        return GroupAccesses(
          canEnter: true,
          canSpeak: canISpeakWithoutTicket(group: group),
        );
      } else {
        Toast.error(
          title: "Error",
          message: "You need an invite to join this room",
        );
        return GroupAccesses(canEnter: false, canSpeak: false);
      }
    }

    return GroupAccesses(canEnter: false, canSpeak: false);
  }

  Future<GroupAccesses?> checkTicket({required FirebaseGroup group}) async {
    joiningGroupId.value = group.id;
    final checkTicketController = Get.put(CheckticketController());
    checkTicketController.group.value = group;
    final accesses = await checkTicketController.checkTickets();
    if (accesses.canEnter == true && accesses.canSpeak == true) {
      joiningGroupId.value = '';
      return GroupAccesses(
        canEnter: accesses.canEnter,
        canSpeak: accesses.canSpeak,
      );
    } else {
      final result = await Get.dialog<GroupAccesses?>(CheckTicketView());
      log.d(
          "Result: $result. Can enter: ${result?.canEnter}, can speak: ${result?.canSpeak}");
      Get.delete<CheckticketController>();
      joiningGroupId.value = '';
      return result;
    }
  }

  Future<bool> _showAreYouOver18Dialog({
    required FirebaseGroup group,
    required UserInfoModel myUser,
  }) async {
    final isGroupAgeRestricted = group.hasAdultContent;
    final iAmOwner = group.creator.id == myUser.id;
    final iAmMember = group.members.contains(myUser.id);
    final amIOver18 = myUser.isOver18;
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

Map<String, FirebaseGroup> getGroupsVisibleToMe(
    Map<String, FirebaseGroup> groups, String myId) {
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
      title: Text("${isCurrentlyArchived ? "Un" : ""}Archive Room"),
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
            TextSpan(text: " this Room?"),
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

class GroupAccesses {
  bool canEnter;
  bool canSpeak;
  GroupAccesses({
    required this.canEnter,
    required this.canSpeak,
  });
}
