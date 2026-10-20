import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/services/replay/replay_format.dart';
import 'package:podium/app/services/replay/replay_processor.dart';
import 'package:podium/app/services/replay/replay_storage.dart';
import 'package:podium/env.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/services/websocket/incomingMessage.dart';
import 'package:podium/utils/logger.dart';

/// A video track to record as the screen share.
class ReplayShareSource {
  final int pcId;
  final String trackId;
  final String uuid;
  final String name;

  const ReplayShareSource({
    required this.pcId,
    required this.trackId,
    required this.uuid,
    required this.name,
  });
}

/// Records an outpost call as a replay: the call audio (as heard on this
/// device), the screen share, and a log of everything shown in the room.
///
/// Everything is saved every [Env.recordingChunkSeconds], so if the app
/// dies mid-call the replay is recovered up to the last save on next launch.
class ReplayRecorder {
  ReplayRecorder._();

  static final instance = ReplayRecorder._();

  static const _minFreeBytes = 300 * 1024 * 1024;

  static const _ignoredWsMessages = {
    IncomingMessageType.follow,
    IncomingMessageType.invite,
    IncomingMessageType.waitlistUpdated,
    IncomingMessageType.creatorJoined,
  };

  final isRecording = false.obs;

  _Session? _session;
  bool _starting = false;

  /// Id of the replay being recorded.
  String? get currentId => _session?.meta.id;

  static int get chunkSeconds => Env.recordingChunkSeconds.clamp(1, 60);

  Future<bool> start({
    required OutpostModel outpost,
    required bool micEnabled,
  }) async {
    if (_starting || _session != null) return false;
    _starting = true;
    Directory? dir;
    RandomAccessFile? events;
    var audioStarted = false;
    try {
      final root = await ReplayStorage.root();
      final free = await jitsiMeet.freeDiskBytes(root.path);
      if (free >= 0 && free < _minFreeBytes) {
        Toast.error(
          title: 'Not enough storage',
          message: 'Free up some space on your device to record.',
        );
        return false;
      }

      final id = ReplayStorage.newId();
      dir = await ReplayStorage.dirOf(id);
      await Directory(p.join(dir.path, ReplayFormat.audioChunks))
          .create(recursive: true);
      final me = myUser;
      final meta = ReplayMeta(
        id: id,
        outpost: ReplayOutpost(
          uuid: outpost.uuid,
          name: outpost.name,
          subject: outpost.subject,
          image: outpost.image,
          creator: ReplayPerson(
            uuid: outpost.creator_user_uuid,
            name: outpost.creator_user_name ?? '',
            image: outpost.creator_user_image,
          ),
        ),
        recordedBy: ReplayPerson(
          uuid: me.uuid,
          name: me.name ?? '',
          image: me.image,
        ),
        startedAt: DateTime.now(),
        appVersion: Env.VERSION,
        platform: Platform.operatingSystem,
      );
      await ReplayStorage.writeMeta(dir, meta);
      await ReplayStorage.writeState(
        dir,
        const ReplayState(status: ReplayStatus.recording),
      );
      events = await File(p.join(dir.path, ReplayFormat.events))
          .open(mode: FileMode.writeOnlyAppend);

      await jitsiMeet.setCallRecordingMicEnabled(micEnabled);
      await jitsiMeet.startCallRecording(
        dir: p.join(dir.path, ReplayFormat.audioChunks),
        chunkSeconds: chunkSeconds,
      );
      audioStarted = true;

      final session = _Session(dir, meta, events, outpost.uuid);
      _session = session;
      session.flushTimer = Timer.periodic(
        Duration(seconds: chunkSeconds),
        (_) => session.flush(),
      );
      isRecording.value = true;
      _recordRoomSnapshot();
      l.d('Recording replay $id into ${dir.path}');
      return true;
    } catch (e, stackTrace) {
      l.e('Error starting replay recording: $e\n$stackTrace');
      if (audioStarted) await _ignoreErrors(jitsiMeet.stopCallRecording);
      await _ignoreErrors(() async => events?.close());
      if (dir != null) {
        await _ignoreErrors(() => dir!.delete(recursive: true));
      }
      Toast.error(
        title: 'Recording failed',
        message: 'Could not start recording the outpost.',
      );
      return false;
    } finally {
      _starting = false;
    }
  }

  /// Stops recording and starts processing the replay in the background.
  /// Returns its id, or null if nothing was being recorded.
  Future<String?> stop() async {
    final session = _session;
    if (session == null) return null;
    _session = null;
    isRecording.value = false;
    session.flushTimer?.cancel();

    await session.shareOp;
    await _closeClip(session);
    try {
      await jitsiMeet.stopCallRecording();
    } catch (e) {
      l.e('Error stopping call audio recording: $e');
    }
    await session.flush();
    await _ignoreErrors(session.events.close);
    await ReplayStorage.writeState(
      session.dir,
      ReplayState(status: ReplayStatus.processing, clips: session.clips),
    );
    final id = session.meta.id;
    unawaited(ReplayProcessor.instance.process(id));
    return id;
  }

  void setMicEnabled(bool enabled) {
    jitsiMeet.setCallRecordingMicEnabled(enabled);
  }

  // Room events ---------------------------------------------------------------

  void onWsMessage(IncomingMessage message) {
    final session = _session;
    if (session == null || _ignoredWsMessages.contains(message.name)) return;
    final outpostId = message.data.outpost_uuid;
    if (outpostId != null && outpostId != session.outpostId) return;
    session.record(ReplayEventType.ws, {
      'name': message.name.wireName,
      'data': message.data.toJson()..removeWhere((_, v) => v == null),
    });
  }

  void onConnection({required bool online}) {
    _session?.recordChanged(ReplayEventType.connection, {'online': online});
  }

  void onMembers(List<LiveMember> members) {
    _session?.recordChanged(ReplayEventType.members, {
      'members': [
        for (final m in members)
          ReplayMember(
            uuid: m.uuid,
            address: m.address,
            name: m.name ?? '',
            image: m.image,
            canSpeak: m.can_speak,
            isSpeaking: m.is_speaking,
            remainingTime: m.remaining_time,
          ).toJson(),
      ],
    });
  }

  void onChat({String? uuid, required String name, required String text}) {
    _session?.record(ReplayEventType.chat, {
      'uuid': uuid,
      'name': name,
      'text': text,
    });
  }

  void onReaction({String? uuid, required String name, required String emoji}) {
    _session?.record(ReplayEventType.reaction, {
      'uuid': uuid,
      'name': name,
      'emoji': emoji,
    });
  }

  void onPoll(PollSnapshot? poll) {
    _session?.recordChanged(ReplayEventType.poll, {'poll': poll?.toJson()});
  }

  void onHands(List<String> uuids) {
    _session?.recordChanged(ReplayEventType.hands, {'uuids': [...uuids]});
  }

  void onDominantSpeaker(String? uuid) {
    _session?.recordChanged(ReplayEventType.dominantSpeaker, {'uuid': uuid});
  }

  /// The screen share now showing in the room, or null when nobody shares.
  void onScreenShare(ReplayShareSource? source) {
    final session = _session;
    if (session == null) return;
    session.shareOp = session.shareOp
        .then((_) => _applyShare(session, source))
        .catchError((Object e) => l.e('Error recording screen share: $e'));
  }

  void _recordRoomSnapshot() {
    if (Get.isRegistered<OutpostCallController>()) {
      onMembers(Get.find<OutpostCallController>().members.value);
    }
    final room = findCallRoom();
    if (room == null) return;
    onHands(room.raisedHandUuids);
    onDominantSpeaker(room.dominantSpeakerUuid.value);
    onPoll(room.activePoll.value);
    onScreenShare(room.recordableShare);
  }

  Future<void> _applyShare(_Session session, ReplayShareSource? source) async {
    if (session.openTrackId == source?.trackId) return;
    await _closeClip(session);
    if (source == null || session.clips.length >= 999) return;

    final index = session.clips.length + 1;
    final clip = ReplayClip(
      index: index,
      startMs: session.now,
      sharerUuid: source.uuid,
      sharerName: source.name,
    );
    final framesDir = Directory(p.join(session.dir.path, clip.framesDir));
    await framesDir.create(recursive: true);
    final attached = await jitsiMeet.startScreenCapture(
      pcId: source.pcId,
      trackId: source.trackId,
      dir: framesDir.path,
    );
    if (!attached) {
      l.w('Screen share track ${source.trackId} not found, not recording it');
      await _ignoreErrors(() => framesDir.delete(recursive: true));
      return;
    }
    session.openTrackId = source.trackId;
    session.clips.add(clip);
    session.record(ReplayEventType.screenShare, {
      'clip': index,
      'uuid': source.uuid,
      'name': source.name,
    });
    await _saveClips(session);
  }

  Future<void> _closeClip(_Session session) async {
    if (session.openTrackId == null) return;
    session.openTrackId = null;
    try {
      await jitsiMeet.stopScreenCapture();
    } catch (e) {
      l.e('Error stopping screen capture: $e');
    }
    final last = session.clips.removeLast();
    session.clips.add(last.copyWith(endMs: session.now));
    session.record(ReplayEventType.screenShare, {'clip': null});
    await _saveClips(session);
  }

  Future<void> _saveClips(_Session session) async {
    if (_session != session) return;
    await ReplayStorage.writeState(
      session.dir,
      ReplayState(status: ReplayStatus.recording, clips: session.clips),
    );
  }

  static Future<void> _ignoreErrors(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }
}

class _Session {
  final Directory dir;
  final ReplayMeta meta;
  final RandomAccessFile events;
  final String outpostId;
  final _clock = Stopwatch()..start();
  final _pending = StringBuffer();
  final _lastByType = <String, String>{};
  Future<void> _io = Future.value();
  Timer? flushTimer;

  final clips = <ReplayClip>[];
  String? openTrackId;
  Future<void> shareOp = Future.value();

  _Session(this.dir, this.meta, this.events, this.outpostId);

  int get now => _clock.elapsedMilliseconds;

  void record(String type, Map<String, dynamic> data) {
    _pending.write(ReplayEvent(now, type, data).toLine());
  }

  /// Records state-like events only when they differ from the last one.
  void recordChanged(String type, Map<String, dynamic> data) {
    final encoded = jsonEncode(data);
    if (_lastByType[type] == encoded) return;
    _lastByType[type] = encoded;
    record(type, data);
  }

  Future<void> flush() {
    return _io = _io.then((_) async {
      if (_pending.isEmpty) return;
      final text = _pending.toString();
      _pending.clear();
      await events.writeString(text);
      await events.flush();
    }).catchError((Object e) => l.e('Error saving replay events: $e'));
  }
}
