import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';

class RecordingFile {
  final String name;
  final String path;
  final DateTime date;

  RecordingFile({
    required this.name,
    required this.path,
    required this.date,
  });
}

class RecordsController extends GetxController {
  final _audioPlayer = AudioPlayer();
  final recordings = <RecordingFile>[].obs;
  final isPlaying = false.obs;
  final selectedFile = Rxn<RecordingFile>();
  final currentPosition = Duration.zero.obs;
  final trimStartTime = Duration.zero.obs;
  final trimEndTime = Duration.zero.obs;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  @override
  void onInit() {
    super.onInit();
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (isPlaying.value) currentPosition.value = position;
    });
    _stateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        isPlaying.value = false;
        currentPosition.value = Duration.zero;
      }
    });
    loadRecordings();
  }

  Future<void> playRecording(RecordingFile file) async {
    try {
      if (isPlaying.value) await stopPlayback();
      final startPosition = currentPosition.value;
      await _audioPlayer.setFilePath(file.path);
      if (startPosition > Duration.zero) {
        await _audioPlayer.seek(startPosition);
      }
      isPlaying.value = true;
      // Completes only when playback stops, so it isn't awaited.
      unawaited(_audioPlayer.play());
    } catch (e) {
      Get.snackbar('Error', 'Failed to play recording: $e');
      isPlaying.value = false;
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stop();
      isPlaying.value = false;
      currentPosition.value = Duration.zero;
    } catch (e) {
      Get.snackbar('Error', 'Failed to stop playback');
    }
  }

  Future<void> seekToPosition(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      currentPosition.value = position;
    } catch (e) {
      Get.snackbar('Error', 'Failed to seek to position');
    }
  }

  @override
  void onClose() {
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    _disposeWaveform();
    _audioPlayer.dispose();
    super.onClose();
  }

  Future<void> loadRecordings() async {
    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) return;

      final files = await directory.list().toList();
      final recordingFiles = <RecordingFile>[];

      for (var file in files) {
        if (file.path.endsWith('.m4a') && file.path.contains('podium_')) {
          final fileName = file.path.split('/').last;
          final date = DateTime.fromMillisecondsSinceEpoch(
            int.parse(fileName.split('_').last.split('.').first),
          );

          recordingFiles.add(
            RecordingFile(
              name: fileName,
              path: file.path,
              date: date,
            ),
          );
        }
      }

      // Sort by date, newest first
      recordingFiles.sort((a, b) => b.date.compareTo(a.date));
      recordings.value = recordingFiles;
    } catch (e) {
      l.d('Error loading recordings: $e');
    }
  }

  Future<void> shareRecording(RecordingFile file) async {
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: file.name),
      );
    } catch (e) {
      l.d('Error sharing file: $e');
    }
  }

  void selectRecording(RecordingFile file) {
    selectedFile.value = file;
  }

  String? _waveformPath;
  BehaviorSubject<WaveformProgress>? _waveform;
  StreamSubscription<WaveformProgress>? _waveformExtraction;

  void _disposeWaveform() {
    _waveformExtraction?.cancel();
    _waveformExtraction = null;
    _waveform?.close();
    _waveform = null;
    _waveformPath = null;
  }

  /// Cached per recording: the sheet asks for it on every rebuild, and each
  /// extraction decodes the whole file.
  Stream<WaveformProgress> getWaveformProgress(RecordingFile recording) {
    final cached = _waveform;
    if (cached != null &&
        !cached.hasError &&
        _waveformPath == recording.path) {
      return cached;
    }
    _disposeWaveform();

    final progressStream = BehaviorSubject<WaveformProgress>();
    _waveform = progressStream;
    _waveformPath = recording.path;

    Future<void> generateWaveform() async {
      try {
        final audioFile = File(recording.path);
        final waveFile = File(p.join(
            (await getTemporaryDirectory()).path, '${recording.name}.wave'));
        if (progressStream.isClosed) return;

        _waveformExtraction = JustWaveform.extract(
          audioInFile: audioFile,
          waveOutFile: waveFile,
        ).listen(
          progressStream.add,
          onError: progressStream.addError,
        );
      } catch (e) {
        if (!progressStream.isClosed) progressStream.addError(e);
      }
    }

    generateWaveform();
    return progressStream;
  }

  Future<void> shareSelectedPortion(RecordingFile trimmedFile) async {
    try {
      if (trimStartTime.value >= trimEndTime.value) {
        Toast.warning(
          title: 'Invalid Selection',
          message: 'End time must be after start time',
        );
        return;
      }
      await SharePlus.instance.share(
        ShareParams(files: [XFile(trimmedFile.path)], subject: trimmedFile.name),
      );
    } catch (e) {
      l.d('Error sharing selected portion: $e');
    }
  }

  Future<void> deleteRecording(RecordingFile file) async {
    try {
      // Stop playback if the file being deleted is currently playing
      if (selectedFile.value?.path == file.path && isPlaying.value) {
        await stopPlayback();
      }

      if (_waveformPath == file.path) _disposeWaveform();

      // Delete the file
      final fileToDelete = File(file.path);
      if (await fileToDelete.exists()) {
        await fileToDelete.delete();
      }

      // Remove from the list
      recordings.removeWhere((recording) => recording.path == file.path);
      loadRecordings();

      // Clear selection if the deleted file was selected
      if (selectedFile.value?.path == file.path) {
        selectedFile.value = null;
      }

      Toast.success(message: 'Recording deleted successfully');
    } catch (e) {
      l.e(e);
      Toast.error(message: 'Could not delete the recording. Please try again.');
    }
  }
}
