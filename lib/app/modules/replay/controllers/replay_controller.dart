import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/services/replay/replay_format.dart';
import 'package:podium/app/services/replay/replay_share.dart';
import 'package:podium/app/services/replay/replay_storage.dart';
import 'package:podium/app/services/replay/replay_timeline.dart';
import 'package:podium/utils/logger.dart';
import 'package:video_player/video_player.dart';

class ShownMoment {
  final int id;
  final ReplayMoment moment;
  final double lane;
  const ShownMoment({required this.id, required this.moment, required this.lane});
}

/// Plays a replay. The audio player is the clock: the room, chat, poll and
/// screen share follow its position.
class ReplayController extends GetxController {
  static const speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
  static const _tick = Duration(milliseconds: 200);
  static const _maxVideoDriftMs = 300;

  final String id;

  ReplayController(this.id);

  final loading = true.obs;
  final error = RxnString();
  final meta = Rxn<ReplayMeta>();
  final durationMs = 0.obs;
  final positionMs = 0.obs;
  final playing = false.obs;
  final speed = 1.0.obs;
  final room = const ReplayRoomState().obs;
  final chat = <ReplayChatMessage>[].obs;
  final moments = <ShownMoment>[].obs;
  final video = Rxn<VideoPlayerController>();
  final sharing = false.obs;
  final markers = <ReplayMarker>[].obs;

  /// While the user drags the seek bar, the position it shows.
  final scrubMs = RxnInt();

  final _player = AudioPlayer();
  final _random = Random();
  late Directory _dir;
  ReplayTimeline? _timeline;
  StreamSubscription<PlayerState>? _stateSubscription;
  Timer? _ticker;
  int _lastMs = 0;
  int _momentSeq = 0;
  int? _videoClipIndex;
  int _videoGeneration = 0;
  DateTime _lastVideoCorrection = DateTime(0);

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _stateSubscription?.cancel();
    _player.dispose();
    _videoGeneration++;
    video.value?.dispose();
    super.onClose();
  }

  Future<void> _load() async {
    try {
      if (Get.isRegistered<OutpostCallController>() &&
          Get.find<OutpostCallController>().isInCall.value) {
        error.value = 'Leave the outpost to play replays.';
        return;
      }
      _dir = await ReplayStorage.dirOf(id);
      final meta = await ReplayStorage.readMeta(_dir);
      if (meta == null) {
        error.value = 'This replay could not be found.';
        return;
      }
      this.meta.value = meta;
      if (!meta.isSupported) {
        error.value = 'Update Podium to play this replay.';
        return;
      }
      final eventsFile = File(p.join(_dir.path, ReplayFormat.events));
      final content =
          await eventsFile.exists() ? await eventsFile.readAsString() : '';
      final events = await _parseReplayEvents(content);

      final audioDuration = await _player.setFilePath(
        p.join(_dir.path, ReplayFormat.audio),
      );
      final duration = max(audioDuration?.inMilliseconds ?? 0, meta.durationMs);
      durationMs.value = duration;
      _timeline = ReplayTimeline(
        events: events,
        clips: meta.clips.where((c) => c.encoded).toList(),
        durationMs: duration,
      );
      markers.assignAll(_timeline!.markers);

      _stateSubscription = _player.playerStateStream.listen((state) {
        final completed = state.processingState == ProcessingState.completed;
        playing.value = state.playing && !completed;
        if (completed) _player.pause();
      });
      await _player.setSpeed(speed.value);
      _update(0, continuous: false);
      _ticker = Timer.periodic(_tick, (_) => _onTick());
      loading.value = false;
    } catch (e, stackTrace) {
      l.e('Error loading replay $id: $e\n$stackTrace');
      error.value = 'This replay could not be played.';
    } finally {
      loading.value = false;
    }
  }

  void _onTick() {
    if (_timeline == null || scrubMs.value != null) return;
    _update(_player.position.inMilliseconds, continuous: true);
  }

  void _update(int ms, {required bool continuous}) {
    final timeline = _timeline;
    if (timeline == null) return;
    ms = ms.clamp(0, durationMs.value);
    if (continuous && playing.value && ms > _lastMs && ms - _lastMs < 1500) {
      for (final moment in timeline.momentsBetween(_lastMs, ms)) {
        _showMoment(moment);
      }
    }
    _lastMs = ms;
    positionMs.value = ms;
    room.value = timeline.stateAt(ms);
    final visibleChat = timeline.chatUntil(ms);
    if (visibleChat.length != chat.length) chat.assignAll(visibleChat);
    _syncVideo(ms, force: !continuous);
  }

  void _showMoment(ReplayMoment moment) {
    if (moments.length > 30) moments.removeAt(0);
    final shown = ShownMoment(
      id: _momentSeq++,
      moment: moment,
      lane: _random.nextDouble(),
    );
    moments.add(shown);
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!isClosed) moments.removeWhere((m) => m.id == shown.id);
    });
  }

  void _syncVideo(int ms, {required bool force}) {
    final clip = room.value.clip;
    if (clip?.index != _videoClipIndex) {
      _switchVideo(clip, ms);
      return;
    }
    final controller = video.value;
    if (clip == null || controller == null || !controller.value.isInitialized) {
      return;
    }
    final target = ms - clip.startMs;
    if (playing.value && !controller.value.isPlaying) controller.play();
    if (!playing.value && controller.value.isPlaying) controller.pause();
    final drift = (controller.value.position.inMilliseconds - target).abs();
    final now = DateTime.now();
    if (force ||
        (drift > _maxVideoDriftMs &&
            now.difference(_lastVideoCorrection).inMilliseconds > 1000)) {
      _lastVideoCorrection = now;
      controller.seekTo(Duration(milliseconds: target));
    }
  }

  Future<void> _switchVideo(ReplayClip? clip, int ms) async {
    final generation = ++_videoGeneration;
    _videoClipIndex = clip?.index;
    final old = video.value;
    video.value = null;
    await old?.dispose();
    if (clip == null) return;
    final controller =
        VideoPlayerController.file(File(p.join(_dir.path, clip.file)));
    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setPlaybackSpeed(speed.value);
      await controller.seekTo(
        Duration(milliseconds: positionMs.value - clip.startMs),
      );
      if (generation != _videoGeneration || isClosed) {
        await controller.dispose();
        return;
      }
      if (playing.value) await controller.play();
      video.value = controller;
    } catch (e) {
      l.e('Error opening screen clip ${clip.index}: $e');
      await controller.dispose();
    }
  }

  Future<void> togglePlay() async {
    if (_timeline == null) return;
    if (_player.playing) {
      await _player.pause();
      video.value?.pause();
      return;
    }
    if (positionMs.value >= durationMs.value - 250) await seek(0);
    // Completes when playback stops, so it isn't awaited.
    unawaited(_player.play());
  }

  Future<void> seek(int ms) async {
    if (_timeline == null) return;
    ms = ms.clamp(0, durationMs.value);
    await _player.seek(Duration(milliseconds: ms));
    _update(ms, continuous: false);
  }

  Future<void> skip(Duration by) =>
      seek(positionMs.value + by.inMilliseconds);

  void scrubTo(double ms) {
    scrubMs.value = ms.round();
  }

  Future<void> endScrub(double ms) async {
    scrubMs.value = null;
    await seek(ms.round());
  }

  Future<void> cycleSpeed() async {
    final index = speeds.indexOf(speed.value);
    final next = speeds[(index + 1) % speeds.length];
    speed.value = next;
    await _player.setSpeed(next);
    await video.value?.setPlaybackSpeed(next);
  }

  Future<void> share() async {
    final meta = this.meta.value;
    if (meta == null || sharing.value) return;
    sharing.value = true;
    try {
      await shareReplay(meta);
    } finally {
      sharing.value = false;
    }
  }
}

/// Parses off the UI isolate. The closure has to be created here: one created
/// inside [ReplayController] captures the controller, and its audio player
/// cannot be sent to another isolate.
Future<List<ReplayEvent>> _parseReplayEvents(String content) {
  return Isolate.run(() => ReplayEvent.parseLines(content));
}
