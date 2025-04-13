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
  final _isInitialized = false.obs;
  final _isBusy = false.obs;

  String? get lastRecordedPath => _lastRecordedPath.value;
  bool get isPlaying => _isPlaying.value;
  bool get hasPermission => _hasPermission.value;

  @override
  void onInit() {
    super.onInit();
    _setupAudioPlayer();
  }

  Future<bool> initializeRecorder() async {
    if (_isBusy.value) return false;
    _isBusy.value = true;

    try {
      if (_isInitialized.value) {
        _isBusy.value = false;
        return true;
      }

      print('Initializing recorder...');

      // First check if we have permission
      final hasPermission = await _audioRecorder.hasPermission();
      print('Initial permission check: $hasPermission');

      if (!hasPermission) {
        print('Requesting permission...');
        // Request permission explicitly
        final permissionGranted = await _audioRecorder.hasPermission();
        print('Permission request result: $permissionGranted');

        if (!permissionGranted) {
          print('Permission denied');
          _hasPermission.value = false;
          _isInitialized.value = false;
          _isBusy.value = false;
          return false;
        }
      }

      _hasPermission.value = true;
      _isInitialized.value = true;
      print('Recorder initialized successfully');
      return true;
    } catch (e, stackTrace) {
      print('Error initializing recorder: $e');
      print('Stack trace: $stackTrace');
      _hasPermission.value = false;
      _isInitialized.value = false;
      return false;
    } finally {
      _isBusy.value = false;
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isPlaying.value = false;
      }
    });
  }

  Future<void> startRecording(bool start, {String? prefix}) async {
    if (_isBusy.value) return;
    _isBusy.value = true;

    try {
      if (start) {
        // Ensure recorder is initialized
        if (!_isInitialized.value) {
          final initialized = await initializeRecorder();
          if (!initialized) {
            Toast.error(message: 'Failed to initialize recorder');
            return;
          }
        }

        // Get downloads directory
        final directory = await getDownloadsDirectory();
        if (directory == null) {
          Toast.error(message: 'Failed to access storage');
          return;
        }

        // Create the directory if it doesn't exist
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        // Generate unique filename with timestamp and optional prefix
        final fileName =
            'podium_${prefix != null ? '${prefix}_' : ''}${DateTime.now().millisecondsSinceEpoch}.m4a';
        final filePath = '${directory.path}/$fileName';

        print('Starting recording to: $filePath');

        // Add a small delay before starting to ensure previous operations are complete
        await Future.delayed(const Duration(milliseconds: 200));

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
        print('Recording started, isRecording: ${isRecording.value}');
      } else {
        // Only stop if we're actually recording
        if (isRecording.value == false) {
          print('Not currently recording, nothing to stop');
          _lastRecordedPath.value = null;
          _isBusy.value = false;
          return;
        }

        // Stop recording
        print('Stopping recording...');
        isRecording.value =
            false; // Set to false before stopping to prevent race conditions
        final path = await _audioRecorder.stop();

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

        print('Recording stopped, isRecording: ${isRecording.value}');

        // Add a small delay after stopping to ensure cleanup
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (e, stackTrace) {
      print('Error during recording: $e');
      print('Stack trace: $stackTrace');
      isRecording.value = false;
      _isInitialized.value = false;
      Toast.error(message: 'Recording failed: ${e.toString()}');
    } finally {
      _isBusy.value = false;
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
