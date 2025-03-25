import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/env.dart';
import 'package:podium/services/websocket/incomingMessage.dart';
import 'package:podium/services/websocket/outgoingMessage.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/throttleAndDebounce/throttle.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

final joinOrLeftThrottle = Throttling(duration: const Duration(seconds: 1));

class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  bool connected = false;
  Timer? _pongTimer;
  StreamSubscription? subscription;
  final String token;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 20;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);

  WebSocketService(this.token) {
    _connect();
  }

  Duration _getReconnectDelay() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      return const Duration(seconds: 30); // Max delay of 30 seconds
    }
    return _initialReconnectDelay *
        (1 << _reconnectAttempts); // Exponential backoff
  }

  void _cleanup() {
    _pongTimer?.cancel();
    _pongTimer = null;
    subscription?.cancel();
    subscription = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    connected = false;
  }

  void _reconnect() {
    if (_isConnecting) return;

    _isConnecting = true;
    _cleanup();

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      l.e("Max reconnection attempts reached. Please check your connection.");
      _isConnecting = false;
      return;
    }

    final delay = _getReconnectDelay();
    l.d("Attempting to reconnect in ${delay.inSeconds} seconds (attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)");

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _connect();
    });
  }

  void _connect() async {
    try {
      _isConnecting = true;
      _channel = WebSocketChannel.connect(
        Uri.parse('${Env.websocketAddress}?token=$token'),
      );

      await _channel!.ready;
      _isConnecting = false;
      connected = true;
      _reconnectAttempts = 0; // Reset attempts on successful connection
      l.d("Connected to websocket: ${_channel!.hashCode}");
      //  sen pong every 20 seconds
      if (_pongTimer != null) _pongTimer!.cancel();
      _pong();
      _pongTimer = Timer.periodic(const Duration(seconds: 19), (timer) {
        _pong();
      });

      subscription = _channel!.stream.listen(
        (message) {
          try {
            final jsoned = jsonDecode(message);
            if (jsoned['name'] == 'error') {
              l.e("Error: ${jsoned['data']['message']}");
              return;
            }
            final incomingMessage =
                IncomingMessage.fromJson(jsonDecode(message));
            _handleIncomingMessage(incomingMessage);
          } catch (e) {
            print("Error parsing message: $e");
          }
        },
        onError: (error) {
          print("WebSocket Error: $error");
          _reconnect();
        },
        onDone: () {
          print("WebSocket closed, reconnecting...");
          _reconnect();
        },
      );
    } catch (e) {
      l.e("Error connecting to websocket: $e");
      _reconnect();
    }
  }

  void _handleIncomingMessage(IncomingMessage incomingMessage) {
    l.d('handle incoming message: ${incomingMessage.name}');
    final outpostCallControllerExists =
        Get.isRegistered<OutpostCallController>();
    if (!outpostCallControllerExists) {
      return;
    }
    final exists = Get.isRegistered<OngoingOutpostCallController>();
    if (!exists) return;

    final ongoingOutpostCallController =
        Get.find<OngoingOutpostCallController>();
    final OutpostCallController outpostCallController =
        Get.find<OutpostCallController>();
    final notificationsController = Get.find<NotificationsController>();
    switch (incomingMessage.name) {
      case IncomingMessageType.userJoined:
      case IncomingMessageType.userLeft:
        joinOrLeftThrottle.throttle(() {
          outpostCallController.fetchLiveData();
        });
        break;
      case IncomingMessageType.remainingTimeUpdated:
        {
          ongoingOutpostCallController.updateUserRemainingTime(
            address: incomingMessage.data.address!,
            newTimeInSeconds: incomingMessage.data.remaining_time!,
          );
        }
      case IncomingMessageType.userStartedSpeaking:
        {
          ongoingOutpostCallController.updateUserIsTalking(
            address: incomingMessage.data.address!,
            isTalking: true,
          );
        }
        break;
      case IncomingMessageType.userStoppedSpeaking:
        {
          ongoingOutpostCallController.updateUserIsTalking(
            address: incomingMessage.data.address!,
            isTalking: false,
          );
        }
        break;

      case IncomingMessageType.userLiked:
      case IncomingMessageType.userDisliked:
      case IncomingMessageType.userBooed:
      case IncomingMessageType.userCheered:
        ongoingOutpostCallController.handleIncomingReaction(incomingMessage);
        outpostCallController.updateReactionsMapByWsEvent(incomingMessage);
        break;
      case IncomingMessageType.timeIsUp:
        ongoingOutpostCallController.handleTimeIsUp(incomingMessage);
      case IncomingMessageType.invite:
      case IncomingMessageType.follow:
        notificationsController.getNotifications();
    }
  }

  void send(WsOutgoingMessage message) {
    final jsoned = message.toJson();
    if (jsoned['data'] == null) {
      jsoned['data'] = {};
    }
    final stringified = jsonEncode(jsoned);
    l.d('Sending message: $stringified');
    _channel?.sink.add(stringified);
  }

  //send a pong message type to websocket, not using out message type
  void _pong() {
    if (!_isConnecting && connected) {
      _channel?.sink.add(List<int>.from([0x8A]));
    }
  }

  void close() {
    _channel?.sink.close(status.goingAway);
    _reconnectTimer?.cancel();
    subscription?.cancel();
  }
}
