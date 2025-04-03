import 'dart:io';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
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
  final _audioPlayer = AudioPlayer();
  final recordings = <RecordingFile>[].obs;
  final isPlaying = false.obs;
  final selectedFile = Rxn<RecordingFile>();
  final currentPosition = Duration.zero.obs;

  @override
  void onInit() {
    super.onInit();
    loadRecordings();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        isPlaying.value = false;
      }
    });
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

  Future<void> playRecording(RecordingFile file) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setFilePath(file.path);
      _audioPlayer.positionStream.listen((position) {
        currentPosition.value = position;
      });
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          stopPlayback();
        }
      });
      await _audioPlayer.play();
      isPlaying.value = true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to play recording');
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

  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stop();
      isPlaying.value = false;
      currentPosition.value = Duration.zero;
    } catch (e) {
      Get.snackbar('Error', 'Failed to stop playback');
    }
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

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
