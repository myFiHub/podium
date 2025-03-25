import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:podium/app/modules/checkTicket/controllers/checkTicket_controller.dart';
import 'package:podium/app/modules/checkTicket/views/checkTicket_view.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/utils/allSetteled.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/modules/outpostDetail/controllers/outpost_detail_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/luma/models/addGuest.dart';
import 'package:podium/providers/api/luma/models/addHost.dart';
import 'package:podium/providers/api/luma/models/createEvent.dart';
import 'package:podium/providers/api/podium/models/outposts/createOutpostRequest.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/outposts/updateOutpostRequest.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/services/websocket/outgoingMessage.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/throttleAndDebounce/throttle.dart';

// detect presence time (groups that were active this milliseconds ago will be considered active)
int dpt = 0;

sendOutpostEvent(
    {required String outpostId,
    required OutgoingMessageTypeEnums eventType,
    WsOutgoingMessageData? eventData}) async {
  try {
    if (eventType == OutgoingMessageTypeEnums.leave) {
      wsClient.send(WsOutgoingMessage(
        message_type: OutgoingMessageTypeEnums.leave,
        outpost_uuid: outpostId,
      ));
      // channel.presence.leave(groupId);
      return;
    }
    if (eventType == OutgoingMessageTypeEnums.start_speaking ||
        eventType == OutgoingMessageTypeEnums.stop_speaking) {
      wsClient.send(WsOutgoingMessage(
        message_type: eventType,
        outpost_uuid: outpostId,
      ));
      return;
    } else if (eventType == OutgoingMessageTypeEnums.like ||
        eventType == OutgoingMessageTypeEnums.dislike ||
        eventType == OutgoingMessageTypeEnums.cheer ||
        eventType == OutgoingMessageTypeEnums.boo) {
      wsClient.send(WsOutgoingMessage(
        message_type: eventType,
        outpost_uuid: outpostId,
        data: eventData,
      ));
      return;
    }
    if (eventType == OutgoingMessageTypeEnums.join) {
      wsClient.send(WsOutgoingMessage(
        message_type: eventType,
        outpost_uuid: outpostId,
      ));
      return;
    }
  } catch (e) {
    l.f(e);
    analytics.logEvent(name: "send_group_presence_event_failed");
  }
}

const numberOfOutpostsPerPage = 10;

class OutpostsController extends GetxController {
  // final _presentUsersRefreshThrottle =
  //     Throttling(duration: const Duration(seconds: 2));
  // final _takingUsersRefreshThrottle =
  //     Throttling(duration: const Duration(seconds: 2));
  bool _shouldUpdatePresentUsers = false; // This is the flag you'll be checking
  late Timer _timerForPresentUsers;
  late Timer _timerForTakingUsers;
  bool _shouldUpdateTakingUsers = false;

  final globalController = Get.find<GlobalController>();
  final joiningOutpostId = ''.obs;
  final outposts = Rx<Map<String, OutpostModel>>({});
  final myOutposts = Rx<Map<String, OutpostModel>>({});
  final isGettingMyOutposts = false.obs;
  late PagingController<int, OutpostModel> allOutpostsPagingController;
  late PagingController<int, OutpostModel> myOutpostsPagingController;
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

    globalController.loggedIn.listen((loggedIn) {
      if (loggedIn) {
        allOutpostsPagingController =
            PagingController<int, OutpostModel>(firstPageKey: 0);
        myOutpostsPagingController =
            PagingController<int, OutpostModel>(firstPageKey: 0);
        _fetchAllOutpostsPage(0);
        _fetchMyOutpostsPage(0);
        getRealtimeOutposts(loggedIn);
      } else {
        allOutpostsPagingController.dispose();
        myOutpostsPagingController.dispose();
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
    _timerForPresentUsers.cancel();
    _timerForTakingUsers.cancel();
  }

  _fetchAllOutpostsPage(int pageKey) async {
    try {
      final newItems = await HttpApis.podium.getOutposts(
        page: pageKey,
        page_size: numberOfOutpostsPerPage,
      );
      final isLastPage = newItems.length < numberOfOutpostsPerPage;
      if (isLastPage) {
        allOutpostsPagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        allOutpostsPagingController.appendPage(newItems, nextPageKey);
      }
      final fetchedOutposts = allOutpostsPagingController.value.itemList ?? [];
      final outpostsMap = Map<String, OutpostModel>.fromEntries(
        fetchedOutposts.map((e) => MapEntry(e.uuid, e)),
      );
      outposts.value = outpostsMap;
    } catch (error) {
      allOutpostsPagingController.error = error;
    }
  }

  _fetchMyOutpostsPage(int pageKey) async {
    try {
      if (pageKey == 0) {
        isGettingMyOutposts.value = true;
      }
      final newItems = await HttpApis.podium.getMyOutposts(
        page: pageKey,
        page_size: numberOfOutpostsPerPage,
      );
      final isLastPage = newItems.length < numberOfOutpostsPerPage;
      if (isLastPage) {
        myOutpostsPagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        myOutpostsPagingController.appendPage(newItems, nextPageKey);
      }
      final fetchedOutposts = myOutpostsPagingController.value.itemList ?? [];
      final outpostsMap = Map<String, OutpostModel>.fromEntries(
        fetchedOutposts.map((e) => MapEntry(e.uuid, e)),
      );
      myOutposts.value = outpostsMap;

      if (pageKey == 0) {
        isGettingMyOutposts.value = false;
      }
    } catch (error) {
      myOutpostsPagingController.error = error;
    } finally {
      isGettingMyOutposts.value = false;
    }
  }

  getPresentUsersInGroup(String groupId) {
    return tmpPresentUsersInGroupsMap[groupId] ?? [];
  }

  Future<void> leaveOutpost({required OutpostModel outpost}) async {
    try {
      final userWantsToLeave = await _showModalToLeaveGroup(outpost: outpost);
      if (userWantsToLeave != true) return;
      final success = await HttpApis.podium.leaveOutpost(outpost.uuid);
      if (success) {
        //  update existing outpost in all outposts page controller and set i_am_member to false
        final outpostIndex = allOutpostsPagingController.value.itemList
            ?.indexWhere((element) => element.uuid == outpost.uuid);
        if (outpostIndex != null) {
          final outpost =
              allOutpostsPagingController.value.itemList?[outpostIndex];
          final updatedOutpost = outpost?.copyWith.i_am_member(false);
          if (updatedOutpost == null) {
            return;
          }
          allOutpostsPagingController.value.itemList?[outpostIndex] =
              updatedOutpost;
          outposts.refresh();

          // update existing outpost in my outposts page controller and set i_am_member to false
          final myOutpostIndex = myOutpostsPagingController.value.itemList
              ?.indexWhere((element) => element.uuid == updatedOutpost.uuid);
          if (myOutpostIndex != null) {
            myOutpostsPagingController.value.itemList?.removeAt(myOutpostIndex);
            myOutposts.value.remove(updatedOutpost.uuid);
            myOutposts.refresh();
          }
          Toast.success(
            title: "Success",
            message: "You have left the outpost",
          );
        }
      }
    } catch (e) {
      l.e(e);
    }
  }

  Future<void> toggleArchive({required OutpostModel outpost}) async {
    final canContinue = await _showModalToToggleArchiveGroup(outpost: outpost);
    if (canContinue == null || canContinue == false) return;
    final archive = !outpost.is_archived;
    final success =
        await HttpApis.podium.toggleOutpostArchive(outpost.uuid, archive);
    if (success != true) {
      Toast.error(
        title: "Error",
        message: "Failed to toggle archive",
      );
      return;
    }
    Toast.success(
      title: "Success",
      message: "Outpost ${archive ? "archived" : "is available again"}",
    );

    // set is archived for outpost in allOutpostsPagingController
    final outpostIndex = allOutpostsPagingController.value.itemList
        ?.indexWhere((element) => element.uuid == outpost.uuid);
    if (outpostIndex != null) {
      allOutpostsPagingController.value.itemList?[outpostIndex] =
          outpost.copyWith.is_archived(archive);
      outposts.value[outpost.uuid] = outpost.copyWith.is_archived(archive);
      outposts.refresh();
    }
    // set is archived for outpost in myOutpostsPagingController
    final myOutpostIndex = myOutpostsPagingController.value.itemList
        ?.indexWhere((element) => element.uuid == outpost.uuid);
    if (myOutpostIndex != null) {
      myOutpostsPagingController.value.itemList?[myOutpostIndex] =
          outpost.copyWith.is_archived(archive);
      myOutposts.value[outpost.uuid] = outpost.copyWith.is_archived(archive);
      myOutposts.refresh();
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

  getMyOutposts() async {
    final outposts = await HttpApis.podium.getMyOutposts();
    final Map<String, OutpostModel> map = {};
    for (var outpost in outposts) {
      map[outpost.uuid] = outpost;
    }
    myOutposts.value = map;
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
    }
  }

  getRealtimeOutposts(bool loggedIn) async {
    allOutpostsPagingController.addPageRequestListener((pageKey) {
      _fetchAllOutpostsPage(pageKey);
    });

    myOutpostsPagingController.addPageRequestListener((pageKey) {
      _fetchMyOutpostsPage(pageKey);
    });
  }

  Future<String?> _createLumaEvent({
    required String outpostId,
    required int scheduledFor,
    required String outpostName,
    required List<AddHostModel> lumaHosts,
    required List<AddGuestModel> lumaGuests,
  }) async {
    try {
      final isoDate =
          DateTime.fromMillisecondsSinceEpoch(scheduledFor).toIso8601String();
      final oneHourAfter =
          DateTime.fromMillisecondsSinceEpoch(scheduledFor + 60 * 60 * 1000)
              .toIso8601String();
      final lumaEvent = Luma_CreateEvent(
        name: outpostName,
        start_at: isoDate,
        end_at: oneHourAfter,
        meeting_url: generateOutpostShareUrl(outpostId: outpostId),
      );
      final createdEvent = await HttpApis.lumaApi.createEvent(event: lumaEvent);
      if (createdEvent != null) {
        final eventId = createdEvent.event.api_id;
        final Map<String, Future<bool?>> addHostsCallMap = {};
        for (var host in lumaHosts) {
          addHostsCallMap[host.email] = HttpApis.lumaApi.addHost(
            host: AddHostModel(
              event_api_id: eventId,
              email: host.email,
              name: host.name,
            ),
          );
        }
        // since we are adding hosts and guests in parallel, we need to wait for all of them to finish,
        // ignoring the failed ones, since we always can add them later
        await allSettled(addHostsCallMap);
        final GuestsAdded = await HttpApis.lumaApi.addGuests(
          eventId: eventId,
          guests: lumaGuests,
        );
        if (GuestsAdded == true) {
          Toast.success(message: 'Luma Event Created');
          return eventId;
        }
      }
    } catch (e) {
      l.e(e);
    }
    return null;
  }

  Future<OutpostModel?> createOutpost({
    required String name,
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
    String? imageUrl,
    bool shouldCreateLumaEvent = false,
    List<AddHostModel> lumaHosts = const [],
    List<AddGuestModel> lumaGuests = const [],
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
      name: name,
      scheduled_for: scheduledFor,
      speak_type: speakerType,
      subject: subject,
      tags: tags,
      tickets_to_enter: accessAddresses,
      tickets_to_speak: speakAddresses,
    );
    try {
      OutpostModel? response;
      response = await HttpApis.podium.createOutpost(
        createOutpostRequest,
      );

      if (response != null) {
        if (shouldCreateLumaEvent) {
          final lumaEventId = await _createLumaEvent(
            outpostId: response.uuid,
            scheduledFor: scheduledFor,
            outpostName: name,
            lumaHosts: lumaHosts,
            lumaGuests: lumaGuests,
          );
          if (lumaEventId == null) {
            Toast.error(message: 'Failed to create Luma Event');
            return response;
          } else {
            final success = await HttpApis.podium.updateOutpost(
              request: UpdateOutpostRequest(
                uuid: response.uuid,
                luma_event_id: lumaEventId,
              ),
            );
            if (!success) {
              Toast.error(message: 'Failed to create Luma Event id');
            } else {
              response.luma_event_id = lumaEventId;
            }
          }
        }
        // add outpost to the top of lists of my outposts and all outposts
        allOutpostsPagingController.value.itemList?.insert(0, response);
        myOutpostsPagingController.value.itemList?.insert(0, response);
        myOutposts.value[response.uuid] = response;
        myOutposts.refresh();
        outposts.value[response.uuid] = response;
        outposts.refresh();
      }
      return response;
    } catch (e) {
      Toast.error(
        title: "Error",
        message: "Failed to create the Outpost",
      );
      return null;
    }
  }

  Future<void> joinOutpostAndOpenOutpostDetailPage({
    required String outpostId,
    bool? openTheRoomAfterJoining,
    bool? joiningByLink,
  }) async {
    if (outpostId.isEmpty) return;
    if (joiningOutpostId != '') {
      return;
    }
    try {
      joiningOutpostId.value = outpostId;
      final outpost = await HttpApis.podium.getOutpost(outpostId);
      l.d("Outpost: $outpost");
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
        joiningOutpostId.value = '';
        return;
      }
      final hasAgeVerified = await _showAreYouOver18Dialog(
        outpost: outpost,
        myUser: myUser,
      );
      if (!hasAgeVerified) {
        joiningOutpostId.value = '';
        return;
      }

      if (!outpost.i_am_member) {
        final added = await HttpApis.podium.addMeAsMember(outpostId: outpostId);
        if (!added) {
          Toast.error(
            title: "Error",
            message: "Failed to join the Outpost, try again or report a bug",
          );
          return;
        }
        // update outposts list in allOutpostsPagingController
        final outpostIndex = allOutpostsPagingController.value.itemList
            ?.indexWhere((element) => element.uuid == outpost.uuid);
        if (outpostIndex != null) {
          final outpost =
              allOutpostsPagingController.value.itemList?[outpostIndex];
          final updatedOutpost = outpost?.copyWith.i_am_member(true);
          if (updatedOutpost == null) {
            return;
          }
          allOutpostsPagingController.value.itemList?[outpostIndex] =
              updatedOutpost;
          outposts.value[updatedOutpost.uuid] = updatedOutpost;
          outposts.refresh();

          // add to top of my outposts if it doesn't exist
          if (myOutpostsPagingController.value.itemList
                  ?.any((element) => element.uuid == updatedOutpost.uuid) ==
              false) {
            myOutpostsPagingController.value.itemList
                ?.insert(0, updatedOutpost);
          }

          myOutposts.value[updatedOutpost.uuid] = updatedOutpost;
          myOutposts.refresh();
        }
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
      l.f("Error joining outpost: $e");
    } finally {
      joiningOutpostId.value = '';
    }

    return;
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
    if (outpost.i_am_member)
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
    joiningOutpostId.value = outpost.uuid;
    final checkTicketController = Get.put(CheckticketController());
    checkTicketController.outpost.value = outpost;
    final accesses = await checkTicketController.checkTickets();
    if (accesses.canEnter == true && accesses.canSpeak == true) {
      joiningOutpostId.value = '';
      return GroupAccesses(
        canEnter: accesses.canEnter,
        canSpeak: accesses.canSpeak,
      );
    } else {
      final result = await Get.dialog<GroupAccesses?>(CheckTicketView());
      l.d("Result: $result. Can enter: ${result?.canEnter}, can speak: ${result?.canSpeak}");
      Get.delete<CheckticketController>();
      joiningOutpostId.value = '';
      return result;
    }
  }

  Future<bool> _showAreYouOver18Dialog({
    required OutpostModel outpost,
    required UserModel myUser,
  }) async {
    final isGroupAgeRestricted = outpost.has_adult_content;
    final iAmOwner = outpost.creator_user_uuid == myUser.uuid;
    final iAmMember = outpost.i_am_member;
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
              globalController.setIsMyUserOver18(true);
              HttpApis.podium.updateMyUserData({'is_over_18': true});
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
