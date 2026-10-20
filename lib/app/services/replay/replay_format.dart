import 'dart:convert';

/// On-disk layout of a replay. A replay is a folder while it lives on this
/// device and an uncompressed zip with the `.podium` extension when shared:
///
/// ```
/// meta.json       ReplayMeta
/// audio.m4a       call audio, the replay's clock
/// events.jsonl    one ReplayEvent per line, in time order
/// screen/clip_NNN.mp4
/// ```
///
/// Only the folder has `state.json`, the raw audio chunks and screen frames;
/// they're never exported.
abstract final class ReplayFormat {
  static const name = 'podium.replay';
  static const version = 1;
  static const extension = 'podium';
  static const mimeType = 'application/vnd.podium.replay';

  static const meta = 'meta.json';
  static const state = 'state.json';
  static const events = 'events.jsonl';
  static const audio = 'audio.m4a';
  static const audioChunks = 'audio';
  static const screen = 'screen';

  static String clipFile(int index) => '$screen/clip_${_pad(index)}.mp4';

  static String clipFrames(int index) => '$screen/clip_${_pad(index)}_frames';

  /// Files that make up a shared replay, besides its clips.
  static const exported = [meta, audio, events];

  static String _pad(int index) => index.toString().padLeft(3, '0');
}

abstract final class ReplayEventType {
  /// Who is in the room: `{members: [ReplayMember]}`. Written when the
  /// recording starts and whenever the member list changes.
  static const members = 'members';

  /// A Podium server event: `{name, data}` with the websocket payload.
  static const ws = 'ws';

  /// `{uuid, name, text}`
  static const chat = 'chat';

  /// `{uuid, name, emoji}`
  static const reaction = 'reaction';

  /// `{poll}`, the poll's public snapshot, or null when it's gone.
  static const poll = 'poll';

  /// `{uuids}`, raised hands, oldest first.
  static const hands = 'hands';

  /// `{uuid}`, null during silence.
  static const dominantSpeaker = 'dominant_speaker';

  /// `{clip, uuid, name}` when a share starts; `{clip: null}` when it stops.
  static const screenShare = 'screen_share';

  /// `{online}`, the recorder's own connection to the Podium server.
  static const connection = 'connection';
}

class ReplayEvent {
  /// Milliseconds since the recording started.
  final int t;
  final String type;
  final Map<String, dynamic> data;

  const ReplayEvent(this.t, this.type, this.data);

  Map<String, dynamic> toJson() => {'t': t, 'type': type, 'data': data};

  String toLine() => '${jsonEncode(toJson())}\n';

  static ReplayEvent? tryParse(Object? json) {
    if (json is! Map) return null;
    final t = json['t'];
    final type = json['type'];
    final data = json['data'];
    if (t is! num || t < 0 || type is! String) return null;
    return ReplayEvent(
      t.toInt(),
      type,
      data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }

  /// Parses an events file, skipping malformed lines such as a line cut off
  /// by a crash. Events are returned in time order.
  static List<ReplayEvent> parseLines(String content) {
    final events = <ReplayEvent>[];
    for (final line in const LineSplitter().convert(content)) {
      if (line.trim().isEmpty) continue;
      try {
        final event = tryParse(jsonDecode(line));
        if (event != null) events.add(event);
      } on FormatException {
        continue;
      }
    }
    // A stable sort keeps the recorded order of events with the same time.
    final indexed = events.asMap().entries.toList()
      ..sort((a, b) {
        final byTime = a.value.t.compareTo(b.value.t);
        return byTime != 0 ? byTime : a.key.compareTo(b.key);
      });
    return [for (final e in indexed) e.value];
  }
}

class ReplayMember {
  final String uuid;
  final String address;
  final String name;
  final String? image;
  final bool canSpeak;
  final bool isSpeaking;

  /// Talk time left, in seconds, when this snapshot was taken.
  final int remainingTime;

  const ReplayMember({
    required this.uuid,
    required this.address,
    required this.name,
    this.image,
    this.canSpeak = false,
    this.isSpeaking = false,
    this.remainingTime = 0,
  });

  ReplayMember copyWith({bool? isSpeaking, int? remainingTime}) =>
      ReplayMember(
        uuid: uuid,
        address: address,
        name: name,
        image: image,
        canSpeak: canSpeak,
        isSpeaking: isSpeaking ?? this.isSpeaking,
        remainingTime: remainingTime ?? this.remainingTime,
      );

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'address': address,
        'name': name,
        if (image != null && image!.isNotEmpty) 'image': image,
        'can_speak': canSpeak,
        'is_speaking': isSpeaking,
        'remaining_time': remainingTime,
      };

  static ReplayMember? tryParse(Object? json) {
    if (json is! Map) return null;
    final uuid = json['uuid'];
    if (uuid is! String || uuid.isEmpty) return null;
    final remaining = json['remaining_time'];
    return ReplayMember(
      uuid: uuid,
      address: json['address']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
      canSpeak: json['can_speak'] == true,
      isSpeaking: json['is_speaking'] == true,
      remainingTime: remaining is num ? remaining.toInt() : 0,
    );
  }
}

class ReplayPerson {
  final String uuid;
  final String name;
  final String? image;

  const ReplayPerson({required this.uuid, required this.name, this.image});

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'name': name,
        if (image != null && image!.isNotEmpty) 'image': image,
      };

  static ReplayPerson? tryParse(Object? json) {
    if (json is! Map) return null;
    final uuid = json['uuid'];
    if (uuid is! String) return null;
    return ReplayPerson(
      uuid: uuid,
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
    );
  }
}

class ReplayOutpost {
  final String uuid;
  final String name;
  final String subject;
  final String? image;
  final ReplayPerson creator;

  const ReplayOutpost({
    required this.uuid,
    required this.name,
    required this.subject,
    required this.creator,
    this.image,
  });

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'name': name,
        'subject': subject,
        if (image != null && image!.isNotEmpty) 'image': image,
        'creator': creator.toJson(),
      };

  static ReplayOutpost? tryParse(Object? json) {
    if (json is! Map) return null;
    final uuid = json['uuid'];
    final name = json['name'];
    final creator = ReplayPerson.tryParse(json['creator']);
    if (uuid is! String || name is! String || creator == null) return null;
    return ReplayOutpost(
      uuid: uuid,
      name: name,
      subject: json['subject']?.toString() ?? '',
      image: json['image']?.toString(),
      creator: creator,
    );
  }
}

/// A screen share, recorded as frames during the call and encoded to an MP4
/// afterwards.
class ReplayClip {
  final int index;

  /// Replay time the share started and stopped. [endMs] is null while the
  /// share is still being recorded.
  final int startMs;
  final int? endMs;
  final String sharerUuid;
  final String sharerName;
  final int width;
  final int height;

  /// True once [ReplayFormat.clipFile] exists.
  final bool encoded;

  const ReplayClip({
    required this.index,
    required this.startMs,
    required this.sharerUuid,
    required this.sharerName,
    this.endMs,
    this.width = 0,
    this.height = 0,
    this.encoded = false,
  });

  String get file => ReplayFormat.clipFile(index);
  String get framesDir => ReplayFormat.clipFrames(index);

  ReplayClip copyWith({int? endMs, int? width, int? height, bool? encoded}) =>
      ReplayClip(
        index: index,
        startMs: startMs,
        endMs: endMs ?? this.endMs,
        sharerUuid: sharerUuid,
        sharerName: sharerName,
        width: width ?? this.width,
        height: height ?? this.height,
        encoded: encoded ?? this.encoded,
      );

  Map<String, dynamic> toJson() => {
        'index': index,
        'file': file,
        'start_ms': startMs,
        if (endMs != null) 'end_ms': endMs,
        'sharer_uuid': sharerUuid,
        'sharer_name': sharerName,
        'width': width,
        'height': height,
        'encoded': encoded,
      };

  static ReplayClip? tryParse(Object? json) {
    if (json is! Map) return null;
    final index = json['index'];
    final start = json['start_ms'];
    final end = json['end_ms'];
    if (index is! int || index < 1 || index > 999) return null;
    if (start is! num || start < 0) return null;
    if (end != null && (end is! num || end < start)) return null;
    final width = json['width'];
    final height = json['height'];
    return ReplayClip(
      index: index,
      startMs: start.toInt(),
      endMs: (end as num?)?.toInt(),
      sharerUuid: json['sharer_uuid']?.toString() ?? '',
      sharerName: json['sharer_name']?.toString() ?? '',
      width: width is num ? width.toInt() : 0,
      height: height is num ? height.toInt() : 0,
      encoded: json['encoded'] == true,
    );
  }
}

class ReplayMeta {
  final String id;
  final int version;
  final ReplayOutpost outpost;
  final ReplayPerson recordedBy;
  final DateTime startedAt;
  final int durationMs;
  final List<ReplayClip> clips;

  /// The app stopped before the recording was finished, so it ends at the
  /// last saved chunk.
  final bool recovered;
  final String appVersion;
  final String platform;

  const ReplayMeta({
    required this.id,
    required this.outpost,
    required this.recordedBy,
    required this.startedAt,
    required this.appVersion,
    required this.platform,
    this.version = ReplayFormat.version,
    this.durationMs = 0,
    this.clips = const [],
    this.recovered = false,
  });

  bool get isSupported => version <= ReplayFormat.version;

  ReplayMeta copyWith({
    int? durationMs,
    List<ReplayClip>? clips,
    bool? recovered,
  }) =>
      ReplayMeta(
        id: id,
        version: version,
        outpost: outpost,
        recordedBy: recordedBy,
        startedAt: startedAt,
        appVersion: appVersion,
        platform: platform,
        durationMs: durationMs ?? this.durationMs,
        clips: clips ?? this.clips,
        recovered: recovered ?? this.recovered,
      );

  Map<String, dynamic> toJson() => {
        'format': ReplayFormat.name,
        'version': version,
        'id': id,
        'outpost': outpost.toJson(),
        'recorded_by': recordedBy.toJson(),
        'started_at': startedAt.toUtc().toIso8601String(),
        'duration_ms': durationMs,
        'clips': [for (final c in clips) c.toJson()],
        'recovered': recovered,
        'app_version': appVersion,
        'platform': platform,
      };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Null unless [json] is a replay's meta. A newer [version] still parses,
  /// so the app can tell the user to update rather than call it broken.
  static ReplayMeta? tryParse(Object? json) {
    if (json is! Map || json['format'] != ReplayFormat.name) return null;
    final version = json['version'];
    final id = json['id'];
    final outpost = ReplayOutpost.tryParse(json['outpost']);
    final recordedBy = ReplayPerson.tryParse(json['recorded_by']);
    final startedAt = DateTime.tryParse(json['started_at']?.toString() ?? '');
    if (version is! int || version < 1) return null;
    if (id is! String || !isValidId(id)) return null;
    if (outpost == null || recordedBy == null || startedAt == null) return null;
    final duration = json['duration_ms'];
    final clips = json['clips'];
    return ReplayMeta(
      id: id,
      version: version,
      outpost: outpost,
      recordedBy: recordedBy,
      startedAt: startedAt,
      durationMs: duration is num ? duration.toInt() : 0,
      clips: [
        if (clips is List)
          for (final c in clips)
            if (ReplayClip.tryParse(c) case final clip?) clip,
      ],
      recovered: json['recovered'] == true,
      appVersion: json['app_version']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
    );
  }

  static ReplayMeta? decode(String source) {
    try {
      return tryParse(jsonDecode(source));
    } on FormatException {
      return null;
    }
  }

  /// Ids name folders, so they're limited to characters safe in a path.
  static bool isValidId(String id) =>
      RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(id);
}

enum ReplayStatus { recording, processing, ready, failed }

/// Local bookkeeping for a replay folder; never exported.
class ReplayState {
  final ReplayStatus status;
  final List<ReplayClip> clips;
  final String? error;

  const ReplayState({
    required this.status,
    this.clips = const [],
    this.error,
  });

  ReplayState copyWith({
    ReplayStatus? status,
    List<ReplayClip>? clips,
    String? error,
  }) =>
      ReplayState(
        status: status ?? this.status,
        clips: clips ?? this.clips,
        error: error,
      );

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'clips': [for (final c in clips) c.toJson()],
        if (error != null) 'error': error,
      };

  String encode() => jsonEncode(toJson());

  static ReplayState? decode(String source) {
    try {
      final json = jsonDecode(source);
      if (json is! Map) return null;
      final status = ReplayStatus.values
          .where((s) => s.name == json['status'])
          .firstOrNull;
      if (status == null) return null;
      final clips = json['clips'];
      return ReplayState(
        status: status,
        clips: [
          if (clips is List)
            for (final c in clips)
              if (ReplayClip.tryParse(c) case final clip?) clip,
        ],
        error: json['error']?.toString(),
      );
    } on FormatException {
      return null;
    }
  }
}
