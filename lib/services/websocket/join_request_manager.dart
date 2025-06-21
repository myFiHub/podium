import 'dart:async';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/services/websocket/client.dart';
import 'package:podium/utils/logger.dart';
import 'package:rxdart/rxdart.dart';

/// Manages join requests and their lifecycle
class JoinRequestManager {
  final _joinRequests = <String, Completer<bool>>{};
  final _joinSubject = PublishSubject<String>();

  Stream<String> get joinStream => _joinSubject.stream;

  String generateJoinId() => 'join-${myUser.address}';

  Future<bool> joinOutpost(String outpostId, {bool force = false}) async {
    // Check if already joined
    if (!force && _isAlreadyJoined(outpostId)) {
      l.d("Already joined outpost: $outpostId");
      return true;
    }

    final joinId = generateJoinId();
    l.d("Starting async join for outpost: $outpostId, joinId: $joinId");

    final completer = Completer<bool>();
    _joinRequests[joinId] = completer;

    // Adaptive timeout: longer if reconnection might be needed
    final timeoutDuration = _getAdaptiveTimeout();
    l.d("Setting join request timeout to ${timeoutDuration.inSeconds} seconds for outpost: $outpostId");

    final timeout = Timer(timeoutDuration, () {
      if (_joinRequests.containsKey(joinId)) {
        l.w("Join request timed out for outpost: $outpostId after ${timeoutDuration.inSeconds} seconds");
        _joinRequests[joinId]!.complete(false);
        _joinRequests.remove(joinId);
      } else {
        l.d("Join request timeout fired but request was already completed for outpost: $outpostId");
      }
    });

    try {
      // Send join message - this will be injected by the service
      l.d("Attempting to send join message for outpost: $outpostId");
      final success = await _sendJoinMessage(outpostId);

      if (!success) {
        l.e("Failed to send join message for outpost: $outpostId");
        timeout.cancel();
        l.d("Cancelled timeout due to send failure for outpost: $outpostId");
        _joinRequests.remove(joinId);
        return false;
      }

      l.d("Join message sent successfully, waiting for confirmation");
      return completer.future.then((result) {
        timeout.cancel();
        l.d("Cancelled timeout due to completion for outpost: $outpostId, result: $result");
        return result;
      });
    } catch (e) {
      l.e("Error during join process for outpost: $outpostId - $e");
      timeout.cancel();
      l.d("Cancelled timeout due to error for outpost: $outpostId");
      _joinRequests.remove(joinId);
      return false;
    }
  }

  Future<bool> joinOutpostWithRetry(String outpostId) async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      l.d("Attempting to join outpost (attempt $attempt/$maxRetries): $outpostId");

      try {
        final result = await joinOutpost(outpostId);
        if (result) {
          l.d("Successfully joined outpost on attempt $attempt: $outpostId");
          return true;
        }

        if (attempt < maxRetries) {
          l.w("Failed to join outpost on attempt $attempt, retrying...");
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        l.e("Error joining outpost on attempt $attempt: $e");
        if (attempt >= maxRetries) {
          l.e("Max retry attempts reached, giving up");
          return false;
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    l.e("Failed to join outpost after $maxRetries attempts: $outpostId");
    return false;
  }

  bool _isAlreadyJoined(String outpostId) {
    if (!Get.isRegistered<OngoingOutpostCallController>()) return false;

    final currentOutpost = Get.find<OngoingOutpostCallController>()
        .outpostCallController
        .outpost
        .value;

    return currentOutpost?.uuid == outpostId;
  }

  void completeJoinRequest(String joinId) {
    _joinSubject.add(joinId);
    if (_joinRequests.containsKey(joinId)) {
      l.d("Completing join request for: $joinId");
      _joinRequests[joinId]!.complete(true);
      _joinRequests.remove(joinId);
    }
  }

  void cleanup() {
    for (final completer in _joinRequests.values) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }
    _joinRequests.clear();
    _joinSubject.close();
  }

  // This will be injected by the WebSocketService
  Future<bool> Function(String) _sendJoinMessage = (outpostId) async => false;

  void setSendJoinMessage(Future<bool> Function(String) sendFunction) {
    _sendJoinMessage = sendFunction;
  }

  Duration _getAdaptiveTimeout() {
    // Check if WebSocket is connected - if not, we might need more time for reconnection
    try {
      final wsClient = WebSocketService.instance;
      final isConnected = wsClient.connected;
      final isConnecting = wsClient.isConnecting;

      l.d("WebSocket state - connected: $isConnected, connecting: $isConnecting");

      if (isConnected) {
        l.d("Using short timeout (5s) - WebSocket is connected");
        return const Duration(
            seconds: 5); // Normal timeout if already connected
      } else if (isConnecting) {
        l.d("Using medium timeout (15s) - WebSocket is connecting");
        return const Duration(seconds: 15); // Medium timeout if connecting
      } else {
        l.d("Using long timeout (20s) - WebSocket needs reconnection");
        return const Duration(
            seconds: 20); // Longer timeout if reconnection needed
      }
    } catch (e) {
      l.w("Could not determine WebSocket state, using default timeout: $e");
      return const Duration(seconds: 15); // Default timeout
    }
  }
}
