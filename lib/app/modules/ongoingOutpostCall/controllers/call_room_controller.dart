import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:ui' show Rect;

import 'package:dartx/dartx.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/constants/meeting.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

part 'call_polls.dart';
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
  bool pending;
  CallChatMessage({
    required this.id,
    required this.senderUuid,
    required this.senderName,
    required this.text,
    required this.at,
    required this.mine,
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
/// raised hands, audio levels, chat, emoji reactions, polls, screen sharing
/// and moderation.
class CallRoomController extends GetxController
    with _CallPolls, _CallScreenShare {
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

  @override
  void onReady() {
    super.onReady();
    jitsiMeet.sendPodiumCommand('requestState');
    if (Get.isRegistered<OngoingOutpostCallController>()) {
      _mutedWorker = ever<bool>(
        Get.find<OngoingOutpostCallController>().amIMuted,
        (muted) {
          if (!muted && myHandRaised) setHandRaised(false);
        },
      );
    }
  }

  @override
  void onClose() {
    _levelDecayTimer?.cancel();
    _chatPreviewTimer?.cancel();
    _mutedWorker?.dispose();
    _disposeStage();
    super.onClose();
  }

  // Identity ------------------------------------------------------------------

  @override
  String? uuidOf(String? jitsiId) {
    if (jitsiId == null) return null;
    if (jitsiId == _localJitsiId) return myId;
    return peers[jitsiId]?.uuid;
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
    peers[participantId] = _peerFrom({
      'participantId': participantId,
      'email': email,
      'name': name,
      'role': role,
    });
    _retryUnverifiedPoll();
    _onPollPeerJoined(participantId);
  }

  void onParticipantLeft(String? participantId) {
    if (participantId == null) return;
    final uuid = uuidOf(participantId);
    peers.remove(participantId);
    if (uuid != null) _setLevel(uuid, 0);
    _onPollPeerLeft(uuid);
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

  /// Moderation needs both a Podium host and a Jitsi moderator, since Jitsi
  /// enforces the latter on its side.
  bool get canModerate =>
      channelAvailable.value && amIHost && localRole.value == 'moderator';

  // Podium channel ------------------------------------------------------------

  void onPodiumEvent(String name, Map<String, dynamic> data) {
    switch (name) {
      case 'state':
        channelAvailable.value = true;
        _localJitsiId = data['localParticipantId']?.toString();
        localRole.value = data['role']?.toString();
        for (final p in (data['participants'] as List? ?? const [])) {
          if (p is Map && p['participantId'] != null) {
            final peer = _peerFrom(p);
            if (peer.jitsiId != _localJitsiId) peers[peer.jitsiId] = peer;
          }
        }
        _setRaisedHands(data['raisedHands'], notify: false);
        _retryUnverifiedPoll();
        if (data.containsKey('screenShare')) {
          _onScreenShareEvent(data['screenShare'], notify: false);
        }
        if (data['localScreenShare'] is bool) {
          _onLocalScreenShare(data['localScreenShare'] as bool);
        }
      case 'screenShare':
        _onScreenShareEvent(data['screenShare'], notify: true);
      case 'localScreenShare':
        _onLocalScreenShare(data['sharing'] == true);
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
        Toast.warning(
          title: 'Removed from the outpost',
          message: 'The host removed you from this outpost',
        );
      default:
        l.d('unhandled podium event $name');
    }
  }

  // Raised hands --------------------------------------------------------------

  List<String> get raisedHandUuids {
    final sorted = _raisedHands.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted.map((h) => uuidOf(h.jitsiId)).whereNotNull().toList();
  }

  bool isHandRaised(String uuid) => raisedHandUuids.contains(uuid);

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

  void removeParticipant(String uuid) {
    final id = jitsiIdOf(uuid);
    if (id == null) return;
    jitsiMeet.sendPodiumCommand('kickParticipant', {'participantId': id});
  }

  // Audio levels --------------------------------------------------------------

  /// One observable per member so a level change only rebuilds that member's
  /// ring. Entries are never removed: a ring may still be listening to one.
  RxDouble _levelRx(String uuid) => _shownLevels.putIfAbsent(uuid, () => 0.0.obs);

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

  void _onAudioLevels(dynamic raw) {
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
          _showReaction(
            emoji,
            displayNameOf(
              uuid: data['uid']?.toString(),
              jitsiId: senderId,
            ),
          );
        }
      case 'poll':
        _onPollMessage(senderId, data);
      case 'pollVote':
        _onPollVote(senderId, data);
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

  void setChatOpen(bool open) {
    _chatOpen = open;
    if (open) {
      unreadChat.value = 0;
      chatPreview.value = null;
    }
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
    final message = CallChatMessage(
      id: '$senderId-${DateTime.now().microsecondsSinceEpoch}',
      senderUuid: uuid,
      senderName: displayNameOf(uuid: uuid, jitsiId: senderId),
      text: text,
      at: DateTime.now(),
      mine: false,
    );
    chat.add(message);
    if (!_chatOpen) {
      unreadChat.value++;
      chatPreview.value = message;
      _chatPreviewTimer?.cancel();
      _chatPreviewTimer = Timer(const Duration(seconds: 4), () {
        if (chatPreview.value?.id == message.id) chatPreview.value = null;
      });
    }
  }
}
