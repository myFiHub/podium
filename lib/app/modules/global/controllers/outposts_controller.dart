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
import 'package:podium/app/modules/search/controllers/search_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/data/repositories/repositories.dart';
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
import 'package:podium/widgets/ui/app_ui.dart';

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
  final _outpostRepository = Get.find<OutpostRepository>();
  final _userRepository = Get.find<UserRepository>();
  final showCreateButton = true.obs;

  final globalController = Get.find<GlobalController>();
  final joiningOutpostId = ''.obs;
  final outposts = Rx<Map<String, OutpostModel>>({});
  final myOutposts = Rx<Map<String, OutpostModel>>({});
  final isGettingMyOutposts = false.obs;
  final isGettingAllOutposts = false.obs;

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
      } else {
        clearOutposts();
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    _showArchivedListener?.cancel();
    _loggedInListener?.cancel();
  }

  static const _onlineCountMaxAge = Duration(seconds: 15);
  final _onlineCountFetchedAt = <String, DateTime>{};

  void addOutpostToView(String outpostId) {
    mapOfOutpostsInView.value[outpostId] = true;
    debounceForFetchingNumberOfOnlineMembers.debounce(() async {
      final now = DateTime.now();
      final ids = mapOfOutpostsInView.value.keys.where((id) {
        final fetchedAt = _onlineCountFetchedAt[id];
        return fetchedAt == null ||
            now.difference(fetchedAt) > _onlineCountMaxAge;
      }).toList();
      if (ids.isEmpty) return;
      for (final id in ids) {
        _onlineCountFetchedAt[id] = now;
      }
      final results = await allSettled({
        for (final id in ids)
          id: _outpostRepository.getNumberOfOnlineMembers(id),
      });
      // Merge, so outposts scrolled out of view keep their last live count.
      final map = {...mapOfOnlineUsersInOutposts.value};
      for (final id in ids) {
        final result = results[id];
        if (result?.isFulfilled != true) continue;
        if (result!.value != 0) {
          map[id] = result.value!;
        } else {
          map.remove(id);
        }
      }
      mapOfOnlineUsersInOutposts.value = map;
    });
  }

  void removeOutpostFromView(String outpostId) {
    mapOfOutpostsInView.value.remove(outpostId);
  }

  /// Page 0 replaces the list once the response arrives, so a refresh keeps
  /// showing the current outposts instead of flashing skeletons. A failed
  /// request leaves the list as it was.
  Future<void> fetchAllOutpostsPage(int pageKey) {
    return _fetchPage(
      pageKey: pageKey,
      target: outposts,
      isLoading: isGettingAllOutposts,
      lastPageReached: lastPageReachedForAllOutposts,
      fetch: () => _outpostRepository.getOutposts(
        page: pageKey,
        page_size: numberOfOutpostsPerPage,
      ),
    );
  }

  Future<void> fetchMyOutpostsPage(int pageKey) {
    return _fetchPage(
      pageKey: pageKey,
      target: myOutposts,
      isLoading: isGettingMyOutposts,
      lastPageReached: lastPageReachedForMyOutposts,
      fetch: () => _outpostRepository.getMyOutposts(
        include_archived: showArchivedOutposts.value,
        page: pageKey,
        page_size: numberOfOutpostsPerPage,
      ),
    );
  }

  Future<void> _fetchPage({
    required int pageKey,
    required Rx<Map<String, OutpostModel>> target,
    required RxBool isLoading,
    required RxBool lastPageReached,
    required Future<List<OutpostModel>> Function() fetch,
  }) async {
    if (pageKey == 0) {
      isLoading.value = true;
    }
    try {
      final newItems = await fetch();
      target.value = {
        if (pageKey != 0) ...target.value,
        for (final outpost in newItems) outpost.uuid: outpost,
      };
      lastPageReached.value = newItems.length < numberOfOutpostsPerPage;
    } on ApiFailure catch (e) {
      // Load-more retries on every scroll, so only a refresh is worth a toast.
      if (pageKey == 0) {
        Toast.error(message: e.message);
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Drops the previous account's lists so they never show for the next one.
  void clearOutposts() {
    outposts.value = {};
    myOutposts.value = {};
    lastPageReachedForAllOutposts.value = false;
    lastPageReachedForMyOutposts.value = false;
    mapOfOnlineUsersInOutposts.value = {};
    _onlineCountFetchedAt.clear();
  }

  Future<void> leaveOutpost({required OutpostModel outpost}) async {
    try {
      final userWantsToLeave = await _showModalToLeaveGroup(outpost: outpost);
      if (userWantsToLeave != true) return;
      final success = await _outpostRepository.leaveOutpost(outpost.uuid);
      if (success) {
        //  update existing outpost in all outposts page controller and set i_am_member to false
        OutpostModel updatedOutpost = outpost.copyWith.i_am_member(false);
        final numberOfMembers = outpost.members_count ?? 1;
        updatedOutpost =
            updatedOutpost.copyWith.members_count(numberOfMembers - 1);
        updateOutpost_local(updatedOutpost);
        fetchMyOutpostsPage(0);

        Toast.success(
          message: "You have left the outpost",
        );
      }
    } catch (e) {
      l.e(e);
    }
  }

  Future<String?> uploadOutpostImage(
      OutpostModel outpost, String newImageUrl) async {
    try {
      final updated = await _outpostRepository.updateOutpost(
        request: UpdateOutpostRequest(
          image: newImageUrl,
          uuid: outpost.uuid,
        ),
      );
      if (!updated) {
        Toast.error(message: 'Failed to update outpost image');
        return null;
      }
      final updatedOutpost = outpost.copyWith.image(newImageUrl);
      updateOutpost_local(updatedOutpost);
      return newImageUrl;
    } catch (e) {
      l.e("Error updating OutpostsController: $e");
      Toast.error(message: 'Failed to update outpost image');
      return null;
    }
  }

  Future<void> toggleArchive({required OutpostModel outpost}) async {
    final canContinue = await _showModalToToggleArchiveGroup(outpost: outpost);
    if (canContinue == null || canContinue == false) return;
    final archive = !outpost.is_archived;
    final success =
        await _outpostRepository.toggleOutpostArchive(outpost.uuid, archive);
    if (success != true) {
      Toast.error(
        message: "Failed to toggle archive",
      );
      return;
    }
    Toast.success(
      message: "Outpost ${archive ? "archived" : "is available again"}",
    );

    final updatedOutpost = outpost.copyWith.is_archived(archive);
    updateOutpost_local(updatedOutpost);

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
      final lumaEvent = LumaCreateEvent(
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
    required List<String> cohosts,
    String? imageUrl,
    bool shouldCreateLumaEvent = false,
    List<AddHostModel> lumaHosts = const [],
    List<AddGuestModel> lumaGuests = const [],
  }) async {
    final accessAddresses = [
      ...requiredAddressesToEnter,
      ...requiredTicketsToAccess.map((e) => e.activeAddress),
    ];
    final speakAddresses = [
      ...requiredAddressesToSpeak,
      ...requiredTicketsToSpeak.map((e) => e.activeAddress),
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
      cohost_user_uuids: cohosts,
    );
    try {
      OutpostModel? response;
      response = await _outpostRepository.createOutpost(
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
            final success = await _outpostRepository.updateOutpost(
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
        fetchMyOutpostsPage(0);
        fetchAllOutpostsPage(0);
      }
      return response;
    } catch (e) {
      Toast.error(
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
    outpostId = outpostId.replaceAll('/', '');
    if (outpostId.isEmpty) return;
    if (joiningOutpostId.value.isNotEmpty) return;
    try {
      joiningOutpostId.value = outpostId;
      final outpost = await _outpostRepository.getOutpost(outpostId);
      if (outpost == null) {
        Toast.error(
          title: "Error-455",
          message: "Failed to join the Outpost",
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
      final isAlreadyMember = outpost.i_am_member;
      if (!isAlreadyMember) {
        final added = await _outpostRepository.addMeAsMember(
          outpostId: outpost.uuid,
        );
        if (!added) {
          Toast.error(
            message: "Failed to join the Outpost, try again or report a bug",
          );
          return;
        }

        OutpostModel updatedOutpost = outpost.copyWith.i_am_member(true);
        final numberOfMembers = outpost.members_count ?? 0;
        updatedOutpost =
            updatedOutpost.copyWith.members_count(numberOfMembers + 1);
        updateOutpost_local(updatedOutpost);
        _openOutpost(
          outpost: updatedOutpost,
          openTheRoomAfterJoining: openTheRoomAfterJoining ?? false,
          accesses: accesses,
          isAlreadyMember: isAlreadyMember,
        );
      } else {
        l.d("Already a member");
        _openOutpost(
          outpost: outpost,
          openTheRoomAfterJoining: openTheRoomAfterJoining ?? false,
          accesses: accesses,
          isAlreadyMember: isAlreadyMember,
        );
      }
    } catch (e) {
      Toast.error(
        message: "Failed to join the Outpost,please try again or report a bug",
      );
      l.f("Error joining outpost: $e");
    } finally {
      joiningOutpostId.value = '';
    }

    return;
  }

  Future<void> _openOutpost({
    required OutpostModel outpost,
    required bool openTheRoomAfterJoining,
    required OutpostAccesses accesses,
    bool? isAlreadyMember,
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
    if (isAlreadyMember == false) {
      fetchMyOutpostsPage(0);
    }
    analytics.logEvent(
      name: "outpost_opened",
      parameters: {
        "outpost_id": outpost.uuid,
      },
    );
  }

  /// updates the outpost in the local list of outposts and my outposts and searched outposts, the new outpost is not fetched from the server,
  /// edits most be done before calling this function, then pass the edited outpost to this function
  void updateOutpost_local(OutpostModel updatedOutpost) {
    for (final list in [outposts, myOutposts]) {
      if (list.value.containsKey(updatedOutpost.uuid)) {
        list.value[updatedOutpost.uuid] = updatedOutpost;
        list.refresh();
      }
    }

    final isSearchRegistered = Get.isRegistered<SearchPageController>();
    if (isSearchRegistered) {
      final searchController = Get.find<SearchPageController>();
      searchController.updateOutpost_local(updatedOutpost);
    }
    final isOutpostDetailRegistered =
        Get.isRegistered<OutpostDetailController>();
    if (isOutpostDetailRegistered) {
      final outpostDetailController = Get.find<OutpostDetailController>();
      outpostDetailController.outpost.value = updatedOutpost;
    }
  }

  Future<OutpostAccesses?> _checkLumaAccess(
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
              return OutpostAccesses(canEnter: true, canSpeak: true);
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

  Future<OutpostAccesses> getOutpostAccesses(
      {required OutpostModel outpost, bool? joiningByLink}) async {
    final iAmOutpostCreator = outpost.creator_user_uuid == myUser.uuid;
    if (iAmOutpostCreator) {
      return OutpostAccesses(canEnter: true, canSpeak: true);
    }
    if (outpost.is_archived) {
      Toast.error(
        message: "This Outpost is archived",
      );
      return OutpostAccesses(canEnter: false, canSpeak: false);
    }
    final cohosts = outpost.cohost_user_uuids ?? [];
    if (cohosts.contains(myUser.uuid)) {
      return OutpostAccesses(canEnter: true, canSpeak: true);
    }
    final lumaAccessResponse = await _checkLumaAccess(outpost: outpost);
    if (lumaAccessResponse != null) {
      return lumaAccessResponse;
    }
    if (accessIsBuyableByTicket(outpost) || speakIsBuyableByTicket(outpost)) {
      final OutpostAccesses? accesses = await checkTicket(
        outpost: outpost,
        joiningByLink: joiningByLink ?? false,
      );
      if (accesses?.canEnter == false) {
        Toast.error(
          message: "You need a ticket to join this Outpost",
        );
        return OutpostAccesses(canEnter: false, canSpeak: false);
      } else {
        return accesses ?? OutpostAccesses(canEnter: false, canSpeak: false);
      }
    }

    if (outpost.i_am_member) {
      return OutpostAccesses(
          canEnter: true, canSpeak: canISpeakWithoutTicket(outpost: outpost));
    }
    if (outpost.enter_type == FreeOutpostAccessTypes.public) {
      return OutpostAccesses(
          canEnter: true, canSpeak: canISpeakWithoutTicket(outpost: outpost));
    }
    if (outpost.enter_type == FreeOutpostAccessTypes.onlyLink) {
      if (joiningByLink == true) {
        return OutpostAccesses(
            canEnter: true, canSpeak: canISpeakWithoutTicket(outpost: outpost));
      } else {
        Toast.error(
          message: "This is a private Outpost, you need an invite link to join",
        );
        return OutpostAccesses(canEnter: false, canSpeak: false);
      }
    }

    if (outpost.enter_type == FreeOutpostAccessTypes.invited_users) {
      if (isInvitedToOutpost(outpost)) {
        return OutpostAccesses(
          canEnter: true,
          canSpeak: canISpeakWithoutTicket(outpost: outpost),
        );
      } else {
        Toast.error(
          message: "You need an invite to join this Outpost",
        );
        return OutpostAccesses(canEnter: false, canSpeak: false);
      }
    }

    return OutpostAccesses(canEnter: false, canSpeak: false);
  }

  Future<OutpostAccesses?> checkTicket({
    required OutpostModel outpost,
    bool joiningByLink = false,
  }) async {
    final checkTicketController = Get.put(CheckticketController());
    checkTicketController.outpost.value = outpost;
    checkTicketController.joiningByLink = joiningByLink;
    final accesses = await checkTicketController.checkTickets();
    if (accesses.canEnter == true && accesses.canSpeak == true) {
      Get.delete<CheckticketController>();
      return OutpostAccesses(
        canEnter: accesses.canEnter,
        canSpeak: accesses.canSpeak,
      );
    } else {
      final result = await Get.dialog<OutpostAccesses?>(
        const AppDialogMotion(child: CheckTicketView()),
      );
      l.d("Result: $result. Can enter: ${result?.canEnter}, can speak: ${result?.canSpeak}");
      Get.delete<CheckticketController>();
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
      AppDialog(
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.accent,
        title: "Age Verification Required",
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Adult Content Warning", style: AppText.cardTitle),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    "You must be 18+ to access this content",
                    style: AppText.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const AppCallout(
              text:
                  "By proceeding, you confirm that you are at least 18 years of age.",
              icon: Icons.verified_user_outlined,
            ),
          ],
        ),
        stackActions: true,
        actions: [
          AppPrimaryButton(
            label: "Yes, I'm 18 or older",
            color: AppColors.accent,
            foreground: AppColors.onColor(AppColors.accent),
            onPressed: () {
              globalController.setIsMyUserOver18(true);
              _userRepository.updateMyUserData({'is_over_18': true});
              Navigator.of(Get.overlayContext!).pop(true);
            },
          ),
          AppSecondaryButton(
            label: "No, I'm under 18",
            onPressed: () {
              Navigator.of(Get.overlayContext!).pop(false);
            },
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

Future<dynamic> _showModalToToggleArchiveGroup(
    {required OutpostModel outpost}) async {
  final isCurrentlyArchived = outpost.is_archived;
  final result = await Get.dialog(
    AppDialog(
      icon: isCurrentlyArchived
          ? Icons.unarchive_outlined
          : Icons.archive_outlined,
      iconColor: isCurrentlyArchived ? AppColors.success : AppColors.danger,
      title: "${isCurrentlyArchived ? "Un" : ""}Archive Outpost",
      content: Text.rich(
        TextSpan(
          text: "Are you sure you want to ",
          style: AppText.muted.copyWith(height: 1.45),
          children: [
            TextSpan(
              text: "${isCurrentlyArchived ? "un" : ""}archive",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    !isCurrentlyArchived ? AppColors.danger : AppColors.success,
              ),
            ),
            const TextSpan(text: " this Outpost?"),
          ],
        ),
      ),
      actions: [
        AppSecondaryButton(
          label: "No",
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(false);
          },
        ),
        AppPrimaryButton(
          label: "Yes",
          color: isCurrentlyArchived ? AppColors.primary : AppColors.danger,
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(true);
          },
        ),
      ],
    ),
  );
  return result;
}

Future<dynamic> _showModalToLeaveGroup({required OutpostModel outpost}) async {
  final result = await Get.dialog(
    AppDialog(
      icon: Icons.exit_to_app_rounded,
      iconColor: AppColors.danger,
      urgent: true,
      title: "Leave Outpost",
      message: "Are you sure you want to leave this outpost?",
      content: AppCallout(
        text: "You can rejoin later if you have the required access.",
        color: AppColors.danger,
      ),
      actions: [
        AppSecondaryButton(
          label: "Cancel",
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(false);
          },
        ),
        AppPrimaryButton(
          label: "Leave",
          color: AppColors.danger,
          onPressed: () {
            Navigator.of(Get.overlayContext!).pop(true);
          },
        ),
      ],
    ),
  );
  return result;
}

class OutpostAccesses {
  bool canEnter;
  bool canSpeak;
  String? accessPriceFullString;
  String? speakPriceFullString;
  OutpostAccesses({
    required this.canEnter,
    required this.canSpeak,
    this.accessPriceFullString,
    this.speakPriceFullString,
  });
}
