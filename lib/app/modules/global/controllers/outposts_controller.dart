import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/checkTicket/controllers/checkTicket_controller.dart';
import 'package:podium/app/modules/createOutpost/luma_event.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/join_outpost_flow.dart';
import 'package:podium/app/modules/global/utils/allSetteled.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/outpostDetail/controllers/outpost_detail_controller.dart';
import 'package:podium/app/modules/search/controllers/search_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/luma/models/addGuest.dart';
import 'package:podium/providers/api/luma/models/addHost.dart';
import 'package:podium/providers/api/podium/models/outposts/createOutpostRequest.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/outposts/updateOutpostRequest.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/services/websocket/outgoingMessage.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';
import 'package:podium/widgets/ui/app_ui.dart';

export 'package:podium/app/modules/checkTicket/ticket_access.dart'
    show OutpostAccesses;

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
  final _joinFlow = JoinOutpostFlow();
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
    bool musicMode = false,
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
      is_music_mode: musicMode,
    );
    try {
      OutpostModel? response;
      response = await _outpostRepository.createOutpost(
        createOutpostRequest,
      );

      if (response != null) {
        if (shouldCreateLumaEvent) {
          final lumaEventId = await createLumaEventForOutpost(
            outpostId: response.uuid,
            outpostName: name,
            scheduledFor: scheduledFor,
            hosts: lumaHosts,
            guests: lumaGuests,
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

      final accesses = await _joinFlow.getOutpostAccesses(
        outpost: outpost,
        joiningByLink: joiningByLink ?? false,
      );
      l.d("Accesses: ${accesses.canEnter} ${accesses.canSpeak}");
      if (accesses.canEnter == false) {
        joiningOutpostId.value = '';
        return;
      }
      final hasAgeVerified = await _joinFlow.confirmAge(
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
