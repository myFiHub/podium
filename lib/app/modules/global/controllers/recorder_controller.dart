import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

/// Records the ongoing outpost call as heard on this device: the incoming
/// audio mixed with the local microphone. The audio is tapped from Jitsi's
/// WebRTC audio device, so it doesn't compete with the call for the mic.
class RecorderController extends GetxController {
  final isRecording = false.obs;
  bool _isBusy = false;

  /// Starts recording to `podium_<prefix>_<timestamp>.m4a` in the downloads
  /// directory, which is where the records page looks for recordings.
  Future<bool> startRecording({String? prefix, required bool micEnabled}) async {
    if (_isBusy || isRecording.value) return false;
    _isBusy = true;
    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        Toast.error(message: 'Failed to access storage');
        return false;
      }
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final safePrefix = prefix?.replaceAll(RegExp(r'[^\w\- ]'), '-');
      final fileName = 'podium_${safePrefix != null ? '${safePrefix}_' : ''}'
          '${DateTime.now().millisecondsSinceEpoch}.m4a';
      final path = '${directory.path}/$fileName';

      l.d('Starting call recording to: $path');
      await jitsiMeet.setCallRecordingMicEnabled(micEnabled);
      await jitsiMeet.startCallRecording(path);
      isRecording.value = true;
      return true;
    } catch (e, stackTrace) {
      l.e('Error starting call recording: $e\n$stackTrace');
      Toast.error(
        title: 'Recording failed',
        message: 'Could not start recording the call.',
      );
      return false;
    } finally {
      _isBusy = false;
    }
  }

  /// Stops the recording, returning the saved file path or null if nothing
  /// was recorded.
  Future<String?> stopRecording() async {
    if (!isRecording.value) return null;
    isRecording.value = false;
    try {
      final path = await jitsiMeet.stopCallRecording();
      if (path != null) {
        l.d('Call recording saved to: $path (${await File(path).length()} bytes)');
      }
      return path;
    } catch (e, stackTrace) {
      l.e('Error stopping call recording: $e\n$stackTrace');
      return null;
    }
  }

  /// Keeps the microphone out of the recording while the user is muted.
  void setMicEnabled(bool enabled) {
    jitsiMeet.setCallRecordingMicEnabled(enabled);
  }

  @override
  void onClose() {
    stopRecording();
    super.onClose();
  }
}
