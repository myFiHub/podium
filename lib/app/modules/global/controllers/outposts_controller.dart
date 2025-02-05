import 'dart:async';
import 'dart:convert';

import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:ably_flutter/ably_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/allOutposts/controllers/all_outposts_controller.dart';
import 'package:podium/app/modules/checkTicket/controllers/checkTicket_controller.dart';
import 'package:podium/app/modules/checkTicket/views/checkTicket_view.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/mixins/firbase_tags.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/outpostDetail/controllers/outpost_detail_controller.dart';
import 'package:podium/app/modules/search/controllers/search_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/constants/constantConfigs.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_Session_model.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/outposts/createOutpostRequest.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
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
    l.f(e);
    analytics.logEvent(name: "send_group_presence_event_failed");
  }
}

class OutpostsController extends GetxController with FirebaseTags {
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
  final outposts = Rx<Map<String, OutpostModel>>({});
  final presentUsersInGroupsMap = Rx<Map<String, List<String>>>({});
  final takingUsersInGroupsMap = Rx<Map<String, List<String>>>({});
  final tmpPresentUsersInGroupsMap = <String, List<String>>{};
  final tmpTakingUsersInGroupsMap = <String, List<String>>{};
  final enterListenersMap = {};
  final updateListenersMap = {};
  final leaveListenersMap = {};
  final gettingAllOutposts = true.obs;
  bool initializedChannels = false;
  bool gotDetectPresenceTime = false;
  StreamSubscription<DatabaseEvent>? subscription;

  @override
  void onInit() {
    super.onInit();

    _timerForPresentUsers = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_shouldUpdatePresentUsers) {
        presentUsersInGroupsMap.value = tmpPresentUsersInGroupsMap;
        presentUsersInGroupsMap.refresh();
        _shouldUpdatePresentUsers = false;
      }
    });
    _timerForTakingUsers = Timer.periodic(const Duration(seconds: 1), (timer) {
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
          l.d('Connected to Ably!');
          break;
        case ably.ConnectionState.failed:
          l.d('The connection to Ably failed.');
          // Failed connection
          break;
        default:
          break;
      }
    });

    globalController.loggedIn.listen((loggedIn) {
      getRealtimeOutposts(loggedIn);
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

  getPresentUsersInGroup(String groupId) {
    return tmpPresentUsersInGroupsMap[groupId] ?? [];
  }

  Future<void> removeMyUserFromSessionAndGroup(
      {required OutpostModel outpost}) async {
    // ask if user want to leave the group
    try {
      final canContinue = await _showModalToLeaveGroup(outpost: outpost);
      if (canContinue == null || canContinue == false) return;
      await removeMyUserFromGroupAndSession(groupId: outpost.uuid);
      // remove group from groups list
      outposts.value.remove(outpost.uuid);
      outposts.refresh();
      if (Get.isRegistered<AllOutpostsController>()) {
        final AllOutpostsController allGroupsController = Get.find();
        allGroupsController.searchedOutposts.refresh();
      }
      if (Get.isRegistered<SearchPageController>()) {
        final SearchPageController searchPageController = Get.find();
        searchPageController.searchedOutposts.refresh();
      }
    } catch (e) {
      l.e(e);
    }
  }

  Future<void> toggleArchive({required OutpostModel outpost}) async {
    final canContinue = await _showModalToToggleArchiveGroup(outpost: outpost);
    if (canContinue == null || canContinue == false) return;
    final archive = !outpost.is_archived;

    final response =
        await HttpApis.podium.toggleOutpostArchive(outpost.uuid, archive);

    Toast.success(
      title: "Success",
      message: "Outpost ${archive ? "archived" : "is available again"}",
    );
    final remoteOutpost = await HttpApis.podium.getOutpost(outpost.uuid);
    if (remoteOutpost != null) {
      outposts.value[outpost.uuid] = remoteOutpost;
      outposts.refresh();
      if (Get.isRegistered<AllOutpostsController>()) {
        final AllOutpostsController allGroupsController = Get.find();
        // allGroupsController.refreshSearchedGroup(remoteOutpost); //TODO: implement this
      }
      if (Get.isRegistered<SearchPageController>()) {
        final SearchPageController searchPageController = Get.find();
        // searchPageController.refreshSearchedGroup(remoteOutpost); //TODO: implement this
      }
    }
    analytics.logEvent(
      name: "group_archive_toggled",
      parameters: {
        "outpost_id": outpost.uuid,
        "archive": archive.toString(),
      },
    );
  }

  final _getAllGroupsthrottle =
      Throttling(duration: const Duration(seconds: 5));
  getAllOutposts() async {
    _getAllGroupsthrottle.throttle(() async {
      gettingAllOutposts.value = true;
      final outposts = await HttpApis.podium.getOutposts();
      final Map<String, OutpostModel> map = {};
      for (var outpost in outposts) {
        map[outpost.uuid] = outpost;
      }
      try {
        await _parseAndSetGroups(map);
      } catch (e) {
        l.e(e);
      } finally {
        gettingAllOutposts.value = false;
      }
    });
  }

  _parseAndSetGroups(Map<String, OutpostModel> data) async {
    if (globalController.myUserInfo.value != null) {
      final myUser = globalController.myUserInfo.value!;
      final myId = myUser.uuid;
      final unsorted = getOutpostsVisibleToMe(data, myId);
      // sort groups by last active time
      final sorted = unsorted.entries.toList()
        ..sort((a, b) {
          final aTime = a.value.last_active_at;
          final bTime = b.value.last_active_at;
          return bTime.compareTo(aTime);
        });
      final sortedMap = Map<String, OutpostModel>.fromEntries(sorted);
      outposts.value = sortedMap;
      initializeChannels();
    }
  }

  initializeChannels() async {
    // if (initializedChannels) return;
    final groupsMap = outposts.value;
    // readt detectPresenceTime from firebase
    try {
      if (!gotDetectPresenceTime) {
        final detectPresenceTimeRef =
            FirebaseDatabase.instance.ref(FireBaseConstants.detectPresenceTime);
        final detectPresenceTimeSnapshot = await detectPresenceTimeRef.get();
        final detectPresenceTime = detectPresenceTimeSnapshot.value;
        if (detectPresenceTime != null) {
          gotDetectPresenceTime = true;
          dpt = detectPresenceTime as int;
        }
      }
    } catch (e) {}
    if (dpt == 0) {
      return;
    }
    l.d("Detect presence time: $dpt");

    final groupsThatWereActiveRecently = groupsMap.entries.where((element) {
      final group = element.value;
      final lastActiveAt = group.last_active_at;
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = now - lastActiveAt;
      final isActive = diff < (1 * dpt) && group.is_archived != true;
      if (isActive) {
        l.d("Group ${group.name} was active at ${DateTime.fromMillisecondsSinceEpoch(lastActiveAt)}");
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
        l.d("Talking users: $currentListForThisGroup");
        _shouldUpdateTakingUsers = true;
      } else if (message.data == eventNames.notTalking) {
        final currentListForThisGroup =
            tmpTakingUsersInGroupsMap[groupId] ?? [];
        currentListForThisGroup.remove(message.clientId!);
        tmpTakingUsersInGroupsMap[groupId] = currentListForThisGroup;
        l.d("Talking users: $currentListForThisGroup");
        _shouldUpdateTakingUsers = true;
      }
    } else {
      l.d("Interaction: ${message.data}");
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

  getRealtimeOutposts(bool loggedIn) async {
    final liveThrottle = Throttling(duration: const Duration(seconds: 5));
    if (loggedIn) {
      gettingAllOutposts.value = true;
      try {
        final response = await HttpApis.podium.getOutposts(
          page: 0,
          page_size: 200,
        );
        final Map<String, OutpostModel> map = {};
        for (var outpost in response) {
          map[outpost.uuid] = outpost;
        }
        outposts.value = map;
      } catch (e) {
      } finally {
        gettingAllOutposts.value = false;
      }
      // final databaseReference =
      //     FirebaseDatabase.instance.ref(FireBaseConstants.groupsRef);
      // subscription = databaseReference.onValue.listen((event) async {
      //   liveThrottle.throttle(() async {
      //     final data = event.snapshot.value as Map<dynamic, dynamic>?;
      //     if (data != null) {
      //       try {
      //         await _parseAndSetGroups(data);
      //       } catch (e) {
      //         l.e(e);
      //       } finally {
      //         gettingAllGroups.value = false;
      //       }
      //     }
      //   });
      // });
    } else {
      // subscription?.cancel();
    }
  }

  Future<OutpostModel?> createOutpost({
    required String name,
    required String id,
    required String accessType,
    required String speakerType,
    required String subject,
    required bool recordable,
    required bool adultContent,
    required List<TicketSellersListMember> requiredTicketsToAccess,
    required List<TicketSellersListMember> requiredTicketsToSpeak,
    required List<String> requiredAddressesToEnter,
    required List<String> requiredAddressesToSpeak,
    required List<String> tags,
    required int scheduledFor,
    String? lumaEventId,
    String? imageUrl,
  }) async {
    final accessAddresses = [
      ...requiredAddressesToEnter.map((e) => e).toList(),
      ...requiredTicketsToAccess.map((e) => e.activeAddress).toList(),
    ];
    final speakAddresses = [
      ...requiredAddressesToSpeak.map((e) => e).toList(),
      ...requiredTicketsToSpeak.map((e) => e.activeAddress).toList(),
    ];

    final createOutpostRequest = CreateOutpostRequest(
      enter_type: accessType,
      has_adult_content: adultContent,
      image: imageUrl ?? '',
      is_recordable: recordable,
      luma_event_id: lumaEventId,
      name: name,
      scheduled_for: scheduledFor,
      speak_type: speakerType,
      subject: subject,
      tags: tags,
      tickets_to_enter: accessAddresses,
      tickets_to_speak: speakAddresses,
    );
    try {
      final response = await HttpApis.podium.createOutpost(
        createOutpostRequest,
      );

      return response;
    } catch (e) {
      return null;
    }
    // final firebaseGroupsReference =
    //     FirebaseDatabase.instance.ref(FireBaseConstants.groupsRef + id);
    // final firebaseSessionReference =
    //     FirebaseDatabase.instance.ref(FireBaseConstants.sessionsRef + id);
    // final myUser = globalController.myUserInfo.value!;
    // final creator = FirebaseGroupCreator(
    //   id: myUser.uuid,
    //   fullName: myUser.name ?? '',
    //   email: myUser.email ?? '',
    //   avatar: myUser.image ?? '',
    // );
    // final group = FirebaseGroup(
    //   id: id,
    //   lumaEventId: lumaEventId,
    //   imageUrl: imageUrl,
    //   name: name,
    //   creator: creator,
    //   accessType: accessType,
    //   speakerType: speakerType,
    //   members: {myUser.uuid: myUser.uuid},
    //   subject: subject,
    //   hasAdultContent: adultContent,
    //   isRecordable: recordable,
    //   lowercasename: name.toLowerCase(),
    //   tags: tags.map((e) => e).toList(),
    //   alarmId: alarmId,
    //   creatorJoined: false,
    //   lastActiveAt: DateTime.now().millisecondsSinceEpoch,
    //   requiredAddressesToEnter: requiredAddressesToEnter,
    //   requiredAddressesToSpeak: requiredAddressesToSpeak,
    //   ticketsRequiredToAccess: requiredTicketsToAccess
    //       .map(
    //         (e) => UserTicket(
    //           userId: e.user.id,
    //           userAddress: e.activeAddress,
    //         ),
    //       )
    //       .toList(),
    //   ticketsRequiredToSpeak: requiredTicketsToSpeak
    //       .map(
    //         (e) => UserTicket(
    //           userId: e.user.id,
    //           userAddress: e.activeAddress,
    //         ),
    //       )
    //       .toList(),
    //   scheduledFor: scheduledFor,
    // );
    // final jsonedGroup = group.toJson();
    // try {
    //   await Future.wait([
    //     firebaseGroupsReference.set(jsonedGroup),
    //     ...tags.map((tag) => saveNewTagIfNeeded(tag: tag, group: group)),
    //   ]);

    //   groups.value[id] = group;
    //   final newFirebaseSession = FirebaseSession(
    //     name: name,
    //     createdBy: myUser.uuid,
    //     id: id,
    //     accessType: group.accessType,
    //     speakerType: group.speakerType,
    //     subject: group.subject,
    //     members: {
    //       // myUser.uuid: createInitialSessionMember(user: myUser, group: group)!
    //     },
    //   );
    //   final jsoned = newFirebaseSession.toJson();
    //   await firebaseSessionReference.set(jsoned);
    //   GroupsController groupsController = Get.find();
    //   groupsController.groups.value.addAll(
    //     {id: group},
    //   );
    //   joinGroupAndOpenGroupDetailPage(
    //     groupId: id,
    //     openTheRoomAfterJoining: group.scheduledFor == 0 ||
    //         group.scheduledFor < DateTime.now().millisecondsSinceEpoch,
    //   );
    //   await Future.delayed(const Duration(seconds: 1));
    //   groupsController.groups.refresh();
    // } catch (e) {
    //   deleteGroup(groupId: id);
    //   Toast.error(
    //     title: "Error",
    //     message: "Failed to create the Outpost",
    //   );
    //   l.f("Error creating group: $e");
    // }
  }

  deleteGroup({required String groupId}) {
    final firebaseGroupsReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.groupsRef + groupId);
    final firebaseSessionReference =
        FirebaseDatabase.instance.ref(FireBaseConstants.sessionsRef + groupId);
    try {
      firebaseGroupsReference.remove();
      firebaseSessionReference.remove();
      outposts.value.remove(groupId);
    } catch (e) {
      Toast.error(
        title: "Error",
        message: "Failed to delete room",
      );
      l.f("Error deleting group: $e");
    }
  }

  joinGroupAndOpenGroupDetailPage({
    required String outpostId,
    bool? openTheRoomAfterJoining,
    bool? joiningByLink,
  }) async {
    if (outpostId.isEmpty) return;
    if (joiningGroupId != '') {
      return;
    }
    try {
      joiningGroupId.value = outpostId;
      final outpost = await HttpApis.podium.getOutpost(outpostId);
      if (outpost == null) {
        Toast.error(
          title: "Error",
          message: "Failed to join the Outpost, Outpost not found",
        );
        Navigate.to(
          type: NavigationTypes.offAllNamed,
          route: Routes.HOME,
        );
        return;
      }

      final accesses = await getOutpostAccesses(
        outpost: outpost,
        joiningByLink: joiningByLink,
      );
      l.d("Accesses: ${accesses.canEnter} ${accesses.canSpeak}");
      if (accesses.canEnter == false) {
        joiningGroupId.value = '';
        return;
      }
      final hasAgeVerified = await _showAreYouOver18Dialog(
        outpost: outpost,
        myUser: myUser,
      );
      if (!hasAgeVerified) {
        joiningGroupId.value = '';
        return;
      }

      if (!outpost.iAmMember) {
        final added = await HttpApis.podium.addMeAsMember(outpostId: outpostId);
        if (!added) {
          Toast.error(
            title: "Error",
            message: "Failed to join the Outpost, try again or report a bug",
          );
          return;
        }
        // TODO: add session
        // final mySession = await getUserSessionData(
        //   groupId: outpostId,
        //   userId: myUser.uuid,
        // );
        // if (mySession == null) {
        // final newFirebaseSessionMember =
        //     createInitialSessionMember(user: myUser, group: group)!;
        // try {
        //   final jsoned = newFirebaseSessionMember.toJson();
        //   await firebaseSessionsReference
        //       .child(FirebaseSession.membersKey)
        //       .child(myUser.uuid)
        //       .set(jsoned);
        // } catch (e) {
        //   // remove user from db
        //   await firebaseSessionsReference
        //       .child(FirebaseSession.membersKey)
        //       .child(myUser.uuid)
        //       .remove();
        //   Toast.error(
        //     title: "Error",
        //     message: "Failed to join the Outpost, try again or report a bug",
        //   );
        //   return;
        // }
        // }
        _openOutpost(
          outpost: outpost,
          openTheRoomAfterJoining: openTheRoomAfterJoining ?? false,
          accesses: accesses,
        );
      } else {
        l.d("Already a member");
        _openOutpost(
          outpost: outpost,
          openTheRoomAfterJoining: openTheRoomAfterJoining ?? false,
          accesses: accesses,
        );
      }
    } catch (e) {
      Toast.error(
        title: "Error",
        message: "Failed to join the Outpost,please try again or report a bug",
      );
      l.f("Error joining group: $e");
    } finally {
      joiningGroupId.value = '';
    }

    return;
  }

  FirebaseSessionMember? createInitialSessionMember(
      {required UserInfoModel user, required FirebaseGroup group}) {
    try {
      final iAmGroupCreator = group.creator.id == user.id;
      final member = FirebaseSessionMember(
        avatar: user.avatar,
        id: user.id,
        name: user.fullName,
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
      return member;
    } catch (e) {
      l.e(e);
      return null;
    }
  }

  _openOutpost({
    required OutpostModel outpost,
    required bool openTheRoomAfterJoining,
    required GroupAccesses accesses,
  }) async {
    final isAlreadyRegistered = Get.isRegistered<OutpostDetailController>();
    if (isAlreadyRegistered) {
      Get.delete<OutpostDetailController>();
    }

    Navigate.to(
        type: NavigationTypes.toNamed,
        route: Routes.OUTPOST_DETAIL,
        parameters: {
          GroupDetailsParametersKeys.enterAccess: accesses.canEnter.toString(),
          GroupDetailsParametersKeys.speakAccess: accesses.canSpeak.toString(),
          GroupDetailsParametersKeys.shouldOpenJitsiAfterJoining:
              openTheRoomAfterJoining.toString(),
          GroupDetailsParametersKeys.outpostInfo: jsonEncode(outpost.toJson()),
        });
    analytics.logEvent(
      name: "outpost_opened",
      parameters: {
        "outpost_id": outpost.uuid,
      },
    );
  }

  Future<GroupAccesses?> _checkLumaAccess(
      {required OutpostModel outpost}) async {
    try {
      if (outpost.luma_event_id != null && outpost.luma_event_id!.isNotEmpty) {
        final myLoginType = myUser.login_type;
        if (myLoginType != null) {
          if (myLoginType.contains('google') || myLoginType.contains('email')) {
            final myEmail = myUser.email;
            final (guests, event) = await (
              HttpApis.lumaApi.getGuests(eventId: outpost.luma_event_id!),
              HttpApis.lumaApi.getEvent(eventId: outpost.luma_event_id!)
            ).wait;
            final guestsList = guests.map((e) => e.guest).toList();
            final hostsList = event?.hosts ?? [];
            final guestEmails = guestsList.map((e) => e.user_email).toList();
            final hostsEmails = hostsList.map((e) => e.email).toList();
            final isGuest = guestEmails.contains(myEmail);
            final isHost = hostsEmails.contains(myEmail);
            if (isGuest || isHost) {
              return GroupAccesses(canEnter: true, canSpeak: true);
            }
          }
        }
      }
      return null;
    } catch (e) {
      l.e(e);
      return null;
    }
  }

  Future<GroupAccesses> getOutpostAccesses(
      {required OutpostModel outpost, bool? joiningByLink}) async {
    final myUser = globalController.myUserInfo.value!;
    final iAmGroupCreator = outpost.creator_user_uuid == myUser.uuid;
    if (iAmGroupCreator) return GroupAccesses(canEnter: true, canSpeak: true);
    final lumaAccessResponse = await _checkLumaAccess(outpost: outpost);
    if (lumaAccessResponse != null) {
      return lumaAccessResponse;
    }
    if (accessIsBuyableByTicket(outpost) || speakIsBuyableByTicket(outpost)) {
      final GroupAccesses? accesses = await checkTicket(outpost: outpost);
      if (accesses?.canEnter == false) {
        Toast.error(
          title: "Error",
          message: "You need a ticket to join this Outpost",
        );
        return GroupAccesses(canEnter: false, canSpeak: false);
      } else {
        return accesses != null
            ? accesses
            : GroupAccesses(canEnter: false, canSpeak: false);
      }
    }

    if (outpost.is_archived) {
      Toast.error(
        title: "Error",
        message: "This Outpost is archived",
      );
      return GroupAccesses(canEnter: false, canSpeak: false);
    }
    if (outpost.iAmMember)
      return GroupAccesses(
          canEnter: true, canSpeak: canISpeakWithoutTicket(outpost: outpost));
    if (outpost.enter_type == FreeOutpostAccessTypes.public)
      return GroupAccesses(
          canEnter: true, canSpeak: canISpeakWithoutTicket(outpost: outpost));
    if (outpost.enter_type == FreeOutpostAccessTypes.onlyLink) {
      if (joiningByLink == true) {
        return GroupAccesses(
            canEnter: true, canSpeak: canISpeakWithoutTicket(outpost: outpost));
      } else {
        Toast.error(
          title: "Error",
          message: "This is a private Outpost, you need an invite link to join",
        );
        return GroupAccesses(canEnter: false, canSpeak: false);
      }
    }

    final invitedMembers = outpost.invites;
    if (outpost.enter_type == FreeOutpostAccessTypes.invitees) {
      if (invitedMembers?.map((e) => e.invitee_uuid).contains(myUser.uuid) ==
          true) {
        return GroupAccesses(
          canEnter: true,
          canSpeak: canISpeakWithoutTicket(outpost: outpost),
        );
      } else {
        Toast.error(
          title: "Error",
          message: "You need an invite to join this Outpost",
        );
        return GroupAccesses(canEnter: false, canSpeak: false);
      }
    }

    return GroupAccesses(canEnter: false, canSpeak: false);
  }

  Future<GroupAccesses?> checkTicket({required OutpostModel outpost}) async {
    joiningGroupId.value = outpost.uuid;
    final checkTicketController = Get.put(CheckticketController());
    checkTicketController.outpost.value = outpost;
    final accesses = await checkTicketController.checkTickets();
    if (accesses.canEnter == true && accesses.canSpeak == true) {
      joiningGroupId.value = '';
      return GroupAccesses(
        canEnter: accesses.canEnter,
        canSpeak: accesses.canSpeak,
      );
    } else {
      final result = await Get.dialog<GroupAccesses?>(CheckTicketView());
      l.d("Result: $result. Can enter: ${result?.canEnter}, can speak: ${result?.canSpeak}");
      Get.delete<CheckticketController>();
      joiningGroupId.value = '';
      return result;
    }
  }

  Future<bool> _showAreYouOver18Dialog({
    required OutpostModel outpost,
    required UserModel myUser,
  }) async {
    final isGroupAgeRestricted = outpost.has_adult_content;
    final iAmOwner = outpost.creator_user_uuid == myUser.uuid;
    final iAmMember = outpost.iAmMember;
    final amIOver18 = myUser.is_over_18;
    if (iAmMember || iAmOwner || !isGroupAgeRestricted || amIOver18 == true) {
      return true;
    }

    final result = await Get.dialog(
      AlertDialog(
        backgroundColor: ColorName.cardBackground,
        title: const Text("Are you over 18?"),
        content: const Text(
          "This group is for adults only, are you over 18?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(Get.overlayContext!).pop(false);
            },
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              final over18Ref = FirebaseDatabase.instance
                  .ref(FireBaseConstants.usersRef + myUser.uuid)
                  .child(UserInfoModel.isOver18Key);
              over18Ref.set(true);
              globalController.setIsMyUserOver18(true);
              Navigator.of(Get.overlayContext!).pop(true);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
    return result;
  }
}

Map<String, OutpostModel> getOutpostsVisibleToMe(
    Map<String, OutpostModel> groups, String myId) {
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

_showModalToToggleArchiveGroup({required OutpostModel outpost}) async {
  final isCurrentlyArchived = outpost.is_archived;
  final result = await Get.dialog(
    AlertDialog(
      backgroundColor: ColorName.cardBackground,
      title: Text("${isCurrentlyArchived ? "Un" : ""}Archive Outpost"),
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
            const TextSpan(text: " this Outpost?"),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(false);
          },
          child: const Text("No"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(true);
          },
          child: const Text("Yes"),
        ),
      ],
    ),
  );
  return result;
}

_showModalToLeaveGroup({required OutpostModel outpost}) async {
  final result = await Get.dialog(
    AlertDialog(
      backgroundColor: ColorName.cardBackground,
      title: const Text("Leave The Outpost"),
      content: RichText(
        text: const TextSpan(
          text: "Are you sure you want to",
          children: [
            const TextSpan(
              text: " leave",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const TextSpan(text: " this Outpost?"),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(false);
          },
          child: const Text("No"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(true);
          },
          child: const Text("Yes"),
        ),
      ],
    ),
  );
  return result;
}

class GroupAccesses {
  bool canEnter;
  bool canSpeak;
  String? accessPriceFullString;
  String? speakPriceFullString;
  GroupAccesses({
    required this.canEnter,
    required this.canSpeak,
    this.accessPriceFullString,
    this.speakPriceFullString,
  });
}
