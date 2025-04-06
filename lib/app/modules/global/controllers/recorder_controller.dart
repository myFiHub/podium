import 'dart:io';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:record/record.dart';

class RecorderController extends GetxController {
  final _audioRecorder = AudioRecorder();
  final isRecording = false.obs;
  final _audioPlayer = AudioPlayer();
  final _lastRecordedPath = RxnString();
  final _isPlaying = false.obs;
  final _hasPermission = false.obs;

  String? get lastRecordedPath => _lastRecordedPath.value;
  bool get isPlaying => _isPlaying.value;
  bool get hasPermission => _hasPermission.value;
  @override
  void onInit() {
    super.onInit();
    _setupAudioPlayer();
  }

  Future<bool> initializeRecorder() async {
    final hasPermission = await _audioRecorder.hasPermission();
    _hasPermission.value = hasPermission;
    if (!hasPermission) {
      // Request permission if not granted
      await _audioRecorder.hasPermission();
    }
    return hasPermission;
  }

  void _setupAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isPlaying.value = false;
      }
    });
  }

  Future<void> startRecording(bool start, {String? prefix}) async {
    try {
      if (start) {
        // Check and request permission if needed
        if (!_hasPermission.value) {
          final hasPermission = await _audioRecorder.hasPermission();
          _hasPermission.value = hasPermission;
          if (!hasPermission) {
            Toast.error(message: 'Microphone permission denied');
            return;
          }
        }

        // Get downloads directory
        final directory = await getDownloadsDirectory();
        if (directory == null) return;

        // Create the directory if it doesn't exist
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        // Generate unique filename with timestamp and optional prefix
        final fileName =
            'podium_${prefix != null ? '${prefix}_' : ''}${DateTime.now().millisecondsSinceEpoch}.m4a';
        final filePath = '${directory.path}/$fileName';

        print('Starting recording to: $filePath');

        // Configure high quality audio settings
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc, // High quality AAC encoder
            bitRate: 128000, // 128 kbps
            sampleRate: 44100, // CD quality sample rate
          ),
          path: filePath,
        );

        isRecording.value = true;
      } else {
        // Stop recording
        final path = await _audioRecorder.stop();
        isRecording.value = false;
        if (path != null) {
          print('Audio saved to: $path');
          _lastRecordedPath.value = path;

          // Verify the file exists after recording
          final file = File(path);
          if (await file.exists()) {
            print('File exists and size: ${await file.length()} bytes');
          } else {
            print('File does not exist after recording!');
          }
        }
      }
    } catch (e) {
      print('Error during recording: $e');
      isRecording.value = false;
    }
  }

  Future<void> playLastRecording() async {
    if (_lastRecordedPath.value == null) return;

    try {
      final file = File(_lastRecordedPath.value!);
      if (!await file.exists()) {
        print('Audio file does not exist at path: ${_lastRecordedPath.value}');
        return;
      }

      await _audioPlayer.stop();
      await _audioPlayer.setFilePath(_lastRecordedPath.value!);
      await _audioPlayer.play();
      _isPlaying.value = true;
    } catch (e) {
      print('Error playing audio: $e');
      _isPlaying.value = false;
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stop();
      _isPlaying.value = false;
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  @override
  void onClose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.onClose();
  }
}
