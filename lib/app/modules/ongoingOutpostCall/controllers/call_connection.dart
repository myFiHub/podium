part of 'call_room_controller.dart';

/// Connection quality of the local participant and of remote participants,
/// 0..100, as sent in a `connectionQuality` event.
class ConnectionQualityUpdate {
  final int? local;
  final Map<String, int> remote;
  const ConnectionQualityUpdate({required this.local, required this.remote});

  static ConnectionQualityUpdate? tryParse(Map<String, dynamic> data) {
    int? clamp(dynamic v) => v is num ? v.round().clamp(0, 100) : null;
    final remote = <String, int>{};
    final raw = data['remote'];
    if (raw is Map) {
      raw.forEach((id, value) {
        final q = clamp(value);
        if (q != null) remote[id.toString()] = q;
      });
    }
    final local = clamp(data['local']);
    if (local == null && remote.isEmpty) return null;
    return ConnectionQualityUpdate(local: local, remote: remote);
  }
}

/// Reconnect state of the conference and per-member connection quality.
mixin _CallConnection on GetxController {
  /// Below this, a member's connection is shown as weak.
  static const weakQuality = 30;

  String? uuidOf(String? jitsiId);

  final reconnecting = false.obs;
  final _qualities = <String, RxnInt>{};

  /// One observable per member so a quality change only rebuilds that badge.
  RxnInt qualityOf(String uuid) => _qualities.putIfAbsent(uuid, RxnInt.new);

  bool isWeakConnection(String uuid) {
    final q = qualityOf(uuid).value;
    return q != null && q < weakQuality;
  }

  void _onConnectionState(Map<String, dynamic> data) {
    final state = data['state'];
    if (state == 'interrupted') {
      reconnecting.value = true;
    } else if (state == 'restored') {
      reconnecting.value = false;
    }
  }

  void _onConnectionQuality(Map<String, dynamic> data) {
    final update = ConnectionQualityUpdate.tryParse(data);
    if (update == null) return;
    if (update.local != null) qualityOf(myId).value = update.local;
    update.remote.forEach((jitsiId, quality) {
      final uuid = uuidOf(jitsiId);
      if (uuid != null) qualityOf(uuid).value = quality;
    });
  }

  void _forgetQuality(String? uuid) {
    if (uuid != null) _qualities[uuid]?.value = null;
  }
}

class ConferenceFailure {
  final String title;
  final String message;

  /// No specific reason is known; only worth showing before the call joined.
  final bool isGeneric;
  const ConferenceFailure(this.title, this.message, {this.isGeneric = false});
}

/// User-facing reason for the error a conference ended with, or null when it
/// ended on purpose (hang-up, kick, room switch).
ConferenceFailure? conferenceErrorMessage(Object? error) {
  if (error == null) return null;
  final code = error.toString();
  if (code.isEmpty || code.contains('kicked')) return null;
  return switch (code) {
    'conference.max_users' => const ConferenceFailure(
        'Outpost is full',
        'This outpost reached its participant limit. Try again later.',
      ),
    'conference.authenticationRequired' ||
    'conference.connectionError.accessDenied' ||
    'conference.connectionError.notAllowed' ||
    'conference.connectionError.membersOnly' ||
    'conference.passwordRequired' ||
    'connection.passwordRequired' =>
      const ConferenceFailure(
        'No access',
        "The audio server didn't let you into this outpost.",
      ),
    'conference.destroyed' => const ConferenceFailure(
        'Outpost ended',
        'The audio room was closed.',
      ),
    'connection.droppedError' ||
    'conference.iceFailed' ||
    'conference.focusDisconnected' ||
    'conference.focusLeft' =>
      const ConferenceFailure(
        'Connection lost',
        'Your connection to the outpost dropped. Please rejoin.',
      ),
    'conference.gracefulShutdown' ||
    'conference.videobridgeNotAvailable' ||
    'connection.serverError' ||
    'connection.shardChangedError' =>
      const ConferenceFailure(
        'Server unavailable',
        'The audio server is busy or restarting. Try again shortly.',
      ),
    _ => const ConferenceFailure(
        "Couldn't connect",
        'Failed to join the outpost, please try again',
        isGeneric: true,
      ),
  };
}
