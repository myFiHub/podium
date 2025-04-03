import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
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
      _audioPlayer.play();
      isPlaying.value = true;
    } catch (e) {
      print('Error playing audio: $e');
      isPlaying.value = false;
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

  void stopPlayback() async {
    await _audioPlayer.stop();
    isPlaying.value = false;
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
