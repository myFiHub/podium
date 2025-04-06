import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/outpostDetail/controllers/outpost_detail_controller.dart';
import 'package:podium/env.dart';
import 'package:podium/services/websocket/incomingMessage.dart';
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

  // Connection state
  WebSocketChannel? _channel;
  bool _isConnecting = false;
  bool connected = false;
  String token = '';

  // Timers and subscriptions
  Timer? _reconnectTimer;
  Timer? _pongTimer;
  StreamSubscription? subscription;

  // Reconnection parameters
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 20;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 10);

  // Synchronization
  final _connectionLock = Lock();

  // Private constructor for singleton
  WebSocketService._();

  /// Connects to the WebSocket server with the provided token
  Future<bool> connect(String newToken) async {
    token = newToken;
    return await _connect();
  }

  /// Calculates the delay for the next reconnection attempt using exponential backoff with jitter
  Duration _getReconnectDelay() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      return _maxReconnectDelay;
    }

    // Exponential backoff with jitter to prevent thundering herd
    final exponentialDelay = _initialReconnectDelay * (1 << _reconnectAttempts);
    final jitter = Duration(
        milliseconds: (exponentialDelay.inMilliseconds *
                0.1 *
                (DateTime.now().millisecondsSinceEpoch % 10))
            .toInt());

    // Cap at max delay
    final delay = exponentialDelay + jitter;
    return delay > _maxReconnectDelay ? _maxReconnectDelay : delay;
  }

  /// Cleans up resources when disconnecting or reconnecting
  void _cleanup() {
    _pongTimer?.cancel();
    _pongTimer = null;
    subscription?.cancel();
    subscription = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      _channel?.sink.close();
    } catch (e) {
      l.w("Error closing channel during cleanup: $e");
    }

    _channel = null;
    connected = false;
  }

  /// Attempts to reconnect to the WebSocket server
  Future<void> reconnect() async {
    if (token.isEmpty) {
      l.w("Cannot reconnect: token is empty");
      return;
    }

    // Use a lock to prevent multiple simultaneous reconnection attempts
    return _connectionLock.synchronized(() async {
      if (_isConnecting) {
        l.d("Already attempting to reconnect, skipping");
        return;
      }

      l.w("WebSocket closed, reconnecting...");
      connected = false;
      _isConnecting = true;
      _cleanup();

      if (_reconnectAttempts >= _maxReconnectAttempts) {
        l.e("Max reconnection attempts reached. Please check your connection.");
        _isConnecting = false;
        return;
      }

      final delay = _getReconnectDelay();
      l.d("Attempting to reconnect in ${delay.inSeconds} seconds (attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)");

      _reconnectTimer = Timer(delay, () async {
        _reconnectAttempts++;
        final success = await _connect();
        if (!success) {
          // Reset _isConnecting if connection failed to allow future reconnection attempts
          _isConnecting = false;
        }
      });
    });
  }

  /// Establishes a connection to the WebSocket server
  Future<bool> _connect() async {
    if (_isConnecting) {
      l.d("Connection already in progress, skipping");
      return false;
    }

    try {
      _isConnecting = true;

      // Close any existing connection first
      if (_channel != null) {
        try {
          _channel!.sink.close();
        } catch (e) {
          l.w("Error closing existing channel: $e");
        }
        _channel = null;
      }

      l.d("Connecting to WebSocket at ${Env.websocketAddress}?token=***");
      _channel = WebSocketChannel.connect(
        Uri.parse('${Env.websocketAddress}?token=$token'),
      );

      await _channel!.ready;
      _isConnecting = false;
      connected = true;
      _reconnectAttempts = 0; // Reset attempts on successful connection
      l.d("Connected to websocket: ${_channel!.hashCode}");

      _setupPongTimer();
      _setupMessageListener();

      return true;
    } catch (e) {
      l.e("Error connecting to websocket: $e");
      _isConnecting = false;
      reconnect();
      return false;
    }
  }

  /// Sets up the pong timer to keep the connection alive
  void _setupPongTimer() {
    if (_pongTimer != null) _pongTimer!.cancel();
    _pong();
    _pongTimer = Timer.periodic(const Duration(seconds: 19), (timer) {
      _pong();
    });
  }

  /// Sets up the message listener to handle incoming messages
  void _setupMessageListener() {
    subscription = _channel!.stream.listen(
      (dynamic message) => _handleIncomingMessageString(message as String),
      onError: (error) {
        l.e("WebSocket Error: $error");
        reconnect();
      },
      onDone: () {
        l.w("WebSocket connection closed");
        reconnect();
      },
    );
  }

  /// Handles incoming message strings by parsing and processing them
  void _handleIncomingMessageString(String message) {
    try {
      final jsoned = jsonDecode(message);
      if (jsoned['name'] == 'error') {
        l.e("Error: ${jsoned['data']['message']}");
        return;
      }
      final incomingMessage = IncomingMessage.fromJson(jsonDecode(message));
      _handleIncomingMessage(incomingMessage);
    } catch (e) {
      l.e("Error parsing message: $e");
    }
  }

  /// Processes incoming messages and routes them to the appropriate controllers
  void _handleIncomingMessage(IncomingMessage incomingMessage) {
    l.d('handle incoming message: ${incomingMessage.name}');

    // Process message based on type
    switch (incomingMessage.name) {
      case IncomingMessageType.userJoined:
      case IncomingMessageType.userLeft:
        if (!Get.isRegistered<OutpostCallController>()) {
          l.w("OutpostCallController not registered, cannot process userJoined or userLeft");
          return;
        }
        final outpostCallController = Get.find<OutpostCallController>();
        // NOTE: also in jitsiMeet.dart
        joinOrLeftDebounce.debounce(() {
          outpostCallController.fetchLiveData();
        });
        break;

      case IncomingMessageType.remainingTimeUpdated:
        if (!Get.isRegistered<OngoingOutpostCallController>()) {
          l.w("OngoingOutpostCallController not registered, cannot process remainingTimeUpdated");
          return;
        }
        _handleRemainingTimeUpdated(
            incomingMessage, Get.find<OngoingOutpostCallController>());
        break;

      case IncomingMessageType.userStartedSpeaking:
        if (!Get.isRegistered<OngoingOutpostCallController>()) {
          l.w("OngoingOutpostCallController not registered, cannot process userStartedSpeaking");
          return;
        }
        _handleUserStartedSpeaking(
            incomingMessage, Get.find<OngoingOutpostCallController>());
        break;

      case IncomingMessageType.userStoppedSpeaking:
        if (!Get.isRegistered<OngoingOutpostCallController>()) {
          l.w("OngoingOutpostCallController not registered, cannot process userStoppedSpeaking");
          return;
        }
        _handleUserStoppedSpeaking(
            incomingMessage, Get.find<OngoingOutpostCallController>());
        break;

      case IncomingMessageType.userLiked:
      case IncomingMessageType.userDisliked:
      case IncomingMessageType.userBooed:
      case IncomingMessageType.userCheered:
        if (!Get.isRegistered<OngoingOutpostCallController>() ||
            !Get.isRegistered<OutpostCallController>()) {
          l.w("Required controllers not registered, cannot process user reaction");
          return;
        }
        _handleUserReaction(
            incomingMessage,
            Get.find<OngoingOutpostCallController>(),
            Get.find<OutpostCallController>());
        break;

      case IncomingMessageType.timeIsUp:
        if (!Get.isRegistered<OngoingOutpostCallController>()) {
          l.w("OngoingOutpostCallController not registered, cannot process timeIsUp");
          return;
        }
        _handleTimeIsUp(
            incomingMessage, Get.find<OngoingOutpostCallController>());
        break;

      case IncomingMessageType.invite:
      case IncomingMessageType.follow:
        if (!Get.isRegistered<NotificationsController>()) {
          l.w("NotificationsController not registered, cannot process notification");
          return;
        }
        _handleNotification(
            incomingMessage, Get.find<NotificationsController>());
        break;

      case IncomingMessageType.waitlistUpdated:
        final outpostDetailControllerExists =
            Get.isRegistered<OutpostDetailController>();
        OutpostDetailController? outpostDetailController;
        if (outpostDetailControllerExists) {
          outpostDetailController = Get.find<OutpostDetailController>();
        }
        _handleWaitlistUpdated(incomingMessage, outpostDetailController,
            outpostDetailControllerExists);
        break;

      case IncomingMessageType.creatorJoined:
        final outpostDetailControllerExists =
            Get.isRegistered<OutpostDetailController>();
        OutpostDetailController? outpostDetailController;
        if (outpostDetailControllerExists) {
          outpostDetailController = Get.find<OutpostDetailController>();
        }
        _handleCreatorJoined(incomingMessage, outpostDetailController,
            outpostDetailControllerExists);
        break;
    }
  }

  /// Handles remaining time updated messages
  void _handleRemainingTimeUpdated(
      IncomingMessage message, OngoingOutpostCallController controller) {
    controller.updateUserRemainingTime(
      address: message.data.address!,
      newTimeInSeconds: message.data.remaining_time!,
    );
  }

  /// Handles user started speaking messages
  void _handleUserStartedSpeaking(
      IncomingMessage message, OngoingOutpostCallController controller) {
    controller.updateUserIsTalking(
      address: message.data.address!,
      isTalking: true,
    );
  }

  /// Handles user stopped speaking messages
  void _handleUserStoppedSpeaking(
      IncomingMessage message, OngoingOutpostCallController controller) {
    controller.updateUserIsTalking(
      address: message.data.address!,
      isTalking: false,
    );
  }

  /// Handles user reaction messages
  void _handleUserReaction(
      IncomingMessage message,
      OngoingOutpostCallController ongoingController,
      OutpostCallController outpostController) {
    ongoingController.handleIncomingReaction(message);
    outpostController.updateReactionsMapByWsEvent(message);
  }

  /// Handles time is up messages
  void _handleTimeIsUp(
      IncomingMessage message, OngoingOutpostCallController controller) {
    controller.handleTimeIsUp(message);
  }

  /// Handles notification messages
  void _handleNotification(
      IncomingMessage message, NotificationsController controller) {
    controller.getNotifications();
  }

  /// Handles waitlist updated messages
  void _handleWaitlistUpdated(IncomingMessage message,
      OutpostDetailController? controller, bool controllerExists) {
    if (controllerExists && controller != null) {
      controller.onMembersUpdated(message);
    }
  }

  /// Handles creator joined messages
  void _handleCreatorJoined(IncomingMessage message,
      OutpostDetailController? controller, bool controllerExists) {
    if (controllerExists && controller != null) {
      controller.onCreatorJoined(message);
    }
  }

  /// Sends a message to the WebSocket server with automatic reconnection
  Future<bool> send(WsOutgoingMessage message) async {
    // Check if we need to reconnect before sending
    if (!connected || _channel == null) {
      if (token.isEmpty) {
        l.w("Cannot send message: token is empty");
        return false;
      }

      l.w("Cannot send message: WebSocket not connected, attempting to reconnect");

      // Try to reconnect first
      await reconnect();

      // Check if reconnection was successful
      if (!connected || _channel == null) {
        l.e("Failed to reconnect, cannot send message");
        return false;
      }

      l.d("Reconnected successfully, now sending message");
    }

    // Send the message
    try {
      return await _sendMessage(message);
    } catch (e) {
      l.e("Error sending message: $e");

      // Try to reconnect and retry sending once
      await reconnect();

      if (connected && _channel != null) {
        try {
          return await _sendMessage(message, isRetry: true);
        } catch (e) {
          l.e("Error sending message after reconnection: $e");
          return false;
        }
      }

      return false;
    }
  }

  /// Helper method to send a message
  Future<bool> _sendMessage(WsOutgoingMessage message,
      {bool isRetry = false}) async {
    final jsoned = message.toJson();
    if (jsoned['data'] == null) {
      jsoned['data'] = {};
    }
    final stringified = jsonEncode(jsoned);
    l.d('${isRetry ? "Retrying to send" : "Sending"} message: $stringified');
    _channel?.sink.add(stringified);
    return true;
  }

  /// Sends a pong message to keep the connection alive
  void _pong() {
    if (!_isConnecting && token.isNotEmpty) {
      if (connected && _channel != null) {
        try {
          _channel?.sink.add(List<int>.from([0x8A]));
          l.d("Sent pong");
        } catch (e) {
          l.e("Error sending pong: $e");
          reconnect();
        }
      } else {
        l.w("Not connected, attempting to reconnect before sending pong");
        reconnect().then((_) {
          // After reconnection attempt, try to send pong if connected
          if (connected && _channel != null) {
            try {
              _channel?.sink.add(List<int>.from([0x8A]));
              l.d("Sent pong after reconnection");
            } catch (e) {
              l.e("Error sending pong after reconnection: $e");
            }
          }
        });
      }
    } else {
      l.w("Not sending pong because connecting or token is empty");
    }
  }

  /// Closes the WebSocket connection and cleans up resources
  void close() {
    token = '';
    _cleanup();
  }
}

/// A simple lock implementation to prevent multiple simultaneous operations
class Lock {
  bool _locked = false;
  final _completers = <Completer<void>>[];

  Future<T> synchronized<T>(Future<T> Function() action) async {
    if (_locked) {
      final completer = Completer<void>();
      _completers.add(completer);
      await completer.future;
    }

    _locked = true;
    try {
      return await action();
    } finally {
      _locked = false;
      if (_completers.isNotEmpty) {
        final completer = _completers.removeAt(0);
        completer.complete();
      }
    }
  }
}
