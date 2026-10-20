import 'dart:math';

import 'package:podium/app/services/replay/replay_format.dart';

/// A member as shown at one moment of a replay.
class ReplayMemberState {
  final ReplayMember member;
  final bool speaking;

  /// Seconds of talk time left at this moment.
  final int remainingSeconds;

  const ReplayMemberState({
    required this.member,
    required this.speaking,
    required this.remainingSeconds,
  });
}

class ReplayChatMessage {
  final int t;
  final String? uuid;
  final String name;
  final String text;

  const ReplayChatMessage({
    required this.t,
    required this.uuid,
    required this.name,
    required this.text,
  });
}

/// Something that pops up briefly: an emoji reaction, or a like, dislike,
/// cheer or boo sent to a member.
class ReplayMoment {
  final int t;
  final String emoji;
  final String label;

  const ReplayMoment({required this.t, required this.emoji, required this.label});
}

/// The room at one moment of a replay.
class ReplayRoomState {
  final List<ReplayMemberState> members;
  final String? dominantSpeakerUuid;
  final List<String> raisedHands;

  /// Public poll snapshot, as recorded (see `PollSnapshot.toJson`).
  final Map<String, dynamic>? poll;
  final ReplayClip? clip;
  final bool online;

  const ReplayRoomState({
    this.members = const [],
    this.dominantSpeakerUuid,
    this.raisedHands = const [],
    this.poll,
    this.clip,
    this.online = true,
  });
}

enum ReplayMarkerKind { chat, reaction, poll, screenShare, offline }

class ReplayMarker {
  final int t;
  final ReplayMarkerKind kind;
  const ReplayMarker(this.t, this.kind);
}

/// Answers "what did the room look like at time t" for a replay's events.
/// Pure and synchronous, so the player can ask on every tick and seek.
class ReplayTimeline {
  static const _checkpointEvery = 200;

  static const _feedbackEmoji = {
    'user.liked': '👍',
    'user.disliked': '👎',
    'user.cheered': '🎉',
    'user.booed': '🍅',
  };
  static const _feedbackVerb = {
    'user.liked': 'liked',
    'user.disliked': 'disliked',
    'user.cheered': 'cheered',
    'user.booed': 'booed',
  };

  final List<ReplayEvent> _events;
  final List<ReplayClip> clips;
  final int durationMs;

  /// Room builders saved every [_checkpointEvery] events, with the number
  /// of events applied to each.
  final _checkpoints = <(int, _RoomBuilder)>[];
  late final List<ReplayChatMessage> chat;
  late final List<ReplayMoment> moments;
  late final List<ReplayMarker> markers;

  ReplayTimeline({
    required List<ReplayEvent> events,
    required List<ReplayClip> clips,
    required this.durationMs,
  })  : _events = events,
        clips = [...clips]..sort((a, b) => a.startMs.compareTo(b.startMs)) {
    _index();
  }

  void _index() {
    final chat = <ReplayChatMessage>[];
    final moments = <ReplayMoment>[];
    final markers = <ReplayMarker>[];
    final builder = _RoomBuilder();
    _checkpoints.add((0, builder.copy()));
    for (var i = 0; i < _events.length; i++) {
      final event = _events[i];
      final data = event.data;
      switch (event.type) {
        case ReplayEventType.chat:
          final text = data['text']?.toString() ?? '';
          if (text.isNotEmpty) {
            chat.add(ReplayChatMessage(
              t: event.t,
              uuid: data['uuid']?.toString(),
              name: _nameOr(data['name'], builder.nameOf(data['uuid'])),
              text: text,
            ));
            markers.add(ReplayMarker(event.t, ReplayMarkerKind.chat));
          }
        case ReplayEventType.reaction:
          final emoji = data['emoji']?.toString() ?? '';
          if (emoji.isNotEmpty) {
            moments.add(ReplayMoment(
              t: event.t,
              emoji: emoji,
              label: _nameOr(data['name'], builder.nameOf(data['uuid'])),
            ));
            markers.add(ReplayMarker(event.t, ReplayMarkerKind.reaction));
          }
        case ReplayEventType.ws:
          final moment = _feedbackMoment(event, builder);
          if (moment != null) {
            moments.add(moment);
            markers.add(ReplayMarker(event.t, ReplayMarkerKind.reaction));
          }
        case ReplayEventType.poll:
          final poll = data['poll'];
          final previous = builder.poll;
          if (poll is Map && previous?['id'] != poll['id']) {
            markers.add(ReplayMarker(event.t, ReplayMarkerKind.poll));
          }
        case ReplayEventType.connection:
          if (data['online'] == false) {
            markers.add(ReplayMarker(event.t, ReplayMarkerKind.offline));
          }
      }
      builder.apply(event);
      if ((i + 1) % _checkpointEvery == 0) {
        _checkpoints.add((i + 1, builder.copy()));
      }
    }
    for (final clip in clips) {
      markers.add(ReplayMarker(clip.startMs, ReplayMarkerKind.screenShare));
    }
    markers.sort((a, b) => a.t.compareTo(b.t));
    this.chat = chat;
    this.moments = moments;
    this.markers = markers;
  }

  ReplayMoment? _feedbackMoment(ReplayEvent event, _RoomBuilder builder) {
    final name = event.data['name']?.toString();
    final emoji = _feedbackEmoji[name];
    if (emoji == null) return null;
    final payload = event.data['data'];
    if (payload is! Map) return null;
    final from = builder.nameByAddress(payload['address']?.toString()) ??
        payload['name']?.toString() ??
        'Someone';
    final to = builder.nameByAddress(
          payload['react_to_user_address']?.toString(),
        ) ??
        'someone';
    final amount = payload['amount'];
    final suffix = amount is num && amount > 0 ? ' ($amount)' : '';
    return ReplayMoment(
      t: event.t,
      emoji: emoji,
      label: '$from ${_feedbackVerb[name]} $to$suffix',
    );
  }

  static String _nameOr(Object? name, String? fallback) {
    final text = name?.toString() ?? '';
    if (text.isNotEmpty) return text;
    return fallback ?? 'Someone';
  }

  ReplayRoomState stateAt(int t) {
    final applied = _countUntil(t);
    var lo = 0;
    var hi = _checkpoints.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (_checkpoints[mid].$1 <= applied) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    final (start, checkpoint) = _checkpoints[lo];
    final builder = checkpoint.copy();
    for (var i = start; i < applied; i++) {
      builder.apply(_events[i]);
    }
    return builder.build(t, clipAt(t));
  }

  ReplayClip? clipAt(int t) {
    for (final clip in clips) {
      if (clip.startMs <= t && t < (clip.endMs ?? durationMs)) return clip;
    }
    return null;
  }

  /// Chat messages sent up to [t].
  List<ReplayChatMessage> chatUntil(int t) =>
      chat.sublist(0, _upperBound(chat, t, (m) => m.t));

  /// Moments in `(from, to]`.
  List<ReplayMoment> momentsBetween(int from, int to) {
    if (to <= from) return const [];
    return moments.sublist(
      _upperBound(moments, from, (m) => m.t),
      _upperBound(moments, to, (m) => m.t),
    );
  }

  /// Number of events at or before [t].
  int _countUntil(int t) => _upperBound(_events, t, (e) => e.t);

  static int _upperBound<T>(List<T> list, int t, int Function(T) timeOf) {
    var lo = 0;
    var hi = list.length;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (timeOf(list[mid]) <= t) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}

class _Talk {
  bool speaking;

  /// Remaining seconds as of [since].
  int remaining;
  int since;

  _Talk(this.speaking, this.remaining, this.since);

  _Talk copy() => _Talk(speaking, remaining, since);

  int remainingAt(int t) {
    if (!speaking) return remaining;
    return max(0, remaining - (t - since) ~/ 1000);
  }

  void setSpeaking(bool value, int t) {
    if (speaking == value) return;
    remaining = remainingAt(t);
    since = t;
    speaking = value;
  }
}

class _RoomBuilder {
  /// Members in the order the server listed them.
  var members = <ReplayMember>[];
  var talk = <String, _Talk>{};
  var uuidByAddress = <String, String>{};
  var names = <String, String>{};
  String? dominant;
  var hands = <String>[];
  Map<String, dynamic>? poll;
  var online = true;

  _RoomBuilder();

  _RoomBuilder copy() => _RoomBuilder()
    ..members = [...members]
    ..talk = {for (final e in talk.entries) e.key: e.value.copy()}
    ..uuidByAddress = {...uuidByAddress}
    ..names = {...names}
    ..dominant = dominant
    ..hands = [...hands]
    ..poll = poll
    ..online = online;

  String? nameOf(Object? uuid) => uuid == null ? null : names[uuid.toString()];

  String? nameByAddress(String? address) {
    final uuid = address == null ? null : uuidByAddress[address];
    return uuid == null ? null : names[uuid];
  }

  void apply(ReplayEvent event) {
    final data = event.data;
    switch (event.type) {
      case ReplayEventType.members:
        _setMembers(event.t, data['members']);
      case ReplayEventType.ws:
        _applyWs(event.t, data['name']?.toString(), data['data']);
      case ReplayEventType.poll:
        final value = data['poll'];
        poll = value is Map ? Map<String, dynamic>.from(value) : null;
      case ReplayEventType.hands:
        final uuids = data['uuids'];
        hands = uuids is List ? [for (final u in uuids) u.toString()] : [];
      case ReplayEventType.dominantSpeaker:
        dominant = data['uuid']?.toString();
      case ReplayEventType.connection:
        online = data['online'] != false;
    }
  }

  void _setMembers(int t, Object? raw) {
    if (raw is! List) return;
    final next = <ReplayMember>[];
    final nextTalk = <String, _Talk>{};
    for (final item in raw) {
      final member = ReplayMember.tryParse(item);
      if (member == null) continue;
      next.add(member);
      nextTalk[member.uuid] = _Talk(member.isSpeaking, member.remainingTime, t);
      if (member.address.isNotEmpty) uuidByAddress[member.address] = member.uuid;
      if (member.name.isNotEmpty) names[member.uuid] = member.name;
    }
    members = next;
    talk = nextTalk;
  }

  void _applyWs(int t, String? name, Object? payload) {
    if (payload is! Map) return;
    final address = payload['address']?.toString();
    final uuid = address == null ? null : uuidByAddress[address];
    switch (name) {
      case 'user.started_speaking':
      case 'user.stopped_speaking':
        if (uuid != null) {
          talk[uuid]?.setSpeaking(name == 'user.started_speaking', t);
        }
      case 'remaining_time.updated':
        final remaining = payload['remaining_time'];
        final state = uuid == null ? null : talk[uuid];
        if (state != null && remaining is num) {
          state
            ..remaining = remaining.toInt()
            ..since = t;
        }
      case 'user.time_is_up':
        if (uuid != null) talk[uuid]?.setSpeaking(false, t);
      case 'user.joined':
        final joinedUuid = payload['uuid']?.toString();
        if (joinedUuid == null || address == null) return;
        uuidByAddress[address] = joinedUuid;
        final joinedName = payload['name']?.toString() ?? '';
        if (joinedName.isNotEmpty) names[joinedUuid] = joinedName;
        if (members.any((m) => m.uuid == joinedUuid)) return;
        members = [
          ...members,
          ReplayMember(
            uuid: joinedUuid,
            address: address,
            name: joinedName,
            image: payload['image']?.toString(),
          ),
        ];
        talk[joinedUuid] = _Talk(false, 0, t);
      case 'user.left':
        if (uuid == null) return;
        members = members.where((m) => m.uuid != uuid).toList();
        talk.remove(uuid);
    }
  }

  ReplayRoomState build(int t, ReplayClip? clip) {
    return ReplayRoomState(
      members: [
        for (final member in members)
          ReplayMemberState(
            member: member,
            speaking: talk[member.uuid]?.speaking ?? false,
            remainingSeconds: talk[member.uuid]?.remainingAt(t) ?? 0,
          ),
      ],
      dominantSpeakerUuid: dominant,
      raisedHands: hands,
      poll: poll,
      clip: clip,
      online: online,
    );
  }
}
