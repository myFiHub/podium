import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:ui' show Rect;

import 'package:dartx/dartx.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/services/blocked_users_service.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/outpost_moderation.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/breakout_sheet.dart'
    show enterBreakoutRoom;
import 'package:podium/app/services/replay/replay_recorder.dart';
import 'package:podium/constants/meeting.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/podium/models/breakout/breakout_access.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost_ban.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

part 'call_audio_route.dart';
part 'call_breakout.dart';
part 'call_connection.dart';
part 'call_moderation.dart';
part 'call_music.dart';
part 'call_polls.dart';
part 'call_private_chat.dart';
part 'call_screen_share.dart';

class CallPeer {
  final String jitsiId;
  final String? uuid;
  final String? name;
  final String? role;
  const CallPeer({required this.jitsiId, this.uuid, this.name, this.role});

  CallPeer withRole(String? role) =>
      CallPeer(jitsiId: jitsiId, uuid: uuid, name: name, role: role);
}

class CallChatMessage {
  final String id;
  final String? senderUuid;
  final String senderName;
  final String text;
  final DateTime at;
  final bool mine;

  /// A notice from the app (e.g. a room switch) rather than a person.
  final bool system;

  /// Only shown as a preview of a private message from [senderUuid].
  final bool private;
  bool pending;
  CallChatMessage({
    required this.id,
    required this.senderUuid,
    required this.senderName,
    required this.text,
    required this.at,
    required this.mine,
    this.system = false,
    this.private = false,
    this.pending = false,
  });
}

class FloatingReaction {
  final int id;
  final String emoji;
  final String senderName;
  final double lane;
  const FloatingReaction({
    required this.id,
    required this.emoji,
    required this.senderName,
    required this.lane,
  });
}

CallRoomController? findCallRoom() => Get.isRegistered<CallRoomController>()
    ? Get.find<CallRoomController>()
    : null;

/// Room-level state that lives in Jitsi rather than in the Podium backend:
/// raised hands, audio levels, chat, emoji reactions, polls, screen sharing,
/// moderation, audio routes, connection quality, breakout rooms and music.
class CallRoomController extends GetxController
    with
        _CallPolls,
        _CallScreenShare,
        _CallAudioRoute,
        _CallConnection,
        _CallBreakout,
        _CallMusic,
        _CallModeration,
        _CallPrivateChat {
  static const reactionEmojis = [
    '❤️',
    '🔥',
    '😂',
    '👏',
    '😮',
    '💯',
    '🙏',
    '👎'
  ];
  static const _envelopeVersion = 1;
  static const _maxChatLength = 1000;

  final _callController = Get.find<OutpostCallController>();

  /// True once the Jitsi SDK answered over the Podium channel; older SDK
  /// builds don't have it, so hands and moderation stay hidden there.
  final channelAvailable = false.obs;
  final peers = <String, CallPeer>{}.obs;
  @override
  final localRole = RxnString();
  String? _localJitsiId;

  final _raisedHands = <({String jitsiId, int timestamp})>[].obs;
  final _audioLevels = <String, double>{};
  final _shownLevels = <String, RxDouble>{};
  final dominantSpeakerUuid = RxnString();

  final chat = <CallChatMessage>[].obs;
  final unreadChat = 0.obs;
  final chatPreview = Rxn<CallChatMessage>();
  bool _chatOpen = false;
  Timer? _chatPreviewTimer;

  final reactions = <FloatingReaction>[].obs;
  final reactionTrayOpen = false.obs;
  int _reactionSeq = 0;
  DateTime _lastReactionSentAt = DateTime.fromMillisecondsSinceEpoch(0);
  final _random = Random();

  Timer? _levelDecayTimer;
  Worker? _mutedWorker;
  late final Worker _handsWorker;
  void Function()? _disposePollRecording;

  /// Every jitsiId -> uuid seen in this call, kept after a peer leaves so
  /// people in other breakout rooms can still be matched to members.
  final _seenUuids = <String, String>{};

  @override
  void onInit() {
    super.onInit();
    _initMusic();
    _handsWorker = everAll([_raisedHands, peers], (_) => _refreshHandUuids());
    _disposePollRecording = activePoll.addListener(
      () => ReplayRecorder.instance.onPoll(activePoll.value),
    );
    Get.find<BlockedUsersService>().ensureLoaded();
  }

  @override
  void onReady() {
    super.onReady();
    jitsiMeet.sendPodiumCommand('requestState');
    refreshBreakoutAccess();
    if (Get.isRegistered<OngoingOutpostCallController>()) {
      _mutedWorker = ever<bool>(
        Get.find<OngoingOutpostCallController>().amIMuted,
        (muted) {
          if (!muted && myHandRaised) setHandRaised(false);
          _applyMusicVolume();
        },
      );
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (!isClosed && !iControlMusic) _requestMusicState();
    });
  }

  @override
  void onClose() {
    _levelDecayTimer?.cancel();
    _chatPreviewTimer?.cancel();
    _mutedWorker?.dispose();
    _handsWorker.dispose();
    _disposePollRecording?.call();
    _disposeStage();
    _disposeMusic();
    _disposePrivateChat();
    _disposeBreakout();
    super.onClose();
  }

  @override
  bool get _micLive {
    if (!Get.isRegistered<OngoingOutpostCallController>()) return false;
    return !Get.find<OngoingOutpostCallController>().amIMuted.value &&
        _callController.canTalk.value;
  }

  // Identity ------------------------------------------------------------------

  @override
  String? uuidOf(String? jitsiId) {
    if (jitsiId == null) return null;
    if (jitsiId == _localJitsiId) return myId;
    return peers[jitsiId]?.uuid;
  }

  /// Like [uuidOf], but also knows peers that have left this room.
  @override
  String? knownUuidOf(String jitsiId) => uuidOf(jitsiId) ?? _seenUuids[jitsiId];

  void _rememberPeer(CallPeer peer) {
    final uuid = peer.uuid;
    if (uuid != null) _seenUuids[peer.jitsiId] = uuid;
  }

  /// Uuids of the people in this device's Jitsi room, or null in the main
  /// room, where everyone in the outpost is shown.
  Set<String>? get breakoutPresence {
    if (!inBreakoutRoom) return null;
    return {
      myId,
      for (final peer in peers.values)
        if (peer.uuid != null) peer.uuid!,
    };
  }

  @override
  String? jitsiIdOf(String uuid) {
    if (uuid == myId) return _localJitsiId;
    return peers.values.firstOrNullWhere((p) => p.uuid == uuid)?.jitsiId;
  }

  @override
  String displayNameOf({String? uuid, String? jitsiId}) {
    final id = uuid ?? uuidOf(jitsiId);
    if (id == myId) return 'You';
    final member =
        _callController.members.value.firstOrNullWhere((m) => m.uuid == id);
    return member?.name ?? peers[jitsiId]?.name ?? 'Someone';
  }

  CallPeer _peerFrom(Map info) {
    final email = info['email']?.toString() ?? '';
    return CallPeer(
      jitsiId: info['participantId'].toString(),
      uuid: email.contains('@') ? transformEmailLikeToId(email) : null,
      name: info['name']?.toString() ?? info['displayName']?.toString(),
      role: info['role']?.toString(),
    );
  }

  void onParticipantJoined({
    String? email,
    String? name,
    String? role,
    String? participantId,
  }) {
    if (participantId == null) return;
    final peer = _peerFrom({
      'participantId': participantId,
      'email': email,
      'name': name,
      'role': role,
    });
    peers[participantId] = peer;
    _rememberPeer(peer);
    _onModerationPeerJoined(peer.uuid);
    _retryUnverifiedPoll();
    _onPollPeerJoined(participantId);
    _onMusicPeerJoined(participantId);
  }

  void onParticipantLeft(String? participantId) {
    if (participantId == null) return;
    final uuid = uuidOf(participantId);
    peers.remove(participantId);
    if (uuid != null) _setLevel(uuid, 0);
    _forgetQuality(uuid);
    _onPollPeerLeft(uuid);
  }

  /// Called once this device is in another Jitsi room (breakout or main).
  /// Chat and polls belong to the room that was left.
  @override
  void _onRoomSwitched(BreakoutRoom? room) {
    for (final uuid in _audioLevels.keys.toList()) {
      _setLevel(uuid, 0);
    }
    final poll = activePoll.value;
    if (poll != null && poll.isOpen && !iOwnActivePoll) {
      activePoll.value = poll.copyWith(status: PollStatus.ended);
    }
    chat.clear();
    unreadChat.value = 0;
    chatPreview.value = null;
    final label = room?.label ?? 'another room';
    Toast.info(title: 'Room changed', message: 'You joined $label');
    chat.add(CallChatMessage(
      id: 'system-${DateTime.now().microsecondsSinceEpoch}',
      senderUuid: null,
      senderName: '',
      text: 'You joined $label',
      at: DateTime.now(),
      mine: false,
      system: true,
    ));
    if (!iControlMusic) {
      musicControllerUuid.value = null;
      _stopMusicLocally();
      Future.delayed(const Duration(seconds: 2), () {
        if (!isClosed) _requestMusicState();
      });
    }
  }

  // Permissions ---------------------------------------------------------------

  @override
  bool isHostUuid(String? uuid) {
    final outpost = _callController.outpost.value;
    if (outpost == null || uuid == null) return false;
    return outpost.creator_user_uuid == uuid ||
        (outpost.cohost_user_uuids ?? const []).contains(uuid);
  }

  @override
  bool get amIHost => isHostUuid(myId);

  @override
  String? get _callOutpostId => _callController.session?.outpostId;

  /// Moderation needs both a Podium host and a Jitsi moderator, since Jitsi
  /// enforces the latter on its side.
  @override
  bool get canModerate =>
      channelAvailable.value && amIHost && localRole.value == 'moderator';

  // Podium channel ------------------------------------------------------------

  void onPodiumEvent(String name, Map<String, dynamic> data) {
    if (name != 'audioLevels') l.d('[podium] $name $data');
    switch (name) {
      case 'state':
        channelAvailable.value = true;
        _localJitsiId = data['localParticipantId']?.toString();
        localRole.value = data['role']?.toString();
        // A full snapshot, sent again after every room switch: anyone not in
        // it is in another room now.
        final next = <String, CallPeer>{};
        for (final p in (data['participants'] as List? ?? const [])) {
          if (p is Map && p['participantId'] != null) {
            final peer = _peerFrom(p);
            if (peer.jitsiId != _localJitsiId) {
              next[peer.jitsiId] = peer;
              _rememberPeer(peer);
            }
          }
        }
        for (final gone in peers.keys.where((id) => !next.containsKey(id))) {
          final uuid = uuidOf(gone);
          if (uuid != null) {
            _setLevel(uuid, 0);
            _forgetQuality(uuid);
          }
        }
        peers.assignAll(next);
        _setRaisedHands(data['raisedHands'], notify: false);
        if (data.containsKey('audioDevices')) {
          _onAudioDevices(data['audioDevices']);
        }
        _onBreakoutCapabilities(data);
        if (data.containsKey('breakoutRooms')) {
          _onBreakoutRooms(data['breakoutRooms']);
        }
        _retryUnverifiedPoll();
        if (data.containsKey('screenShare')) {
          _onScreenShareEvent(data['screenShare'], notify: false);
        }
        if (data['localScreenShare'] is bool) {
          _onLocalScreenShare(
            data['localScreenShare'] as bool,
            data['localScreenShareTrackId']?.toString(),
          );
        }
      case 'screenShare':
        _onScreenShareEvent(data['screenShare'], notify: true);
      case 'localScreenShare':
        _onLocalScreenShare(
          data['sharing'] == true,
          data['trackId']?.toString(),
        );
      case 'stageVideoSize':
        _onStageVideoSize(data);
      case 'raisedHands':
        channelAvailable.value = true;
        _setRaisedHands(data['raisedHands'], notify: true);
      case 'audioLevels':
        _onAudioLevels(data['levels']);
      case 'dominantSpeaker':
        dominantSpeakerUuid.value = data['silence'] == true
            ? null
            : uuidOf(data['participantId']?.toString());
        ReplayRecorder.instance.onDominantSpeaker(dominantSpeakerUuid.value);
      case 'roleChanged':
        final id = data['participantId']?.toString();
        if (data['isLocal'] == true || id == _localJitsiId) {
          localRole.value = data['role']?.toString();
        } else if (id != null && peers[id] != null) {
          peers[id] = peers[id]!.withRole(data['role']?.toString());
        }
      case 'mutedByModerator':
        if (data['mediaType'] == null || data['mediaType'] == 'audio') {
          Toast.info(
            title: 'You were muted',
            message: 'The host muted your microphone',
          );
        }
      case 'kicked':
        // A removal through Podium already explains itself in a dialog.
        final outpostId = _callOutpostId;
        if (outpostId == null || wsClient.joinRejectionFor(outpostId) == null) {
          Toast.warning(
            title: 'Removed from the outpost',
            message: 'The host removed you from this outpost',
          );
        }
      case 'audioDevices':
        _onAudioDevices(data['devices']);
      case 'connection':
        _onConnectionState(data);
      case 'connectionQuality':
        _onConnectionQuality(data);
      case 'breakoutRooms':
        _onBreakoutRooms(data);
      case 'breakoutMoveRequested':
        _onProtectedMoveRequested(data);
      case 'breakoutJoinDenied':
        _onBreakoutJoinDenied(data);
      default:
        l.d('unhandled podium event $name');
    }
  }

  /// Podium server events about this call that aren't outpost updates.
  void onServerEvent(String name, Map<String, dynamic> data) {
    if (name.startsWith('private_message.')) {
      _onPrivateMessageEvent(name, data);
    } else if (name == 'breakout_rooms.updated') {
      _onBreakoutAccessEvent(data);
    }
  }

  // Raised hands --------------------------------------------------------------

  /// Uuids with a raised hand, oldest first. Recomputed only when hands or
  /// peers change, since every avatar asks [isHandRaised] while building.
  final _handUuids = <String>[].obs;

  List<String> get raisedHandUuids => _handUuids;

  bool isHandRaised(String uuid) => _handUuids.contains(uuid);

  void _refreshHandUuids() {
    final sorted = _raisedHands.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _handUuids.assignAll(
      sorted.map((h) => uuidOf(h.jitsiId)).whereNotNull(),
    );
    ReplayRecorder.instance.onHands(_handUuids);
  }

  bool get myHandRaised {
    final hands = _raisedHands.toList();
    return _localJitsiId != null &&
        hands.any((h) => h.jitsiId == _localJitsiId);
  }

  void _setRaisedHands(dynamic raw, {required bool notify}) {
    if (raw is! List) return;
    final before = _raisedHands.map((h) => h.jitsiId).toSet();
    final next = <({String jitsiId, int timestamp})>[];
    for (final item in raw) {
      if (item is! Map || item['participantId'] == null) continue;
      final ts = item['raisedHandTimestamp'];
      if (ts is num && ts <= 0) continue;
      next.add((
        jitsiId: item['participantId'].toString(),
        timestamp: ts is num ? ts.toInt() : 0,
      ));
    }
    _raisedHands.assignAll(next);
    if (!notify || !amIHost) return;
    for (final hand in next) {
      if (!before.contains(hand.jitsiId) && hand.jitsiId != _localJitsiId) {
        Toast.info(
          title: '✋ Hand raised',
          message: '${displayNameOf(jitsiId: hand.jitsiId)} raised their hand',
        );
      }
    }
  }

  void setHandRaised(bool raised) {
    jitsiMeet.sendPodiumCommand('raiseHand', {'raised': raised});
  }

  void toggleHand() => setHandRaised(!myHandRaised);

  void lowerHand(String uuid) {
    final id = jitsiIdOf(uuid);
    if (id == null) return;
    jitsiMeet.sendPodiumCommand('lowerHand', {'participantId': id});
  }

  void lowerAllHands() => jitsiMeet.sendPodiumCommand('lowerAllHands');

  // Moderation ----------------------------------------------------------------

  void muteParticipant(String uuid) {
    final id = jitsiIdOf(uuid);
    if (id == null) return;
    jitsiMeet.sendPodiumCommand('muteParticipant', {'participantId': id});
  }

  void muteEveryone() => jitsiMeet.sendPodiumCommand('muteEveryone');

  /// Removes (for [kickDuration]) or blocks [uuid] on the server, which
  /// disconnects them everywhere, then takes them out of the Jitsi room.
  /// False if the server refused; the host has been told why.
  Future<bool> removeFromOutpost(
    String uuid, {
    required OutpostBanKind kind,
    String? reason,
  }) async {
    final outpostId = _callOutpostId;
    if (outpostId == null) return false;
    final ban = await banFromOutpost(
      outpostId: outpostId,
      userId: uuid,
      kind: kind,
      reason: reason,
    );
    if (ban == null || isClosed) return ban != null;
    _markRemovedByMe(uuid, ban);
    return true;
  }

  // Audio levels --------------------------------------------------------------

  /// One observable per member so a level change only rebuilds that member's
  /// ring. Entries are never removed: a ring may still be listening to one.
  RxDouble _levelRx(String uuid) =>
      _shownLevels.putIfAbsent(uuid, () => 0.0.obs);

  double levelOf(String uuid) => _levelRx(uuid).value;

  void _setLevel(String uuid, double level) {
    if (level > 0.02) {
      _audioLevels[uuid] = level;
    } else {
      _audioLevels.remove(uuid);
      level = 0;
    }
    // Rx only notifies on change, so steps of 0.1 skip imperceptible updates.
    _levelRx(uuid).value = (level * 10).round() / 10;
  }

  DateTime _lastLevelsLog = DateTime(0);

  void _onAudioLevels(dynamic raw) {
    if (DateTime.now().difference(_lastLevelsLog).inSeconds >= 2) {
      _lastLevelsLog = DateTime.now();
      l.d('[levels] raw=$raw local=$_localJitsiId mapped='
          '${raw is Map ? raw.keys.map((k) => '$k->${uuidOf(k.toString())}').toList() : null}');
    }
    if (raw is! Map) return;
    raw.forEach((jitsiId, level) {
      final uuid = uuidOf(jitsiId.toString());
      if (uuid == null || level is! num) return;
      _setLevel(uuid, level.toDouble().clamp(0, 1));
    });
    if (_audioLevels.isEmpty) return;
    _levelDecayTimer ??= Timer.periodic(
      const Duration(milliseconds: 150),
      (_) => _decayLevels(),
    );
  }

  void _decayLevels() {
    for (final entry in _audioLevels.entries.toList()) {
      _setLevel(entry.key, entry.value * 0.75);
    }
    if (_audioLevels.isEmpty) {
      _levelDecayTimer?.cancel();
      _levelDecayTimer = null;
    }
  }

  // Emoji reactions -----------------------------------------------------------

  void sendReaction(String emoji) {
    if (!reactionEmojis.contains(emoji)) return;
    final now = DateTime.now();
    if (now.difference(_lastReactionSentAt).inMilliseconds < 250) return;
    _lastReactionSentAt = now;
    _showReaction(emoji, 'You');
    ReplayRecorder.instance.onReaction(
      uuid: myId,
      name: myUser.name ?? '',
      emoji: emoji,
    );
    jitsiMeet.sendEndpointTextMessage(
      message: jsonEncode({
        'podium': _envelopeVersion,
        't': 'reaction',
        'uid': myId,
        'e': emoji,
      }),
    );
  }

  void onEndpointMessage(String senderId, String message) {
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map<String, dynamic>) return;
      data = decoded;
    } catch (_) {
      return;
    }
    if (data['podium'] != _envelopeVersion) return;
    switch (data['t']) {
      case 'reaction':
        final emoji = data['e'];
        if (emoji is String && reactionEmojis.contains(emoji)) {
          final uuid = uuidOf(senderId) ?? data['uid']?.toString();
          final name = displayNameOf(uuid: uuid, jitsiId: senderId);
          _showReaction(emoji, name);
          ReplayRecorder.instance.onReaction(
            uuid: uuid,
            name: name,
            emoji: emoji,
          );
        }
      case 'poll':
        _onPollMessage(senderId, data);
      case 'pollVote':
        _onPollVote(senderId, data);
      case 'music':
        _onMusicMessage(senderId, data);
      case 'musicRequest':
        _onMusicRequest(senderId);
    }
  }

  void _showReaction(String emoji, String senderName) {
    final reaction = FloatingReaction(
      id: _reactionSeq++,
      emoji: emoji,
      senderName: senderName,
      lane: _random.nextDouble(),
    );
    if (reactions.length > 30) reactions.removeAt(0);
    reactions.add(reaction);
    Future.delayed(const Duration(milliseconds: 2800), () {
      reactions.removeWhere((r) => r.id == reaction.id);
    });
  }

  // Chat ----------------------------------------------------------------------

  /// Room chat and private messages not seen yet, for badges.
  int get unreadTotal => unreadChat.value + unreadPrivate.value;

  void setChatOpen(bool open) {
    _chatOpen = open;
    if (open) {
      unreadChat.value = 0;
      chatPreview.value = null;
    } else {
      setOpenPrivateThread(null);
    }
  }

  @override
  void _showPrivatePreview(String peerUuid, String name, String text) {
    if (_chatOpen) return;
    final message = CallChatMessage(
      id: 'pm-$peerUuid-${DateTime.now().microsecondsSinceEpoch}',
      senderUuid: peerUuid,
      senderName: name,
      text: text,
      at: DateTime.now(),
      mine: false,
      private: true,
    );
    _showChatPreview(message);
  }

  void _showChatPreview(CallChatMessage message) {
    chatPreview.value = message;
    _chatPreviewTimer?.cancel();
    _chatPreviewTimer = Timer(const Duration(seconds: 4), () {
      if (chatPreview.value?.id == message.id) chatPreview.value = null;
    });
  }

  /// Blocks [uuid] and drops what they said in this call.
  Future<bool> blockUser(String uuid) async {
    final member =
        _callController.members.value.firstOrNullWhere((m) => m.uuid == uuid);
    final ok = await Get.find<BlockedUsersService>().block(
      uuid,
      name: member?.name ?? displayNameOf(uuid: uuid),
      image: member?.image,
    );
    if (!ok || isClosed) return ok;
    chat.removeWhere((m) => m.senderUuid == uuid && !m.mine);
    clearPrivateThread(uuid);
    if (chatPreview.value?.senderUuid == uuid) chatPreview.value = null;
    return true;
  }

  void sendChat(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    final clipped =
        text.length > _maxChatLength ? text.substring(0, _maxChatLength) : text;
    chat.add(CallChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      senderUuid: myId,
      senderName: 'You',
      text: clipped,
      at: DateTime.now(),
      mine: true,
      pending: true,
    ));
    ReplayRecorder.instance.onChat(
      uuid: myId,
      name: myUser.name ?? '',
      text: clipped,
    );
    jitsiMeet.sendChatMessage(message: clipped);
  }

  void onChatMessage(String senderId, String text, bool isPrivate) {
    final fromMe = senderId == _localJitsiId;
    final echo = chat.lastOrNullWhere((m) =>
        m.mine &&
        m.pending &&
        m.text == text &&
        DateTime.now().difference(m.at).inSeconds < 30);
    if (echo != null && (fromMe || _localJitsiId == null)) {
      echo.pending = false;
      chat.refresh();
      return;
    }
    if (fromMe) return;
    final uuid = uuidOf(senderId);
    if (Get.find<BlockedUsersService>().isBlocked(uuid)) return;
    final message = CallChatMessage(
      id: '$senderId-${DateTime.now().microsecondsSinceEpoch}',
      senderUuid: uuid,
      senderName: displayNameOf(uuid: uuid, jitsiId: senderId),
      text: text,
      at: DateTime.now(),
      mine: false,
    );
    chat.add(message);
    ReplayRecorder.instance.onChat(
      uuid: uuid,
      name: message.senderName,
      text: text,
    );
    if (!_chatOpen) {
      unreadChat.value++;
      _showChatPreview(message);
    }
  }
}
