part of 'call_room_controller.dart';

/// Keeps people a host removed out of the Jitsi room. The Podium server
/// stops them from rejoining the outpost, but it has no say over the Jitsi
/// server, so moderators in the room kick them if their app doesn't leave by
/// itself or they come back with a modified one.
mixin _CallModeration on GetxController {
  String? jitsiIdOf(String uuid);
  String displayNameOf({String? uuid, String? jitsiId});
  bool get amIHost;
  RxnString get localRole;
  String? get _callOutpostId;

  /// Removed uuid -> when they may come back, or null for a block.
  final _removedUntil = <String, DateTime?>{};
  final _moderationRandom = Random();

  bool _isRemoved(String uuid) {
    if (!_removedUntil.containsKey(uuid)) return false;
    final until = _removedUntil[uuid];
    if (until != null && !until.isAfter(DateTime.now())) {
      _removedUntil.remove(uuid);
      return false;
    }
    return true;
  }

  /// A `user.removed` event for someone else.
  void onUserRemoved({
    required String outpostId,
    required String uuid,
    required OutpostBanInfo ban,
    String? removedByUuid,
  }) {
    if (outpostId != _callOutpostId) return;
    final name = displayNameOf(uuid: uuid);
    _removedUntil[uuid] = ban.expiresAt;
    if (amIHost && removedByUuid != myId) {
      Toast.info(
        title: ban.banKind == OutpostBanKind.ban ? 'Blocked' : 'Removed',
        message: ban.banKind == OutpostBanKind.ban
            ? '$name was blocked from this outpost'
            : '$name was removed from this outpost',
      );
    }
    _kickFromJitsi(uuid, immediately: removedByUuid == myId);
  }

  /// Called by the host who removed [uuid], before the server's event
  /// arrives.
  void _markRemovedByMe(String uuid, OutpostBanInfo ban) {
    _removedUntil[uuid] = ban.expiresAt;
    _kickFromJitsi(uuid, immediately: true);
  }

  void _onModerationPeerJoined(String? uuid) {
    if (uuid == null || !_isRemoved(uuid)) return;
    _kickFromJitsi(uuid, immediately: amIHost);
  }

  /// Hosts kick right away. Other moderators wait a moment and only kick if
  /// the person is still there, so a room full of moderators doesn't send a
  /// kick each.
  void _kickFromJitsi(String uuid, {required bool immediately}) {
    void kick() {
      if (isClosed || !_isRemoved(uuid)) return;
      if (localRole.value != 'moderator') return;
      final id = jitsiIdOf(uuid);
      if (id == null) return;
      jitsiMeet.sendPodiumCommand('kickParticipant', {'participantId': id});
    }

    if (immediately) {
      kick();
      return;
    }
    Future.delayed(
      Duration(milliseconds: 2000 + _moderationRandom.nextInt(4000)),
      kick,
    );
  }
}
