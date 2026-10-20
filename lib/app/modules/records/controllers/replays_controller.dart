import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/app/services/replay/replay_format.dart';
import 'package:podium/app/services/replay/replay_processor.dart';
import 'package:podium/app/services/replay/replay_recorder.dart';
import 'package:podium/app/services/replay/replay_share.dart';
import 'package:podium/app/services/replay/replay_storage.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

class ReplayEntry {
  final ReplayMeta meta;
  final ReplayStatus status;
  final String? error;
  final int sizeBytes;

  const ReplayEntry({
    required this.meta,
    required this.status,
    required this.sizeBytes,
    this.error,
  });

  String get id => meta.id;
}

/// The replays saved on this device, recorded here or received from others.
class ReplaysController extends GetxController {
  final entries = <ReplayEntry>[].obs;
  final loading = true.obs;

  /// Id of the replay being packed for sharing.
  final exportingId = RxnString();

  final _processor = ReplayProcessor.instance;
  void Function()? _disposeChangesListener;
  void Function()? _disposeRecordingListener;
  int _loadSeq = 0;

  @override
  void onInit() {
    super.onInit();
    _disposeChangesListener = _processor.changes.addListener(load);
    _disposeRecordingListener =
        ReplayRecorder.instance.isRecording.addListener(load);
    load();
  }

  @override
  void onClose() {
    _disposeChangesListener?.call();
    _disposeRecordingListener?.call();
    super.onClose();
  }

  double? progressOf(String id) => _processor.progress[id];

  Future<void> load() async {
    final seq = ++_loadSeq;
    final found = <ReplayEntry>[];
    try {
      final root = await ReplayStorage.root();
      await for (final entity in root.list()) {
        if (entity is! Directory) continue;
        if (!ReplayMeta.isValidId(p.basename(entity.path))) continue;
        final meta = await ReplayStorage.readMeta(entity);
        final state = await ReplayStorage.readState(entity);
        if (meta == null || state == null) continue;
        found.add(ReplayEntry(
          meta: meta,
          status: state.status,
          error: state.error,
          sizeBytes: await ReplayStorage.sizeOf(entity),
        ));
      }
    } catch (e) {
      l.e('Error loading replays: $e');
    }
    if (seq != _loadSeq) return;
    found.sort((a, b) => b.meta.startedAt.compareTo(a.meta.startedAt));
    entries.assignAll(found);
    loading.value = false;
  }

  void open(ReplayEntry entry) {
    switch (entry.status) {
      case ReplayStatus.ready:
        Get.toNamed(Routes.REPLAY, arguments: entry.id);
      case ReplayStatus.recording:
        Toast.info(
          title: 'Still recording',
          message: 'The replay is ready once the recording stops.',
        );
      case ReplayStatus.processing:
        Toast.info(
          title: 'Almost there',
          message: 'The replay is still being saved.',
        );
      case ReplayStatus.failed:
        retry(entry);
    }
  }

  void retry(ReplayEntry entry) {
    if (_processor.isProcessing(entry.id)) return;
    unawaited(_processor.process(entry.id));
  }

  Future<void> share(ReplayEntry entry) async {
    if (entry.status != ReplayStatus.ready || exportingId.value != null) return;
    exportingId.value = entry.id;
    try {
      await shareReplay(entry.meta);
    } finally {
      exportingId.value = null;
    }
  }

  Future<void> delete(ReplayEntry entry) async {
    if (entry.status == ReplayStatus.recording ||
        _processor.isProcessing(entry.id)) {
      Toast.warning(
        title: 'Not yet',
        message: 'Wait for the replay to finish saving.',
      );
      return;
    }
    try {
      final dir = await ReplayStorage.dirOf(entry.id);
      if (await dir.exists()) await dir.delete(recursive: true);
      entries.removeWhere((e) => e.id == entry.id);
      Toast.success(message: 'Replay deleted');
    } catch (e) {
      l.e('Error deleting replay ${entry.id}: $e');
      Toast.error(message: 'Could not delete the replay. Please try again.');
    }
  }
}
