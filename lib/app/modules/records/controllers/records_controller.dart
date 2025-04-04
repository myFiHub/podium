import 'dart:async';
import 'dart:io';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
  late final FlutterSoundPlayer _audioPlayer;
  final recordings = <RecordingFile>[].obs;
  final isPlaying = false.obs;
  final selectedFile = Rxn<RecordingFile>();
  final currentPosition = Duration.zero.obs;
  final _isInitialized = false.obs;
  StreamSubscription? _positionSubscription;

  @override
  void onInit() async {
    super.onInit();
    _audioPlayer = FlutterSoundPlayer();
    await _initializeAudioPlayer();
    loadRecordings();
  }

  Future<void> _initializeAudioPlayer() async {
    await _audioPlayer.openPlayer();
    _audioPlayer.setSubscriptionDuration(const Duration(milliseconds: 10));
    _isInitialized.value = true;
  }

  Future<void> playRecording(RecordingFile file) async {
    if (!_isInitialized.value) return;

    try {
      if (_audioPlayer.isPlaying) {
        await stopPlayback();
      }

      isPlaying.value = true;
      await _audioPlayer.startPlayer(
        fromURI: file.path,
        codec: Codec.aacADTS,
        whenFinished: () {
          isPlaying.value = false;
          currentPosition.value = Duration.zero;
          _positionSubscription?.cancel();
        },
      );

      // Start position tracking
      _positionSubscription?.cancel();
      _positionSubscription = _audioPlayer.onProgress?.listen((e) {
        currentPosition.value = e.position;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to play recording: $e');
      isPlaying.value = false;
    }
  }

  Future<void> stopPlayback() async {
    if (!_isInitialized.value) return;

    try {
      await _audioPlayer.stopPlayer();
      _positionSubscription?.cancel();
      isPlaying.value = false;
      currentPosition.value = Duration.zero;
    } catch (e) {
      Get.snackbar('Error', 'Failed to stop playback');
    }
  }

  Future<void> seekToPosition(Duration position) async {
    if (!_isInitialized.value) return;

    try {
      await _audioPlayer.seekToPlayer(position);
      currentPosition.value = position;
    } catch (e) {
      Get.snackbar('Error', 'Failed to seek to position');
    }
  }

  @override
  void onClose() async {
    _positionSubscription?.cancel();
    await _audioPlayer.closePlayer();
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
      print('Error loading recordings: $e');
    }
  }

  Future<void> shareRecording(RecordingFile file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '${file.name}',
      );
    } catch (e) {
      print('Error sharing file: $e');
    }
  }

  void selectRecording(RecordingFile file) {
    selectedFile.value = file;
  }

  Stream<WaveformProgress> getWaveformProgress(RecordingFile recording) {
    final progressStream = BehaviorSubject<WaveformProgress>();

    Future<void> generateWaveform() async {
      try {
        final audioFile = File(recording.path);
        final waveFile = File(p.join(
            (await getTemporaryDirectory()).path, '${recording.name}.wave'));

        JustWaveform.extract(
          audioInFile: audioFile,
          waveOutFile: waveFile,
        ).listen(
          progressStream.add,
          onError: progressStream.addError,
        );
      } catch (e) {
        progressStream.addError(e);
      }
    }

    generateWaveform();
    return progressStream;
  }
}
