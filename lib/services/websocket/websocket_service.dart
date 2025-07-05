import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/outpostDetail/controllers/outpost_detail_controller.dart';
import 'package:podium/env.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/services/websocket/incomingMessage.dart';
import 'package:podium/services/websocket/outgoingMessage.dart';
import 'package:podium/utils/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum WebSocketState {
  disconnected,
  connecting,
  connected,
}

/// Simplified WebSocket service that handles all websocket operations
/// This replaces the complex multi-file architecture with a single reliable service
class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._();

  // Core state
  WebSocketChannel? _channel;
  WebSocketState _state = WebSocketState.disconnected;
  String _token = '';

  // Timers and subscriptions
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  StreamSubscription? _subscription;

  // Join request management
  final Map<String, Completer<bool>> _joinRequests = {};

  // Reconnection state
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 20;
  static const Duration _baseReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);

  WebSocketService._();

  // Public getters
  WebSocketState get state => _state;
  bool get isConnected => _state == WebSocketState.connected;
  bool get isConnecting => _state == WebSocketState.connecting;
  bool get isDisconnected => _state == WebSocketState.disconnected;

  // Legacy API compatibility
  bool get connected => isConnected;

  /// Connect to the websocket server
  Future<bool> connect(String token) async {
    if (token.isEmpty) {
      l.e('Cannot connect: token is empty');
      return false;
    }

    _token = token;
    _setState(WebSocketState.connecting);

    try {
      await _closeChannel();

      final uri = Uri.parse('${Env.websocketAddress}?token=$token');
      l.d('Connecting to WebSocket: ${uri.toString().replaceAll(token, '***')}');

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _setState(WebSocketState.connected);
      _reconnectAttempts = 0;
      _setupListeners();
      _startPingTimer();

      l.d('WebSocket connected successfully');
      return true;
    } catch (e) {
      l.e('Failed to connect to WebSocket: $e');
      _setState(WebSocketState.disconnected);
      _scheduleReconnect();
      return false;
    }
  }

  /// Send a message through the websocket
  Future<bool> send(WsOutgoingMessage message) async {
    if (!isConnected) {
      l.w('Cannot send message: not connected. Attempting to reconnect...');
      if (_token.isEmpty) {
        l.e('Cannot reconnect: no token available');
        return false;
      }

      final success = await connect(_token);
      if (!success) {
        l.e('Failed to reconnect for sending message');
        return false;
      }
    }

    try {
      final json = message.toJson();
      json['data'] ??= {};
      final jsonString = jsonEncode(json);

      l.d('Sending message: $jsonString');
      _channel!.sink.add(jsonString);
      return true;
    } catch (e) {
      l.e('Error sending message: $e');
      _setState(WebSocketState.disconnected);
      _scheduleReconnect();
      return false;
    }
  }

  /// Legacy reconnect method for API compatibility
  Future<bool> reconnect() async {
    if (_token.isEmpty) {
      l.w('Cannot reconnect: no token available');
      return false;
    }
    return await connect(_token);
  }

  /// Join an outpost with simplified logic
  Future<bool> joinOutpost(String outpostId,
      {bool force = false, bool withRetry = false}) async {
    if (withRetry) {
      return await _joinOutpostWithRetry(outpostId, force: force);
    }

    return await _joinOutpostSingle(outpostId, force: force);
  }

  /// Single join attempt
  Future<bool> _joinOutpostSingle(String outpostId,
      {bool force = false}) async {
    if (!force && _isAlreadyJoined(outpostId)) {
      l.d('Already joined outpost: $outpostId');
      return true;
    }

    final joinId = _generateJoinId();
    final completer = Completer<bool>();
    _joinRequests[joinId] = completer;

    // Set timeout for join request
    Timer(const Duration(seconds: 10), () {
      if (_joinRequests.containsKey(joinId)) {
        l.w('Join request timed out for outpost: $outpostId');
        _joinRequests[joinId]!.complete(false);
        _joinRequests.remove(joinId);
      }
    });

    try {
      final success = await send(WsOutgoingMessage(
        message_type: OutgoingMessageTypeEnums.join,
        outpost_uuid: outpostId,
      ));

      if (!success) {
        l.e('Failed to send join message for outpost: $outpostId');
        _joinRequests.remove(joinId);
        return false;
      }

      return await completer.future;
    } catch (e) {
      l.e('Error joining outpost: $e');
      _joinRequests.remove(joinId);
      return false;
    }
  }

  /// Join with retry logic for better reliability
  Future<bool> _joinOutpostWithRetry(String outpostId,
      {bool force = false}) async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      l.d('Join attempt $attempt/$maxRetries for outpost: $outpostId');

      try {
        final success = await _joinOutpostSingle(outpostId, force: force);
        if (success) {
          l.d('Join succeeded on attempt $attempt for outpost: $outpostId');
          return true;
        }

        if (attempt < maxRetries) {
          l.w('Join attempt $attempt failed, will retry in 1 second...');
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        l.e('Error during join attempt $attempt: $e');
        if (attempt >= maxRetries) {
          l.e('Max retry attempts reached for outpost: $outpostId');
          return false;
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    l.e('Failed to join outpost after $maxRetries attempts: $outpostId');
    return false;
  }

  /// Close the websocket connection
  void close() {
    _token = '';
    _cleanup();
  }

  /// Force reset the connection
  void reset() {
    l.w('Force resetting websocket connection');
    _reconnectAttempts = 0;
    _cleanup();
  }

  // Private methods
  void _setState(WebSocketState newState) {
    if (_state != newState) {
      l.d('WebSocket state changed: $_state -> $newState');
      _state = newState;
    }
  }

  void _setupListeners() {
    _subscription?.cancel();
    _subscription = _channel!.stream.listen(
      _handleMessage,
      onError: _handleError,
      onDone: _handleDisconnect,
    );
  }

  void _handleMessage(dynamic message) {
    try {
      final messageStr = message.toString();
      l.d('Received message: ${messageStr.length > 100 ? '${messageStr.substring(0, 100)}...' : messageStr}');

      final json = jsonDecode(messageStr);
      if (json['name'] == 'error') {
        l.e('WebSocket error: ${json['data']['message']}');
        return;
      }

      final incomingMessage = IncomingMessage.fromJson(json);
      _routeMessage(incomingMessage);
    } catch (e) {
      l.e('Error handling message: $e');
    }
  }

  void _handleError(error) {
    l.e('WebSocket error: $error');
    _setState(WebSocketState.disconnected);
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    l.w('WebSocket disconnected');
    _setState(WebSocketState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_token.isEmpty) return;

    _reconnectTimer?.cancel();

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      l.e('Max reconnection attempts reached');
      Toast.error(
          message: 'Connection lost. Please check your internet connection.');
      return;
    }

    final delay = _calculateReconnectDelay();
    l.d('Scheduling reconnect in ${delay.inSeconds} seconds (attempt ${_reconnectAttempts + 1})');

    _reconnectTimer = Timer(delay, () {
      // Check if already connected before attempting reconnect
      if (isConnected) {
        l.d('Already connected, skipping reconnect attempt');
        _reconnectAttempts = 0; // Reset attempts since we're good
        return;
      }

      _reconnectAttempts++;
      connect(_token);
    });
  }

  Duration _calculateReconnectDelay() {
    final exponentialDelay =
        _baseReconnectDelay * (1 << min(_reconnectAttempts, 5));
    final jitter = Duration(milliseconds: Random().nextInt(1000));
    final totalDelay = exponentialDelay + jitter;
    return totalDelay > _maxReconnectDelay ? _maxReconnectDelay : totalDelay;
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (isConnected) {
        try {
          _channel!.sink.add([0x8A]); // WebSocket ping frame
        } catch (e) {
          l.e('Error sending ping: $e');
          _setState(WebSocketState.disconnected);
          _scheduleReconnect();
        }
      }
    });
  }

  Future<void> _closeChannel() async {
    if (_channel != null) {
      try {
        await _channel!.sink.close();
      } catch (e) {
        l.w('Error closing channel: $e');
      }
      _channel = null;
    }
  }

  void _cleanup() {
    _setState(WebSocketState.disconnected);
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _subscription?.cancel();
    _reconnectTimer = null;
    _pingTimer = null;
    _subscription = null;

    _closeChannel();

    // Complete all pending join requests
    for (final completer in _joinRequests.values) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }
    _joinRequests.clear();
  }

  String _generateJoinId() => 'join-${myUser.address}';

  bool _isAlreadyJoined(String outpostId) {
    if (!Get.isRegistered<OngoingOutpostCallController>()) return false;

    final currentOutpost = Get.find<OngoingOutpostCallController>()
        .outpostCallController
        .outpost
        .value;

    return currentOutpost?.uuid == outpostId;
  }

  void _completeJoinRequest(String joinId) {
    if (_joinRequests.containsKey(joinId)) {
      l.d('Completing join request: $joinId');
      _joinRequests[joinId]!.complete(true);
      _joinRequests.remove(joinId);
    }
  }

  // Simplified message routing
  void _routeMessage(IncomingMessage message) {
    l.d('Routing message: ${message.name}');

    switch (message.name) {
      case IncomingMessageType.userJoined:
        _handleUserJoined(message);
        break;
      case IncomingMessageType.userLeft:
        _handleUserLeft(message);
        break;
      case IncomingMessageType.remainingTimeUpdated:
        _handleRemainingTimeUpdated(message);
        break;
      case IncomingMessageType.userStartedSpeaking:
        _handleUserSpeaking(message, true);
        break;
      case IncomingMessageType.userStoppedSpeaking:
        _handleUserSpeaking(message, false);
        break;
      case IncomingMessageType.userLiked:
      case IncomingMessageType.userDisliked:
      case IncomingMessageType.userBooed:
      case IncomingMessageType.userCheered:
        _handleUserReaction(message);
        break;
      case IncomingMessageType.timeIsUp:
        _handleTimeIsUp(message);
        break;
      case IncomingMessageType.invite:
      case IncomingMessageType.follow:
        _handleNotification(message);
        break;
      case IncomingMessageType.waitlistUpdated:
        _handleWaitlistUpdated(message);
        break;
      case IncomingMessageType.creatorJoined:
        _handleCreatorJoined(message);
        break;
      case IncomingMessageType.userStartedRecording:
        _handleUserRecording(message, true);
        break;
      case IncomingMessageType.userStoppedRecording:
        _handleUserRecording(message, false);
        break;
    }
  }

  void _handleUserJoined(IncomingMessage message) {
    if (message.data.address == myUser.address) {
      final joinId = _generateJoinId();
      _completeJoinRequest(joinId);
    }

    _withController<OutpostCallController>((controller) {
      joinOrLeftDebounce.debounce(() => controller.fetchLiveData());
    });
  }

  void _handleUserLeft(IncomingMessage message) {
    _withController<OutpostCallController>((controller) {
      if (message.data.address != myUser.address) {
        controller.fetchLiveData();
      }
    });
  }

  void _handleRemainingTimeUpdated(IncomingMessage message) {
    _withController<OngoingOutpostCallController>((controller) {
      controller.updateUserRemainingTime(
        address: message.data.address!,
        newTimeInSeconds: message.data.remaining_time!,
      );
    });
  }

  void _handleUserSpeaking(IncomingMessage message, bool isTalking) {
    _withController<OngoingOutpostCallController>((controller) {
      controller.updateUserIsTalking(
        address: message.data.address!,
        isTalking: isTalking,
      );
    });
  }

  void _handleUserReaction(IncomingMessage message) {
    if (!Get.isRegistered<OngoingOutpostCallController>() ||
        !Get.isRegistered<OutpostCallController>()) {
      l.w('Required controllers not registered for user reaction');
      return;
    }

    final ongoingController = Get.find<OngoingOutpostCallController>();
    final outpostController = Get.find<OutpostCallController>();

    outpostController.updateReactionsMapByWsEvent(message);
    ongoingController.handleIncomingReaction(message);
  }

  void _handleTimeIsUp(IncomingMessage message) {
    _withController<OngoingOutpostCallController>((controller) {
      controller.handleTimeIsUp(message);
    });
  }

  void _handleNotification(IncomingMessage message) {
    _withController<NotificationsController>((controller) {
      controller.getNotifications();
    });
  }

  void _handleWaitlistUpdated(IncomingMessage message) {
    _withController<OutpostDetailController>((controller) {
      controller.onMembersUpdated(message);
    });
  }

  void _handleCreatorJoined(IncomingMessage message) {
    _withController<OutpostDetailController>((controller) {
      controller.onCreatorJoined(message);
    });
  }

  void _handleUserRecording(IncomingMessage message, bool isRecording) {
    _withController<OngoingOutpostCallController>((controller) {
      if (isRecording) {
        controller.onUserStartedRecording(message);
      } else {
        controller.onUserStoppedRecording(message);
      }
    });
  }

  void _withController<T>(void Function(T controller) action) {
    if (!Get.isRegistered<T>()) {
      l.w('${T.toString()} not registered, cannot process message');
      return;
    }
    action(Get.find<T>());
  }
}
