import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/services/replay/replay_format.dart';
import 'package:podium/app/services/replay/replay_recorder.dart';
import 'package:podium/app/services/replay/replay_storage.dart';
import 'package:podium/utils/logger.dart';

class ReplayProcessingException implements Exception {
  final String message;
  const ReplayProcessingException(this.message);

  @override
  String toString() => message;
}

/// Turns a recorded folder into a playable replay: joins the audio chunks
/// into `audio.m4a` and encodes each screen share's frames into an MP4.
/// Every step is saved as it finishes, so processing can be retried after a
/// failure or a crash without redoing finished work.
class ReplayProcessor {
  ReplayProcessor._();

  static final instance = ReplayProcessor._();

  static const _encodeAttempts = 3;

  /// Replay id -> progress from 0 to 1, while processing.
  final progress = <String, double>{}.obs;

  /// Bumped when a replay's status changes, so lists can reload.
  final changes = 0.obs;

  final _running = <String, Future<void>>{};

  bool isProcessing(String id) => _running.containsKey(id);

  Future<void> process(String id) {
    return _running[id] ??= _process(id).whenComplete(() {
      _running.remove(id);
      progress.remove(id);
      changes.value++;
    });
  }

  /// Finishes recordings cut off by the app stopping, and resumes
  /// processing that didn't complete. Run once at launch.
  Future<void> recoverInterrupted() async {
    final Directory root;
    try {
      root = await ReplayStorage.root();
    } catch (e) {
      l.e('Could not open the replays folder: $e');
      return;
    }
    await for (final entity in root.list()) {
      if (entity is! Directory) continue;
      final id = p.basename(entity.path);
      if (!ReplayMeta.isValidId(id) || id == ReplayRecorder.instance.currentId) {
        continue;
      }
      final state = await ReplayStorage.readState(entity);
      if (state == null) continue;
      switch (state.status) {
        case ReplayStatus.recording:
          final meta = await ReplayStorage.readMeta(entity);
          if (meta == null) continue;
          l.d('Recovering interrupted replay $id');
          await ReplayStorage.writeMeta(entity, meta.copyWith(recovered: true));
          await ReplayStorage.writeState(
            entity,
            state.copyWith(status: ReplayStatus.processing),
          );
          unawaited(process(id));
        case ReplayStatus.processing:
          unawaited(process(id));
        case ReplayStatus.ready:
        case ReplayStatus.failed:
          break;
      }
    }
    changes.value++;
  }

  Future<void> _process(String id) async {
    final dir = await ReplayStorage.dirOf(id);
    var meta = await ReplayStorage.readMeta(dir);
    final saved = await ReplayStorage.readState(dir);
    if (meta == null || saved == null) return;
    var state = saved.copyWith(status: ReplayStatus.processing);
    await ReplayStorage.writeState(dir, state);
    changes.value++;
    progress[id] = 0;

    try {
      final durationMs = await _joinAudio(dir, meta.durationMs);
      meta = meta.copyWith(durationMs: durationMs);
      await ReplayStorage.writeMeta(dir, meta);

      final recorded = state.clips;
      final clips = <ReplayClip>[];
      for (var i = 0; i < recorded.length; i++) {
        final clip = await _encodeClip(
          dir,
          recorded[i],
          durationMs,
          (fraction) => progress[id] = (i + fraction) / recorded.length,
        );
        if (clip != null) clips.add(clip);
        state = state.copyWith(
          clips: [...clips, ...recorded.skip(i + 1)],
        );
        await ReplayStorage.writeState(dir, state);
      }

      meta = meta.copyWith(clips: clips);
      await ReplayStorage.writeMeta(dir, meta);
      await ReplayStorage.writeState(
        dir,
        ReplayState(status: ReplayStatus.ready, clips: clips),
      );
      l.d('Replay $id ready: ${durationMs}ms, ${clips.length} clips');
    } catch (e, stackTrace) {
      l.e('Error processing replay $id: $e\n$stackTrace');
      await ReplayStorage.writeState(
        dir,
        state.copyWith(status: ReplayStatus.failed, error: e.toString()),
      );
    }
  }

  /// Returns the audio's duration in milliseconds.
  Future<int> _joinAudio(Directory dir, int knownDurationMs) async {
    final audio = File(p.join(dir.path, ReplayFormat.audio));
    final chunks = Directory(p.join(dir.path, ReplayFormat.audioChunks));
    if (await chunks.exists()) {
      final hasChunks = await chunks.list().any((e) => e is File);
      if (!hasChunks) {
        throw const ReplayProcessingException('No audio was recorded');
      }
      final durationMs = await jitsiMeet.joinAudioChunks(
        dir: chunks.path,
        outPath: audio.path,
      );
      if (durationMs <= 0) {
        throw const ReplayProcessingException('Could not save the audio');
      }
      await chunks.delete(recursive: true);
      return durationMs;
    }
    if (await audio.exists() && knownDurationMs > 0) return knownDurationMs;
    throw const ReplayProcessingException('The audio file is missing');
  }

  /// Returns the encoded clip, or null when it has nothing to show.
  Future<ReplayClip?> _encodeClip(
    Directory dir,
    ReplayClip clip,
    int durationMs,
    void Function(double fraction) onProgress,
  ) async {
    final output = File(p.join(dir.path, clip.file));
    final frames = Directory(p.join(dir.path, clip.framesDir));
    if (clip.encoded) {
      if (await output.exists()) return clip;
      return null;
    }
    final endMs = min(clip.endMs ?? durationMs, durationMs);
    if (endMs <= clip.startMs || !await _hasFrames(frames)) {
      await _deleteQuietly(frames);
      return null;
    }

    for (var attempt = 1;; attempt++) {
      // iOS doesn't allow video encoding in the background.
      if (Platform.isIOS) await _waitForForeground();
      try {
        final result = await jitsiMeet.encodeScreenClip(
          dir: frames.path,
          outPath: output.path,
          endMs: endMs - clip.startMs,
          onProgress: (done, total) {
            if (total > 0) onProgress(done / total);
          },
        );
        await _deleteQuietly(frames);
        return clip.copyWith(
          endMs: endMs,
          width: result.width,
          height: result.height,
          encoded: true,
        );
      } catch (e) {
        l.w('Encoding screen clip ${clip.index} failed (attempt $attempt): $e');
        if (attempt >= _encodeAttempts) {
          throw const ReplayProcessingException(
            'Could not save the screen share',
          );
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
  }

  static Future<bool> _hasFrames(Directory frames) async {
    final index = File(p.join(frames.path, 'frames.idx'));
    return await index.exists() && await index.length() > 0;
  }

  static Future<void> _waitForForeground() async {
    while (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  static Future<void> _deleteQuietly(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } on FileSystemException catch (e) {
      l.w('Could not delete ${dir.path}: $e');
    }
  }
}
