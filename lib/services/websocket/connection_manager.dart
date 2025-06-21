import 'dart:async';

import 'package:podium/env.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/services/websocket/connection_state.dart';
import 'package:podium/services/websocket/lock.dart';
import 'package:podium/utils/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Manages connection lifecycle and reconnection logic
class ConnectionManager {
  static const int _maxReconnectAttempts = 20;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 5);
  static const Duration _connectionTimeout = Duration(seconds: 30);

  int _reconnectAttempts = 0;
  Timer? _connectionTimeoutTimer;
  final Lock _connectionLock = Lock();

  Duration _getReconnectDelay() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return _maxReconnectDelay;

    final Duration exponentialDelay =
        _initialReconnectDelay * (1 << _reconnectAttempts);
    final Duration jitter = Duration(
        milliseconds: (exponentialDelay.inMilliseconds *
                0.1 *
                (DateTime.now().millisecondsSinceEpoch % 10))
            .toInt());

    final Duration delay = exponentialDelay + jitter;
    return delay > _maxReconnectDelay ? _maxReconnectDelay : delay;
  }

  Future<bool> connect({
    required String token,
    required void Function(ConnectionState) updateConnectionState,
    required Future<void> Function() closeChannel,
    required Function() setupPongTimer,
    required Function() setupMessageListener,
    required Function(WebSocketChannel) setChannel,
  }) async {
    try {
      updateConnectionState(ConnectionState.connecting);
      l.d("Starting connection attempt #${_reconnectAttempts + 1}");

      // Close existing connection
      await closeChannel();

      // Set up timeout
      _setupConnectionTimeout(updateConnectionState);

      // Connect
      final uri = Uri.parse('${Env.websocketAddress}?token=$token');
      l.d("Connecting to WebSocket at ${uri.toString().replaceAll(token, '***')}");

      final channel = WebSocketChannel.connect(uri);
      await channel.ready;
      setChannel(channel);

      // Success
      _connectionTimeoutTimer?.cancel();
      _connectionTimeoutTimer = null;
      updateConnectionState(ConnectionState.connected);
      _reconnectAttempts = 0;
      l.d("Connected to websocket: ${channel.hashCode}");

      setupPongTimer();
      setupMessageListener();
      return true;
    } catch (e) {
      l.e("Error connecting to websocket: $e");
      _connectionTimeoutTimer?.cancel();
      _connectionTimeoutTimer = null;
      updateConnectionState(ConnectionState.disconnected);
      return false;
    }
  }

  void _setupConnectionTimeout(
      void Function(ConnectionState) updateConnectionState) {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(_connectionTimeout, () {
      updateConnectionState(ConnectionState.disconnected);
    });
  }

  Future<bool> reconnect({
    required String token,
    required void Function(ConnectionState) updateConnectionState,
    required Function() cleanup,
    required Future<bool> Function() connect,
  }) async {
    if (token.isEmpty) {
      l.w("Cannot reconnect: token is empty");
      return false;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      l.e("Max reconnection attempts reached. Please check your connection.");
      Toast.error(message: "Please check your connection.");
      return false;
    }

    final delay = _getReconnectDelay();
    l.d("Attempting to reconnect in ${delay.inSeconds} seconds (attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)");
    await Future.delayed(delay);

    return _connectionLock.synchronized(() async {
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        l.e("Max reconnection attempts reached while waiting for lock");
        return false;
      }

      l.w("WebSocket closed, reconnecting...");
      updateConnectionState(ConnectionState.connecting);
      cleanup();

      try {
        _reconnectAttempts++;
        l.d("Starting reconnection attempt #$_reconnectAttempts");
        final success = await connect();

        if (success) {
          l.d("Reconnection attempt #$_reconnectAttempts succeeded");
          return true;
        } else {
          l.w("Connection attempt #$_reconnectAttempts failed");
          updateConnectionState(ConnectionState.disconnected);
          return false;
        }
      } catch (e) {
        l.e("Error during reconnection attempt #$_reconnectAttempts: $e");
        updateConnectionState(ConnectionState.disconnected);
        return false;
      }
    });
  }

  Future<bool> reconnectWithRetry({
    required String token,
    required void Function(ConnectionState) updateConnectionState,
    required Function() cleanup,
    required Future<bool> Function() connect,
  }) async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      l.d("Reconnection attempt $attempt/$maxRetries");

      try {
        final success = await reconnect(
          token: token,
          updateConnectionState: updateConnectionState,
          cleanup: cleanup,
          connect: connect,
        );
        if (success) {
          l.d("Reconnection succeeded on attempt $attempt");
          return true;
        }

        if (attempt < maxRetries) {
          l.w("Reconnection attempt $attempt failed, will retry...");
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        l.e("Error during reconnection attempt $attempt: $e");
        if (attempt >= maxRetries) {
          l.e("Max retry attempts reached, giving up");
          return false;
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    l.e("Failed to reconnect after $maxRetries attempts");
    return false;
  }

  void reset() {
    _reconnectAttempts = 0;
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
  }
}
