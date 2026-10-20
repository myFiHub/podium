import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/outpostDetail/controllers/outpost_detail_controller.dart';
import 'package:podium/app/services/replay/replay_recorder.dart';
import 'package:podium/env.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost_ban.dart';
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
  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _closeTimeout = Duration(seconds: 2);

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
      final timeZoneString = await FlutterTimezone.getLocalTimezone();

      final uri = Uri.parse(
          '${Env.websocketAddress}?token=$token&timezone=$timeZoneString');
      l.d('Connecting to WebSocket: ${uri.toString().replaceAll(token, '***')}');

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready.timeout(_connectTimeout);

      _setState(WebSocketState.connected);
      _reconnectAttempts = 0;
      _setupListeners();
      _startPingTimer();
      _rejoinCurrentOutpost();

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
  Future<bool> send(WsOutgoingMessage message) {
    final json = message.toJson();
    json['data'] ??= {};
    return sendJson(json);
  }

  /// Sends a private message to someone present in [outpostId]. The server
  /// answers with `private_message.sent` or `private_message.rejected`
  /// carrying [clientId].
  Future<bool> sendPrivateMessage({
    required String outpostId,
    required String toUuid,
    required String text,
    required String clientId,
  }) {
    return sendJson({
      'message_type': 'private_message',
      'outpost_uuid': outpostId,
      'data': {'to_uuid': toUuid, 'text': text, 'client_id': clientId},
    });
  }

  /// Sends [json] as is, reconnecting first if needed.
  Future<bool> sendJson(Map<String, dynamic> json) async {
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
      final jsonString = jsonEncode(json);

      if (kDebugMode) l.d('Sending message: $jsonString');
      _channel!.sink.add(jsonString);
      return true;
    } catch (e) {
      l.e('Error sending message: $e');
      _setState(WebSocketState.disconnected);
      _scheduleReconnect();
      return false;
    }
  }

  /// Reconnects right away (with a fresh retry budget) unless already
  /// connected or connecting. For when the app returns to the foreground or
  /// the network comes back, instead of waiting out the backoff.
  Future<void> ensureConnected() async {
    if (_token.isEmpty || isConnected || isConnecting) return;
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    await connect(_token);
  }

  /// Legacy reconnect method for API compatibility
  Future<bool> reconnect() async {
    if (_token.isEmpty) {
      l.w('Cannot reconnect: no token available');
      return false;
    }
    return await connect(_token);
  }

  final Map<String, Future<bool>> _inflightJoins = {};

  /// Outposts that refused our join because a host removed or blocked us.
  /// Retrying would only be refused again.
  final Map<String, OutpostBanInfo> _joinRejections = {};

  /// Why the last join of [outpostId] was refused, while that still applies.
  OutpostBanInfo? joinRejectionFor(String outpostId) {
    final rejection = _joinRejections[outpostId];
    if (rejection != null && !rejection.isActive) {
      _joinRejections.remove(outpostId);
      return null;
    }
    return rejection;
  }

  /// Join an outpost with simplified logic. A join already in flight for the
  /// same outpost is shared: the server only answers the first join, so a
  /// second one would just time out.
  Future<bool> joinOutpost(String outpostId,
      {bool force = false, bool withRetry = false}) {
    final inflight = _inflightJoins[outpostId];
    if (inflight != null) return inflight;
    _joinRejections.remove(outpostId);

    final join = withRetry
        ? _joinOutpostWithRetry(outpostId, force: force)
        : _joinOutpostSingle(outpostId, force: force);
    _inflightJoins[outpostId] = join;
    join.whenComplete(() {
      if (identical(_inflightJoins[outpostId], join)) {
        _inflightJoins.remove(outpostId);
      }
    });
    return join;
  }

  /// Single join attempt
  Future<bool> _joinOutpostSingle(String outpostId,
      {bool force = false}) async {
    if (!force && _isAlreadyJoined(outpostId)) {
      l.d('Already joined outpost: $outpostId');
      return true;
    }

    final joinId = _generateJoinId(outpostId);
    final completer = Completer<bool>();
    _joinRequests[joinId] = completer;

    // Set timeout for join request
    final timeout = Timer(const Duration(seconds: 10), () {
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
    } finally {
      timeout.cancel();
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
        if (_joinRejections.containsKey(outpostId)) return false;

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
      if (newState != WebSocketState.connecting) {
        ReplayRecorder.instance.onConnection(
          online: newState == WebSocketState.connected,
        );
      }
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
      if (kDebugMode) {
        l.d('Received message: ${messageStr.length > 100 ? '${messageStr.substring(0, 100)}...' : messageStr}');
      }

      final json = jsonDecode(messageStr);
      if (json['name'] == 'error') {
        final data = json['data'];
        l.e('WebSocket error: ${data['message']}');
        if (data is Map && data['code'] == 'outpost_ban') {
          _handleJoinRefused(Map<String, dynamic>.from(data));
        }
        return;
      }

      // Not outpost events, so IncomingMessage can't parse them.
      final name = json['name'];
      if (name is String &&
          (name.startsWith('private_message.') ||
              name == 'breakout_rooms.updated')) {
        final data = json['data'];
        if (data is Map) {
          findCallRoom()?.onServerEvent(name, Map<String, dynamic>.from(data));
        }
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
    l.w('WebSocket disconnected: code ${_channel?.closeCode}, '
        'reason ${_channel?.closeReason}');
    _setState(WebSocketState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_token.isEmpty) return;

    _reconnectTimer?.cancel();

    // A live call keeps retrying at the max delay rather than giving up.
    if (_reconnectAttempts >= _maxReconnectAttempts && !_isInCall) {
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

  /// Keep this app-level message: with protocol pings instead, the server
  /// dropped the connection shortly after every outpost join.
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (isConnected) {
        try {
          _channel!.sink.add([0x8A]);
        } catch (e) {
          l.e('Error sending ping: $e');
          _setState(WebSocketState.disconnected);
          _scheduleReconnect();
        }
      }
    });
  }

  bool get _isInCall =>
      Get.isRegistered<OutpostCallController>() &&
      Get.find<OutpostCallController>().isInCall.value;

  /// The outpost of the live call, if any.
  String? get _currentCallOutpostId {
    if (!_isInCall) return null;
    return Get.find<OutpostCallController>().outpost.value?.uuid;
  }

  /// After a reconnect the server no longer knows we're in the outpost.
  void _rejoinCurrentOutpost() {
    final outpostId = _currentCallOutpostId;
    if (outpostId != null) {
      joinOutpost(outpostId, force: true);
    }
  }

  Future<void> _closeChannel() async {
    final channel = _channel;
    if (channel == null) return;
    _channel = null;
    try {
      // sink.close() never completes on a channel that failed to connect.
      await channel.sink.close().timeout(_closeTimeout);
    } catch (e) {
      l.w('Error closing channel: $e');
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

  int _joinCounter = 0;

  /// Unique per attempt so concurrent or retried joins never overwrite each
  /// other's completer.
  String _generateJoinId(String outpostId) => '$outpostId#${_joinCounter++}';

  bool _isAlreadyJoined(String outpostId) =>
      _currentCallOutpostId == outpostId;

  void _completeJoinRequest(String joinId) {
    if (_joinRequests.containsKey(joinId)) {
      l.d('Completing join request: $joinId');
      _joinRequests[joinId]!.complete(true);
      _joinRequests.remove(joinId);
    }
  }

  // Simplified message routing
  void _routeMessage(IncomingMessage message) {
    if (kDebugMode) l.d('Routing message: ${message.name}');
    ReplayRecorder.instance.onWsMessage(message);

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
      case IncomingMessageType.userRemoved:
        _handleUserRemoved(message);
        break;
    }
  }

  /// Fails the outpost's pending joins right away instead of letting them
  /// time out and retry.
  void _rejectJoins(String outpostId, OutpostBanInfo ban) {
    _joinRejections[outpostId] = ban;
    final pending =
        _joinRequests.keys.where((id) => id.startsWith('$outpostId#')).toList();
    for (final id in pending) {
      final completer = _joinRequests.remove(id);
      if (completer != null && !completer.isCompleted) completer.complete(false);
    }
  }

  void _handleJoinRefused(Map<String, dynamic> data) {
    final outpostId = data['outpost_uuid'] as String?;
    if (outpostId == null) return;
    final ban = OutpostBanInfo.fromJson(data);
    _rejectJoins(outpostId, ban);
    _withController<OutpostCallController>((controller) {
      controller.onRemovedFromOutpost(outpostId, ban);
    });
  }

  void _handleUserRemoved(IncomingMessage message) {
    final data = message.data;
    final outpostId = data.outpost_uuid;
    final uuid = data.uuid;
    if (outpostId == null || uuid == null) return;
    final ban = OutpostBanInfo(kind: data.kind ?? 'ban', expires_at: data.expires_at);
    if (uuid == myId) {
      _rejectJoins(outpostId, ban);
      _withController<OutpostCallController>((controller) {
        controller.onRemovedFromOutpost(outpostId, ban);
      });
      return;
    }
    if (Get.isRegistered<CallRoomController>()) {
      Get.find<CallRoomController>().onUserRemoved(
        outpostId: outpostId,
        uuid: uuid,
        ban: ban,
        removedByUuid: data.removed_by_uuid,
      );
    }
  }

  void _handleUserJoined(IncomingMessage message) {
    if (message.data.address == myUser.address) {
      final outpostId = message.data.outpost_uuid;
      final pending = _joinRequests.keys
          .where((id) => outpostId == null || id.startsWith('$outpostId#'))
          .toList();
      pending.forEach(_completeJoinRequest);
    }

    _withController<OutpostCallController>((controller) {
      joinOrLeftDebounce.debounce(() => controller.fetchLiveData());
    });
  }

  void _handleUserLeft(IncomingMessage message) {
    _withController<OutpostCallController>((controller) {
      if (message.data.address != myUser.address) {
        joinOrLeftDebounce.debounce(() => controller.fetchLiveData());
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
