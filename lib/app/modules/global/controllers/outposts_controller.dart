import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
import 'package:podium/utils/throttleAndDebounce/debounce.dart';

/// Sends an outpost event to the WebSocket server
///
/// [outpostId] - The UUID of the outpost
/// [eventType] - The type of event to send
/// [requestId] - Optional request ID for tracking
/// [eventData] - Optional data to send with the event
///
/// Returns a Future that completes when the message is sent
/// Throws [OutpostEventException] if the message fails to send
Future<void> sendOutpostEvent({
  required String outpostId,
  required OutgoingMessageTypeEnums eventType,
  String? requestId,
  WsOutgoingMessageData? eventData,
}) async {
  try {
    // Validate inputs
    if (outpostId.isEmpty) {
      throw ArgumentError('outpostId cannot be empty');
    }

    // Create the base message
    final message = WsOutgoingMessage(
      message_type: eventType,
      outpost_uuid: outpostId,
      data: eventData,
    );

    // Send the message
    await wsClient.send(message);

    // Log successful send
    l.d('Sent outpost event: ${eventType.name} for outpost: $outpostId, ');
  } catch (e) {
    l.e('Failed to send outpost event: ${eventType.name} for outpost: $outpostId - $e');
  }
}

const numberOfOutpostsPerPage = 15;

final debounceForFetchingNumberOfOnlineMembers =
    Debouncing(duration: const Duration(seconds: 2));

class OutpostsController extends GetxController {
  final showCreateButton = true.obs;

  final globalController = Get.find<GlobalController>();
  final joiningOutpostId = ''.obs;
  final outposts = Rx<Map<String, OutpostModel>>({});
  final myOutposts = Rx<Map<String, OutpostModel>>({});
  final isGettingMyOutposts = false.obs;
  final isGettingAllOutposts = false.obs;

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

  final lastPageReachedForAllOutposts = false.obs;
  final lastPageReachedForMyOutposts = false.obs;

  StreamSubscription<bool>? _showArchivedListener;
  StreamSubscription<bool>? _loggedInListener;

  final showArchivedOutposts = false.obs;

  final mapOfOutpostsInView = Rx<Map<String, bool>>({});
  final mapOfOnlineUsersInOutposts = Rx<Map<String, int>>({});

  @override
  void onInit() {
    super.onInit();
    showArchivedOutposts.value = globalController.showArchivedOutposts.value;
    _showArchivedListener =
        globalController.showArchivedOutposts.listen((show) {
      showArchivedOutposts.value = show;
      fetchMyOutpostsPage(0);
    });
    _loggedInListener = globalController.loggedIn.listen((loggedIn) {
      if (loggedIn) {
        fetchAllOutpostsPage(0);
        fetchMyOutpostsPage(0);
      } else {}
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
    _showArchivedListener?.cancel();
    _loggedInListener?.cancel();
  }

  void addOutpostToView(String outpostId) {
    mapOfOutpostsInView.value[outpostId] = true;
    final List<String> ids = mapOfOutpostsInView.value.keys
        .where((String e) => mapOfOutpostsInView.value[e] == true)
        .toList();
    debounceForFetchingNumberOfOnlineMembers.debounce(() async {
      final Map<String, Future<int>> calls = <String, Future<int>>{};
      for (String id in ids) {
        calls[id] = HttpApis.podium.getNumberOfOnlineMembers(id);
      }
      final Map<String, dynamic> results = await allSettled(calls);
      final Map<String, int> map = <String, int>{};
      for (String id in ids) {
        if (results[id]?['status'] == AllSettledStatus.fulfilled &&
            results[id]?['value'] != 0) {
          map[id] = results[id]!['value'];
        }
      }

      mapOfOutpostsInView.value = <String, bool>{};
      mapOfOnlineUsersInOutposts.value = map;
    });
  }

  void removeOutpostFromView(String outpostId) {
    mapOfOutpostsInView.value[outpostId] = false;
  }

  fetchAllOutpostsPage(int pageKey) async {
    try {
      if (pageKey == 0) {
        isGettingAllOutposts.value = true;
        outposts.value = {};
        lastPageReachedForAllOutposts.value = false;
      }
      final newItems = await HttpApis.podium.getOutposts(
        page: pageKey,
        page_size: numberOfOutpostsPerPage,
      );
      if (newItems.length < numberOfOutpostsPerPage) {
        lastPageReachedForAllOutposts.value = true;
      }
      final previousOutposts = outposts.value.values.toList();
      final outpostsMap = Map<String, OutpostModel>.fromEntries(
        [...previousOutposts, ...newItems].map((e) => MapEntry(e.uuid, e)),
      );
      outposts.value = outpostsMap;
    } catch (error) {
    } finally {
      isGettingAllOutposts.value = false;
    }
  }

  fetchMyOutpostsPage(int pageKey) async {
    try {
      if (pageKey == 0) {
        myOutposts.value = {};
        lastPageReachedForMyOutposts.value = false;
        isGettingMyOutposts.value = true;
      }
      final showArchived = showArchivedOutposts.value;
      final newItems = await HttpApis.podium.getMyOutposts(
        include_archived: showArchived,
        page: pageKey,
        page_size: numberOfOutpostsPerPage,
      );
      if (newItems.length < numberOfOutpostsPerPage) {
        lastPageReachedForMyOutposts.value = true;
      }
      final previousOutposts = myOutposts.value.values.toList();
      final outpostsMap = Map<String, OutpostModel>.fromEntries(
        [...previousOutposts, ...newItems].map((e) => MapEntry(e.uuid, e)),
      );
      myOutposts.value = outpostsMap;

      if (pageKey == 0) {
        isGettingMyOutposts.value = false;
      }
    } catch (error) {
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
        final outpostIndex = outposts.value.values
            .toList()
            .indexWhere((element) => element.uuid == outpost.uuid);
        if (outpostIndex != -1) {
          final outpost = outposts.value.values.toList()[outpostIndex];
          final updatedOutpost = outpost.copyWith.i_am_member(false);
          outposts.value[outpost.uuid] = updatedOutpost;
          outposts.refresh();

          // update existing outpost in my outposts page controller and set i_am_member to false
          final myOutpostIndex = myOutposts.value.values
              .toList()
              .indexWhere((element) => element.uuid == updatedOutpost.uuid);
          if (myOutpostIndex != -1) {
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
    final outpostIndex = outposts.value.values
        .toList()
        .indexWhere((element) => element.uuid == outpost.uuid);
    if (outpostIndex != -1) {
      outposts.value[outpost.uuid] = outpost.copyWith.is_archived(archive);
      outposts.refresh();
    }
    // set is archived for outpost in myOutpostsPagingController
    final myOutpostIndex = myOutposts.value.values
        .toList()
        .indexWhere((element) => element.uuid == outpost.uuid);
    if (myOutpostIndex != -1) {
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

  Future<String?> _createLumaEvent({
    required String outpostId,
    required int scheduledFor,
    required String outpostName,
    required List<AddHostModel> lumaHosts,
    required List<AddGuestModel> lumaGuests,
  }) async {
    try {
      final isoDate = DateTime.fromMillisecondsSinceEpoch(scheduledFor)
          .toUtc()
          .toIso8601String();
      final oneHourAfter =
          DateTime.fromMillisecondsSinceEpoch(scheduledFor + 60 * 60 * 1000)
              .toUtc()
              .toIso8601String();
      final lumaEvent = Luma_CreateEvent(
        name: outpostName,
        start_at: isoDate,
        end_at: oneHourAfter,
        timezone: 'UTC',
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
        final outpostIndex = outposts.value.values
            .toList()
            .indexWhere((element) => element.uuid == outpost.uuid);
        if (outpostIndex != -1) {
          final outpost = outposts.value.values.toList()[outpostIndex];
          final updatedOutpost = outpost.copyWith.i_am_member(true);
          outposts.value[updatedOutpost.uuid] = updatedOutpost;
          outposts.refresh();

          // add to top of my outposts if it doesn't exist
          if (myOutposts.value.values
                  .toList()
                  .any((element) => element.uuid == updatedOutpost.uuid) ==
              false) {
            myOutposts.value[updatedOutpost.uuid] = updatedOutpost;
            myOutposts.refresh();
          }
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

  updateOutpost(OutpostModel outpost) {
    final outpostIndex = outposts.value.values
        .toList()
        .indexWhere((element) => element.uuid == outpost.uuid);
    if (outpostIndex != -1) {
      outposts.value[outpost.uuid] = outpost;
      outposts.refresh();
      final myOutpostIndex = myOutposts.value.values
          .toList()
          .indexWhere((element) => element.uuid == outpost.uuid);
      if (myOutpostIndex != -1) {
        myOutposts.value[outpost.uuid] = outpost;
        myOutposts.refresh();
      }
    }
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
