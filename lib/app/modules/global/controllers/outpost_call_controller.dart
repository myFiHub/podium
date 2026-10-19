import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:podium/app/modules/checkTicket/ticket_access.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/popUpsAndModals/scoreOutpostPrompt.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/permissions.dart';
import 'package:podium/app/modules/global/utils/time.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/constants/meeting.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/models/jitsi_member.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/services/websocket/incomingMessage.dart';
import 'package:podium/services/websocket/outgoingMessage.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class OutpostCallController extends GetxController {
  final _outpostRepository = Get.find<OutpostRepository>();
  final storage = GetStorage();
  final outpostsController = Get.find<OutpostsController>();
  final globalController = Get.find<GlobalController>();
  final outpost = Rxn<OutpostModel>();

  /// Present members in server order. Emits only when membership changes;
  /// speaking flags and talk times are updated in place, see [speakingTick]
  /// and [talkTimeTick].
  final members = Rx<List<LiveMember>>([]);

  /// [members] split by [isStageMember], speakers first on stage. Each is
  /// reassigned only when its order actually changes, so a speak event that
  /// doesn't move anyone rebuilds nothing but the speaker's avatar.
  final stageMembers = Rx<List<LiveMember>>([]);
  final audienceMembers = Rx<List<LiveMember>>([]);
  final talkingCount = 0.obs;

  /// Bumped whenever a member's speaking flag changes in place.
  final speakingTick = 0.obs;
  final Map<String, RxBool> _speaking = {};

  /// Per-member speaking flag, so an avatar rebuilds only for its own member.
  RxBool speakingOf(String uuid) =>
      _speaking.putIfAbsent(uuid, () => false.obs);

  final reactionsMap = Rx<Map<String, Map<OutgoingMessageTypeEnums, int>>>({});
  final haveOngoingCall = false.obs;

  CallSession? _session;

  /// The live call, or null once it ended. Async work started for a call
  /// should capture this and check [CallSession.isActive] after every await,
  /// or schedule itself through [CallSession.delayed].
  CallSession? get session {
    final s = _session;
    return s != null && s.isActive ? s : null;
  }

  /// True once [cleanupAfterCall] ran for the current call. Jitsi reports
  /// readyToClose after our own hang-up too, which must not clean up twice.
  bool get callCleanedUp => session == null;

  /// True from the moment a join starts until [cleanupAfterCall] runs.
  final isInCall = false.obs;

  CallSession markCallStarted({required String outpostId}) {
    _session?.end();
    final s = CallSession(outpostId);
    _session = s;
    _jitsiClosed = Completer<void>();
    isInCall.value = true;
    return s;
  }

  final jitsiMembers = Rx<List<JitsiMember>>([]);
  final searchedValueInMeet = Rx<String>('');
  final canTalk = false.obs;
  final keysMap = Rx<Map<String, GlobalKey>>({});

  StreamSubscription<bool>? triggerLiveDataFetchListener;
  StreamSubscription<List<LiveMember>>? membersListener;
  StreamSubscription<OutpostModel?>? outpostListener;
  StreamSubscription<int>? tickerListener;
  StreamSubscription<bool>? canTalkListener;

  bool gotMembersOnce = false;
  @override
  void onInit() {
    super.onInit();
    tickerListener = globalController.ticker.listen((d) {
      handleTimerTick();
    });
    canTalkListener = canTalk.listen((_) => _updateStageAndAudience());
    membersListener = members.listen((listOfUsers) {
      if (!gotMembersOnce) {
        _updateReactionsMap(listOfUsers);
        gotMembersOnce = true;
      }
      _syncSpeakingFlags(listOfUsers);
      _updateStageAndAudience();
    });
    outpostListener = outpost.listen((_) {
      members.value = [];
    });
  }

  /// Joins the outpost on the websocket for [callSession]. Called on every
  /// call start: rejoining sets [outpost] to the same value, so nothing keyed
  /// on it changing would fire, and the server treats the outpost as not live
  /// until someone joins it here.
  Future<void> _joinOutpostSocket(CallSession callSession) async {
    final joined = await wsClient.joinOutpost(
      callSession.outpostId,
      force: true,
      withRetry: true,
    );
    if (joined || !callSession.isActive) return;
    if (wsClient.isConnecting) {
      Toast.error(
        title: 'Connecting…',
        message: 'Please wait a moment, then try again.',
      );
      return;
    }
    Toast.error(
      title: 'Could not join the outpost',
      message: 'Please try again in a moment.',
    );
    leaveCall(askForScore: false);
  }

  @override
  void onClose() {
    super.onClose();
    gotMembersOnce = false;
    reactionsMap.value = {};
    membersListener?.cancel();
    outpostListener?.cancel();
    tickerListener?.cancel();
    canTalkListener?.cancel();
    triggerLiveDataFetchListener?.cancel();
  }

  void _syncSpeakingFlags(List<LiveMember> listOfUsers) {
    final present = <String>{};
    for (final member in listOfUsers) {
      present.add(member.uuid);
      speakingOf(member.uuid).value = member.is_speaking;
    }
    _speaking.removeWhere((uuid, _) => !present.contains(uuid));
  }

  void _updateStageAndAudience() {
    final creatorId = outpost.value?.creator_user_uuid;
    final speaking = <LiveMember>[];
    final silent = <LiveMember>[];
    final audience = <LiveMember>[];
    for (final member in members.value) {
      if (!isStageMember(member, creatorId: creatorId)) {
        audience.add(member);
      } else if (member.is_speaking) {
        speaking.add(member);
      } else {
        silent.add(member);
      }
    }
    final stage = [...speaking, ...silent];
    talkingCount.value = speaking.length;
    if (!_sameOrder(stageMembers.value, stage)) stageMembers.value = stage;
    if (!_sameOrder(audienceMembers.value, audience)) {
      audienceMembers.value = audience;
    }
  }

  static bool _sameOrder(List<LiveMember> a, List<LiveMember> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  void updateReactionsMapByWsEvent(IncomingMessage incomingMessage) {
    final reactionTypes = {
      IncomingMessageType.userLiked: OutgoingMessageTypeEnums.like,
      IncomingMessageType.userDisliked: OutgoingMessageTypeEnums.dislike,
      IncomingMessageType.userCheered: OutgoingMessageTypeEnums.cheer,
      IncomingMessageType.userBooed: OutgoingMessageTypeEnums.boo,
    };

    final reactionType = reactionTypes[incomingMessage.name];
    if (reactionType == null) return;

    final userAddress = incomingMessage.data.react_to_user_address;
    if (userAddress == null) return;
    if (reactionsMap.value[userAddress] == null) {
      reactionsMap.value[userAddress] = {};
    }
    reactionsMap.value[userAddress]![reactionType] =
        (reactionsMap.value[userAddress]![reactionType] ?? 0) + 1;

    reactionsMap.refresh();
  }

  void _updateReactionsMap(List<LiveMember> listOfUsers) {
    final Map<String, Map<OutgoingMessageTypeEnums, int>> tmp = {};

    final feedbackTypes = {
      OutgoingMessageTypeEnums.like.name: OutgoingMessageTypeEnums.like,
      OutgoingMessageTypeEnums.dislike.name: OutgoingMessageTypeEnums.dislike,
    };

    final reactionTypes = {
      OutgoingMessageTypeEnums.cheer.name: OutgoingMessageTypeEnums.cheer,
      OutgoingMessageTypeEnums.boo.name: OutgoingMessageTypeEnums.boo,
    };

    for (final user in listOfUsers) {
      for (final FeedbackModel feedback in user.feedbacks) {
        final reactionType = feedbackTypes[feedback.feedback_type];
        if (reactionType != null) {
          _updateReactionCount(tmp, feedback.user_address, reactionType);
        }
      }

      // Process reactions (cheers and boos)
      for (final UserReaction reaction in user.reactions) {
        final reactionType = reactionTypes[reaction.reaction_type];
        if (reactionType != null) {
          _updateReactionCount(tmp, reaction.user_address, reactionType);
        }
      }
    }
    reactionsMap.value = tmp;
  }

  void _updateReactionCount(
    Map<String, Map<OutgoingMessageTypeEnums, int>> reactions,
    String userAddress,
    OutgoingMessageTypeEnums type,
  ) {
    if (reactions[userAddress] == null) {
      reactions[userAddress] = {};
    }
    reactions[userAddress]![type] = (reactions[userAddress]![type] ?? 0) + 1;
  }

  /// Bumped when the local countdown changes talk times. Times are updated in
  /// place, so widgets showing them listen to this instead of [members],
  /// which keeps the whole member grid from rebuilding every second.
  final talkTimeTick = 0.obs;

  void handleTimerTick() {
    final creatorUuid = outpost.value?.creator_user_uuid;
    var changed = false;
    for (final member in members.value) {
      if (member.is_speaking == true &&
          member.remaining_time > 0 &&
          member.uuid != creatorUuid) {
        member.remaining_time--;
        changed = true;
      }
    }
    // REVIEW: running out of time is handled in ongoing_outpost_call_controller.dart
    if (changed) talkTimeTick.value++;
  }

  /// don't use withRetry, use withJoin only, if needed
  void fetchLiveData({bool? withRetry = true, bool? withJoin = false}) async {
    final callSession = session;
    if (callSession == null) return;
    final outpostId = callSession.outpostId;

    final seq = ++_liveDataSeq;
    final liveData =
        await _outpostRepository.getLatestLiveData(outpostId: outpostId);
    if (!callSession.isActive) return;
    if (liveData == null) {
      // A newer request is in flight and will decide.
      if (seq != _liveDataSeq && withJoin != true) return;
      // "Outpost is not live" until our websocket join lands; Jitsi can
      // connect before it does. Wait for the join, then ask once more.
      if (withJoin == true && withRetry == true) {
        final joined = await wsClient.joinOutpost(
          outpostId,
          force: true,
          withRetry: true,
        );
        if (!callSession.isActive) return;
        if (joined) {
          fetchLiveData(withRetry: false, withJoin: true);
          return;
        }
      }
      leaveCall(askForScore: false);
      Toast.error(
        title: 'Could not join the outpost',
        message: 'Please try again.',
      );
    } else {
      final tmp = liveData.members;
      tmp.asMap().forEach((index, element) {
        element.last_speaked_at_timestamp ??= -1 * (index);
      });
      if (withJoin == true) {
        // do i exist and is present?
        // After leaving, the server keeps us in the list with is_present false.
        final iExistAndPresent = tmp
            .any((member) => member.uuid == myId && member.is_present == true);
        if (!iExistAndPresent) {
          bool joined = false;
          try {
            joined = await wsClient.joinOutpost(outpostId,
                force: true, withRetry: true);
            if (!callSession.isActive) return;
            if (withRetry == true && joined == true) {
              fetchLiveData(withRetry: false);
              return;
            }
          } catch (e) {
            l.e('Error joining outpost: $e');
          }
          if (!callSession.isActive) return;
          if (!joined) {
            final reconnecting = wsClient.isConnecting;
            if (reconnecting) {
              Toast.error(
                title: 'Connecting…',
                message: 'Please wait a moment, then try again.',
              );
              return;
            }
            Toast.error(
              title: 'Could not join the outpost',
              message: 'Please try again.',
            );
            jitsiMeet.hangUp();
          }
        }
      }
      // Responses can arrive out of order; an older one must not overwrite
      // the members of a newer one.
      if (seq != _liveDataSeq) return;
      members.value = tmp.where((member) => member.is_present == true).toList();
    }
  }

  int _liveDataSeq = 0;

  void updateUserIsTalking({required String address, required bool isTalking}) {
    final member = members.value.firstWhereOrNull((m) => m.address == address);
    if (member == null) return;
    member.last_speaked_at_timestamp =
        DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final changed = member.is_speaking != isTalking;
    member.is_speaking = isTalking;
    speakingOf(member.uuid).value = isTalking;
    _updateStageAndAudience();
    if (changed) speakingTick.value++;
  }

  void updateUserTime({required String address, required int newTime}) {
    final member = members.value.firstWhereOrNull((m) => m.address == address);
    if (member == null) return;
    member.remaining_time = newTime;
    talkTimeTick.value++;
  }

  Future<void> cleanupAfterCall({bool askForScore = true}) async {
    final callSession = session;
    if (callSession == null) return;
    callSession.end();
    isInCall.value = false;
    haveOngoingCall.value = false;
    jitsiMembers.value = [];
    jitsiMeet.hangUp();
    members.value = [];
    searchedValueInMeet.value = '';
    final outpostId = callSession.outpostId;
    reactionsMap.value = {};
    if (Get.isRegistered<CallRoomController>()) {
      Get.delete<CallRoomController>(force: true);
    }
    final ongoing = Get.isRegistered<OngoingOutpostCallController>()
        ? Get.find<OngoingOutpostCallController>()
        : null;
    // Delayed so the call page can finish its exit transition first. Only
    // this call's controller is deleted; a call joined meanwhile has its own.
    Future.delayed(const Duration(seconds: 1), () {
      for (var i = 0;
          i < 3 &&
              Get.isRegistered<OngoingOutpostCallController>() &&
              identical(Get.find<OngoingOutpostCallController>(), ongoing);
          i++) {
        Get.delete<OngoingOutpostCallController>(force: true);
      }
    });
    sendOutpostEvent(
      outpostId: outpostId,
      eventType: OutgoingMessageTypeEnums.leave,
    );
    if (!askForScore) return;
    // Let the route change that triggered cleanup finish first.
    await WidgetsBinding.instance.endOfFrame;
    final score = await showScoreOutpostPrompt();
    if (score != null) {
      await _outpostRepository.scoreOutpost(
        outpostId: outpostId,
        score: score,
      );
    }
  }

  Future<bool> _verifyOutpostSchedule(OutpostModel outpostToJoin) async {
    final iAmCreator = outpostToJoin.creator_user_uuid == myId;
    final isScheduled = outpostToJoin.scheduled_for > 0;
    if (!iAmCreator && isScheduled) {
      try {
        final remoteOutpostData = await _outpostRepository.getOutpost(
          outpostToJoin.uuid,
        );

        if (remoteOutpostData == null) {
          Toast.error(
            title: 'Outpost Not Found',
            message: 'This outpost is no longer available',
          );
          return false;
        }
        outpost.value = remoteOutpostData;
        final outpostController = Get.find<OutpostsController>();
        outpostController.updateOutpost_local(remoteOutpostData);

        if (remoteOutpostData.is_archived) {
          Toast.error(
            title: 'Outpost Archived',
            message: 'This outpost is no longer available',
          );
          return false;
        }

        final isPassed = remoteOutpostData.scheduled_for <
            DateTime.now().millisecondsSinceEpoch;

        if (!isPassed) {
          final timeUntilStart = remainintTimeUntilMilSecondsFormated(
            time: remoteOutpostData.scheduled_for,
          );

          Toast.warning(
            title: 'Outpost Rescheduled',
            message: 'This outpost will start in $timeUntilStart',
          );
          return false;
        }

        return true;
      } catch (e) {
        l.e('Error checking outpost schedule: $e');
        Toast.error(
          title: 'Connection Error',
          message: 'Unable to verify outpost schedule',
        );
        return false;
      }
    }
    return true;
  }

  Future<void> startCall(
      {required OutpostModel outpostToJoin,
      OutpostAccesses? accessOverRides}) async {
    if (!await _leaveOtherOutpostFirst(outpostToJoin)) return;
    // The previous conference's late readyToClose would otherwise reach the
    // new call's listeners and end it.
    await waitForJitsiClosed();

    final iAmAllowedToSpeak = accessOverRides != null
        ? accessOverRides.canSpeak
        : canISpeakWithoutTicket(outpost: outpostToJoin);
    canTalk.value = iAmAllowedToSpeak;
    bool hasMicAccess = false;
    if (iAmAllowedToSpeak) {
      hasMicAccess = await getPermission(Permission.microphone);
      if (!hasMicAccess) {
        Toast.warning(
          title: 'Microphone access required',
          message: 'Please allow microphone access to speak',
        );
        canTalk.value = false;
      }
    }
    final hasNotificationPermission =
        await getPermission(Permission.notification);
    l.d("notifications allowed: $hasNotificationPermission");

    final myUser = globalController.myUserInfo.value!;

    if ((myUser.external_wallet_address == '' ||
            globalController.connectedWalletAddress.value == '') &&
        myUser.defaultWalletAddress == '') {
      Toast.warning(
        title: 'Wallet required',
        message: 'Please connect a wallet to join',
      );
      globalController.connectToWallet(
        afterConnection: () {
          startCall(
              outpostToJoin: outpostToJoin, accessOverRides: accessOverRides);
        },
      );
      return;
    }
    outpost.value = outpostToJoin;
    var options = MeetingConstants.buildMeetOptions(
      outpost: outpostToJoin,
      myUser: myUser,
      allowedToSpeak: iAmAllowedToSpeak,
    );
    try {
      // For non-creators, verify outpost availability and schedule
      final canProceed = await _verifyOutpostSchedule(outpostToJoin);
      if (!canProceed) return;

      final listeners = jitsiListeners(outpost: outpostToJoin);
      final callSession = session;
      if (callSession != null) _joinOutpostSocket(callSession);
      await jitsiMeet.join(options, listeners);
      if (Get.isRegistered<OngoingOutpostCallController>() &&
          !Get.find<OngoingOutpostCallController>().callPageOpened &&
          !callCleanedUp) {
        openCallPage();
      }

      analytics.logEvent(
        name: 'joined_group_call',
        parameters: {
          'outpost_id': outpostToJoin.uuid,
          'outpost_name': outpostToJoin.name,
          'user_id': myUser.uuid,
        },
      );
    } catch (e) {
      l.f(e.toString());
    }
  }

  /// Ends the call and takes the call page out of the stack, leaving whatever
  /// page the user is on in place.
  Future<void> leaveCall({bool askForScore = true}) async {
    closeCallPage();
    await cleanupAfterCall(askForScore: askForScore);
  }

  Completer<void>? _jitsiClosed;

  void onJitsiClosed() {
    final completer = _jitsiClosed;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  /// Completes once Jitsi has torn the previous conference down, so a new
  /// one isn't joined into a session that is still closing.
  Future<void> waitForJitsiClosed() async {
    final completer = _jitsiClosed;
    if (completer == null || completer.isCompleted) return;
    await completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () {});
  }

  /// Returns false when the user chose to stay in the outpost they're in.
  Future<bool> _leaveOtherOutpostFirst(OutpostModel outpostToJoin) async {
    final current = outpost.value;
    if (!isInCall.value || current == null) return true;
    if (current.uuid == outpostToJoin.uuid) {
      openCallPage();
      return false;
    }
    final switchOutpost = await showAppConfirm(
      title: "You're in ${current.name}",
      message: 'You can only be in one outpost at a time. '
          'Leave it and join ${outpostToJoin.name}?',
      confirmLabel: 'Leave & join',
      cancelLabel: 'Stay',
      destructive: true,
    );
    if (!switchOutpost) return false;
    await leaveCall(askForScore: false);
    await waitForJitsiClosed();
    return true;
  }
}

/// One joined call, from [OutpostCallController.markCallStarted] until
/// [OutpostCallController.cleanupAfterCall]. Leaving and rejoining creates a
/// new session, so work belonging to the old one can tell it is stale.
class CallSession {
  CallSession(this.outpostId);

  final String outpostId;
  bool _ended = false;
  final _timers = <Timer>{};

  bool get isActive => !_ended;

  /// Like [Future.delayed], but cancelled when the call ends.
  void delayed(Duration duration, void Function() action) {
    if (_ended) return;
    late final Timer timer;
    timer = Timer(duration, () {
      _timers.remove(timer);
      if (!_ended) action();
    });
    _timers.add(timer);
  }

  void end() {
    _ended = true;
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }
}

/// Creators always count as speakers; `last_speaked_at_timestamp` is only
/// positive once the member actually talked (see `fetchLiveData`).
bool isStageMember(LiveMember member, {required String? creatorId}) {
  return member.uuid == creatorId ||
      member.can_speak ||
      member.is_speaking ||
      (member.last_speaked_at_timestamp ?? 0) > 0 ||
      (member.uuid == myId && Get.find<OutpostCallController>().canTalk.value);
}

bool canISpeakWithoutTicket({required OutpostModel outpost}) =>
    TicketAccessEvaluator(outpost, myId: myId).canSpeakWithoutTicket;
