import 'dart:async';
import 'dart:convert';

import 'package:podium/services/websocket/connection_manager.dart';
import 'package:podium/services/websocket/connection_state.dart';
import 'package:podium/services/websocket/incomingMessage.dart';
import 'package:podium/services/websocket/join_request_manager.dart';
import 'package:podium/services/websocket/message_router.dart';
import 'package:podium/services/websocket/outgoingMessage.dart';
import 'package:podium/utils/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocketService manages the WebSocket connection for the application.
/// It handles connection, reconnection, message sending, and message receiving.
class WebSocketService {
  // Singleton instance
  static WebSocketService? _instance;
  static WebSocketService get instance {
    _instance ??= WebSocketService._();
    return _instance!;
  }

  // Core components
  final ConnectionManager _connectionManager = ConnectionManager();
  final JoinRequestManager _joinManager = JoinRequestManager();

  // Connection state
  WebSocketChannel? _channel;
  ConnectionState _connectionState = ConnectionState.disconnected;
  String token = '';

  // Timers and subscriptions
  Timer? _pongTimer;
  StreamSubscription? subscription;

  // Private constructor for singleton
  WebSocketService._() {
    // Set up the join message sender
    _joinManager.setSendJoinMessage((outpostId) async {
      return await send(WsOutgoingMessage(
        message_type: OutgoingMessageTypeEnums.join,
        outpost_uuid: outpostId,
      ));
    });
  }

  // Public getters
  ConnectionState get connectionState => _connectionState;
  bool get isConnecting => _connectionState == ConnectionState.connecting;
  bool get connected => _connectionState == ConnectionState.connected;
  Stream<String> get joinStream => _joinManager.joinStream;

  Map<String, dynamic> get connectionStatus => {
        'state': _connectionState.toString(),
        'isConnecting': isConnecting,
        'connected': connected,
        'hasChannel': _channel != null,
        'hasToken': token.isNotEmpty,
      };

  // Public methods
  Future<bool> connect(String newToken) async {
    token = newToken;
    return await _connectionManager.connect(
      token: token,
      updateConnectionState: _updateConnectionState,
      closeChannel: _closeChannel,
      setupPongTimer: _setupPongTimer,
      setupMessageListener: _setupMessageListener,
      setChannel: (channel) => _channel = channel,
    );
  }

  Future<bool> send(WsOutgoingMessage message) async {
    if (_connectionState != ConnectionState.connected || _channel == null) {
      if (token.isEmpty) {
        l.w("Cannot send message: token is empty");
        return false;
      }

      l.w("Cannot send message: WebSocket not connected, attempting to reconnect");
      final reconnectSuccess = await reconnect();

      if (!reconnectSuccess ||
          _connectionState != ConnectionState.connected ||
          _channel == null) {
        l.e("Failed to reconnect, cannot send message");
        return false;
      }
    }

    try {
      final jsoned = message.toJson();
      if (jsoned['data'] == null) jsoned['data'] = {};
      final stringified = jsonEncode(jsoned);
      l.d('Sending message: $stringified');
      _channel?.sink.add(stringified);
      l.d('Message sent successfully');
      return true;
    } catch (e) {
      l.e("Error sending message: $e");
      _updateConnectionState(ConnectionState.disconnected);
      await reconnectWithRetry();
      return false;
    }
  }

  Future<bool> asyncJoinOutpost(String outpostId, {bool force = false}) {
    return _joinManager.joinOutpost(outpostId, force: force);
  }

  Future<bool> asyncJoinOutpostWithRetry(String outpostId) {
    return _joinManager.joinOutpostWithRetry(outpostId);
  }

  /// Attempts to reconnect to the WebSocket server
  Future<bool> reconnect() async {
    return await _connectionManager.reconnect(
      token: token,
      updateConnectionState: _updateConnectionState,
      cleanup: _cleanup,
      connect: () => connect(token),
    );
  }

  /// Attempts to reconnect to the WebSocket server with automatic retries
  Future<bool> reconnectWithRetry() async {
    return await _connectionManager.reconnectWithRetry(
      token: token,
      updateConnectionState: _updateConnectionState,
      cleanup: _cleanup,
      connect: () => connect(token),
    );
  }

  void close() {
    token = '';
    _cleanup();
  }

  void forceResetConnection() {
    l.w("Force resetting connection state");
    _connectionManager.reset();
    _cleanup();
  }

  // Internal methods
  void _updateConnectionState(ConnectionState newState) {
    final oldState = _connectionState;
    _connectionState = newState;
    l.d("Connection state changed: $oldState -> $newState");
  }

  Future<void> _closeChannel() async {
    if (_channel != null) {
      try {
        await _channel!.sink.close();
      } catch (e) {
        l.w("Error closing existing channel: $e");
      }
      _channel = null;
    }
  }

  void _cleanup() {
    _pongTimer?.cancel();
    _pongTimer = null;
    subscription?.cancel();
    subscription = null;

    _closeChannel();
    _updateConnectionState(ConnectionState.disconnected);
    _joinManager.cleanup();
  }

  void _setupPongTimer() {
    _pongTimer?.cancel();
    _pong();
    _pongTimer =
        Timer.periodic(const Duration(seconds: 19), (timer) => _pong());
  }

  void _setupMessageListener() {
    subscription?.cancel();

    l.d("Setting up message listener");
    subscription = _channel!.stream.listen(
      (dynamic message) {
        final messageStr = message.toString();
        l.d("Received message: ${messageStr.length > 100 ? '${messageStr.substring(0, 100)}...' : messageStr}");
        _handleIncomingMessageString(message as String);
      },
      onError: (error) {
        l.e("WebSocket Error: $error");
        _updateConnectionState(ConnectionState.disconnected);
        Future.microtask(() => reconnectWithRetry());
      },
      onDone: () {
        l.w("WebSocket connection closed");
        _updateConnectionState(ConnectionState.disconnected);
        Future.microtask(() => reconnectWithRetry());
      },
    );
    l.d("Message listener set up successfully");
  }

  void _handleIncomingMessageString(String message) {
    try {
      final jsoned = jsonDecode(message);
      if (jsoned['name'] == 'error') {
        l.e("Error: ${jsoned['data']['message']}");
        return;
      }
      final incomingMessage = IncomingMessage.fromJson(jsoned);
      WebSocketMessageRouter.routeMessage(incomingMessage);
    } catch (e) {
      l.e("Error parsing message: $e");
    }
  }

  void _pong() async {
    if (_connectionState != ConnectionState.connecting && token.isNotEmpty) {
      if (_connectionState == ConnectionState.connected && _channel != null) {
        try {
          _channel?.sink.add(List<int>.from([0x8A]));
        } catch (e) {
          l.e("Error sending pong: $e");
          _updateConnectionState(ConnectionState.disconnected);
          await reconnectWithRetry();
        }
      } else {
        l.w("Not connected, attempting to reconnect before sending pong");
        await reconnectWithRetry();
      }
    }
  }

  // This method is called by the message router
  void completeJoinRequest(String joinId) {
    _joinManager.completeJoinRequest(joinId);
  }
}
