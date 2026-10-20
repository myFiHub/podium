part of 'call_room_controller.dart';

enum PrivateMessageStatus { sending, sent, failed }

class PrivateMessage {
  /// The client id until the server confirms it, then the server's id.
  String id;
  final String clientId;
  final String peerUuid;
  final bool mine;
  final String text;
  DateTime at;
  PrivateMessageStatus status;

  /// Why sending failed, shown under the message.
  String? error;

  PrivateMessage({
    required this.id,
    required this.clientId,
    required this.peerUuid,
    required this.mine,
    required this.text,
    required this.at,
    required this.status,
    this.error,
  });
}

/// One-to-one conversation with someone in the outpost. Held only for this
/// call, like room chat.
class PrivateThread {
  final String peerUuid;
  String peerName;
  String? peerImage;
  final messages = <PrivateMessage>[];
  int unread = 0;

  PrivateThread({required this.peerUuid, required this.peerName});

  PrivateMessage? get last => messages.lastOrNull;
  DateTime get lastAt =>
      last?.at ?? DateTime.fromMillisecondsSinceEpoch(0);
}

/// Private messages, relayed by the Podium server to people present in the
/// same outpost. They don't go through Jitsi, so they reach people in other
/// breakout rooms too.
mixin _CallPrivateChat on GetxController {
  String? get _callOutpostId;
  String displayNameOf({String? uuid, String? jitsiId});
  void _showPrivatePreview(String peerUuid, String name, String text);

  static const maxPrivateLength = 1000;
  static const _ackTimeout = Duration(seconds: 10);

  final privateThreads = <String, PrivateThread>{}.obs;
  final unreadPrivate = 0.obs;

  /// The thread on screen, whose messages arrive already read.
  String? _openThreadUuid;
  final _ackTimers = <String, Timer>{};
  int _clientSeq = 0;

  BlockedUsersService get _blocks => Get.find<BlockedUsersService>();

  /// Threads, newest activity first.
  List<PrivateThread> get sortedThreads => privateThreads.values.toList()
    ..sort((a, b) => b.lastAt.compareTo(a.lastAt));

  PrivateThread _threadFor(String uuid, {String? name, String? image}) {
    final thread = privateThreads.putIfAbsent(
      uuid,
      () => PrivateThread(
        peerUuid: uuid,
        peerName: name ?? displayNameOf(uuid: uuid),
      ),
    );
    if (name != null && name.isNotEmpty) thread.peerName = name;
    if (image != null && image.isNotEmpty) thread.peerImage = image;
    return thread;
  }

  /// Marks [uuid]'s thread as on screen (or none when null) and read.
  void setOpenPrivateThread(String? uuid) {
    _openThreadUuid = uuid;
    if (uuid == null) return;
    final thread = privateThreads[uuid];
    if (thread == null || thread.unread == 0) return;
    thread.unread = 0;
    _recountPrivateUnread();
  }

  void _recountPrivateUnread() {
    unreadPrivate.value =
        privateThreads.values.fold(0, (sum, t) => sum + t.unread);
    privateThreads.refresh();
  }

  /// Returns why the message can't be sent, or null once it is on its way.
  String? sendPrivateMessage(String toUuid, String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    if (toUuid == myId) return "You can't message yourself";
    if (_blocks.isBlocked(toUuid)) {
      return 'Unblock ${displayNameOf(uuid: toUuid)} to message them';
    }
    final outpostId = _callOutpostId;
    if (outpostId == null) return 'You are not in an outpost';
    final clipped = text.length > maxPrivateLength
        ? text.substring(0, maxPrivateLength)
        : text;
    final clientId =
        'pm-${DateTime.now().microsecondsSinceEpoch}-${_clientSeq++}';
    final message = PrivateMessage(
      id: clientId,
      clientId: clientId,
      peerUuid: toUuid,
      mine: true,
      text: clipped,
      at: DateTime.now(),
      status: PrivateMessageStatus.sending,
    );
    _threadFor(toUuid).messages.add(message);
    privateThreads.refresh();
    _transmit(outpostId, message);
    return null;
  }

  void retryPrivateMessage(PrivateMessage message) {
    if (!message.mine || message.status != PrivateMessageStatus.failed) return;
    final outpostId = _callOutpostId;
    if (outpostId == null) return;
    message
      ..status = PrivateMessageStatus.sending
      ..error = null
      ..at = DateTime.now();
    privateThreads.refresh();
    _transmit(outpostId, message);
  }

  void _transmit(String outpostId, PrivateMessage message) {
    _ackTimers[message.clientId]?.cancel();
    _ackTimers[message.clientId] = Timer(_ackTimeout, () {
      _ackTimers.remove(message.clientId);
      _failPrivate(message.clientId, 'Not delivered. Tap to retry.');
    });
    wsClient
        .sendPrivateMessage(
      outpostId: outpostId,
      toUuid: message.peerUuid,
      text: message.text,
      clientId: message.clientId,
    )
        .then((sent) {
      if (!sent) {
        _failPrivate(message.clientId, 'You are offline. Tap to retry.');
      }
    });
  }

  PrivateMessage? _pendingByClientId(String? clientId) {
    if (clientId == null) return null;
    for (final thread in privateThreads.values) {
      for (final message in thread.messages.reversed) {
        if (message.mine && message.clientId == clientId) return message;
      }
    }
    return null;
  }

  void _failPrivate(String clientId, String error) {
    _ackTimers.remove(clientId)?.cancel();
    final message = _pendingByClientId(clientId);
    if (message == null || message.status != PrivateMessageStatus.sending) {
      return;
    }
    message
      ..status = PrivateMessageStatus.failed
      ..error = error;
    privateThreads.refresh();
  }

  void _onPrivateMessageEvent(String name, Map<String, dynamic> data) {
    final outpostId = data['outpost_uuid']?.toString();
    if (outpostId != null && outpostId != _callOutpostId) return;
    switch (name) {
      case 'private_message.received':
        _onPrivateReceived(data);
      case 'private_message.sent':
        _onPrivateSent(data);
      case 'private_message.rejected':
        final clientId = data['client_id']?.toString();
        if (clientId == null) return;
        _failPrivate(clientId, _rejectionText(data));
    }
  }

  void _onPrivateReceived(Map<String, dynamic> data) {
    final from = data['from_uuid']?.toString();
    final text = data['text']?.toString();
    if (from == null || text == null || from == myId) return;
    // The server already refuses these; this covers a block that is still
    // on its way to the server.
    if (_blocks.isBlocked(from)) return;
    final id = data['id']?.toString() ??
        '$from-${DateTime.now().microsecondsSinceEpoch}';
    final thread = _threadFor(
      from,
      name: data['from_name']?.toString(),
      image: data['from_image']?.toString(),
    );
    if (thread.messages.any((m) => m.id == id)) return;
    thread.messages.add(PrivateMessage(
      id: id,
      clientId: id,
      peerUuid: from,
      mine: false,
      text: text,
      at: DateTime.tryParse(data['sent_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      status: PrivateMessageStatus.sent,
    ));
    if (_openThreadUuid == from) {
      privateThreads.refresh();
      return;
    }
    thread.unread++;
    _recountPrivateUnread();
    _showPrivatePreview(from, thread.peerName, text);
  }

  void _onPrivateSent(Map<String, dynamic> data) {
    final clientId = data['client_id']?.toString();
    _ackTimers.remove(clientId)?.cancel();
    final message = _pendingByClientId(clientId);
    if (message == null) return;
    message
      ..id = data['id']?.toString() ?? message.id
      ..status = PrivateMessageStatus.sent
      ..error = null;
    privateThreads.refresh();
  }

  String _rejectionText(Map<String, dynamic> data) {
    final to = data['to_uuid']?.toString();
    final name = to == null ? 'They' : displayNameOf(uuid: to);
    switch (data['reason']) {
      case 'recipient_left':
        return '$name left the outpost';
      case 'not_in_outpost':
        return 'You are not in this outpost anymore';
      case 'you_blocked':
        return 'You blocked $name';
      case 'unavailable':
        return "$name can't receive private messages";
      case 'rate_limited':
        return 'Too many messages. Wait a moment and tap to retry.';
      case 'too_long':
        return 'Message is too long';
      default:
        return data['message']?.toString() ?? 'Not delivered. Tap to retry.';
    }
  }

  /// Drops [uuid]'s conversation, e.g. after blocking them.
  void clearPrivateThread(String uuid) {
    final thread = privateThreads.remove(uuid);
    if (thread == null) return;
    for (final message in thread.messages) {
      _ackTimers.remove(message.clientId)?.cancel();
    }
    _recountPrivateUnread();
  }

  void _disposePrivateChat() {
    for (final timer in _ackTimers.values) {
      timer.cancel();
    }
    _ackTimers.clear();
  }
}
