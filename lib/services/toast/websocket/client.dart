import 'dart:async';
import 'dart:convert';
import 'package:podium/env.dart';
import 'package:podium/services/toast/websocket/incomingMessage.dart';
import 'package:podium/services/toast/websocket/outgoingMessage.dart';
import 'package:podium/utils/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  Timer? _pongTimer;
  StreamSubscription? subscription;
  final String token;

  WebSocketService(this.token) {
    _connect();
  }

  void _connect() async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('${Env.websocketAddress}?token=$token'),
      );

      await _channel!.ready;
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
            final incomingMessage =
                IncomingMessage.fromJson(jsonDecode(message));
            print("Received: $incomingMessage");
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

  void _reconnect() {
    if (_isConnected) return;
    _isConnected = true;
    subscription?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 1), () {
      _isConnected = false;
      _connect();
    });
  }

  void send(WsOutgoingMessage message) {
    _channel?.sink.add(jsonEncode(message.toJson()));
  }

  //send a pong message type to websocket, not using out message type
  void _pong() {
    _channel?.sink.add(List<int>.from([0x8A]));
  }

  void close() {
    _channel?.sink.close(status.goingAway);
    _reconnectTimer?.cancel();
    subscription?.cancel();
  }
}
