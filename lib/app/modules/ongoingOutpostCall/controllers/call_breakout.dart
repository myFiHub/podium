part of 'call_room_controller.dart';

class BreakoutParticipant {
  /// Jitsi endpoint id; stays the same when the participant switches rooms.
  final String participantId;
  final String displayName;
  const BreakoutParticipant({
    required this.participantId,
    required this.displayName,
  });
}

class BreakoutRoom {
  final String id;
  final String jid;
  final String name;
  final bool isMainRoom;
  final List<BreakoutParticipant> participants;

  /// Uuid of the Podium access rules the Jitsi server enforces for this room,
  /// or null for a room anyone can enter.
  final String? podiumAccess;
  const BreakoutRoom({
    required this.id,
    required this.jid,
    required this.name,
    required this.isMainRoom,
    required this.participants,
    this.podiumAccess,
  });

  String get label => isMainRoom ? 'Main room' : (name.isEmpty ? 'Room' : name);
}

/// Breakout rooms of the conference, as sent in a `breakoutRooms` event.
class BreakoutState {
  final bool supported;
  final String? currentRoomId;
  final bool isInBreakoutRoom;

  /// Main room first, then breakout rooms by name. Empty until a moderator
  /// creates the first breakout room.
  final List<BreakoutRoom> rooms;

  const BreakoutState({
    required this.supported,
    required this.currentRoomId,
    required this.isInBreakoutRoom,
    required this.rooms,
  });

  static const empty = BreakoutState(
    supported: false,
    currentRoomId: null,
    isInBreakoutRoom: false,
    rooms: [],
  );

  List<BreakoutRoom> get breakoutRooms =>
      rooms.where((r) => !r.isMainRoom).toList();

  BreakoutRoom? get mainRoom => rooms.firstOrNullWhere((r) => r.isMainRoom);

  /// The room this device is in. Room ids are bare room jids while the
  /// current room id is the room's name, so both are compared.
  BreakoutRoom? get currentRoom {
    final current = currentRoomId;
    if (current == null || current.isEmpty) return null;
    return rooms.firstOrNullWhere(
      (r) => r.id == current || r.id.split('@').first == current,
    );
  }

  /// Jitsi clears its room list while switching rooms and may not send it
  /// again. While in one of the breakout rooms known before, those rooms are
  /// kept, so the way back to the main room stays visible. In the main room an
  /// empty list is real: the server forgets the rooms if the main room empties.
  BreakoutState orKnownRooms(BreakoutState known) {
    if (rooms.isNotEmpty || !supported || known.rooms.isEmpty) return this;
    final kept = _derive(
      supported: supported,
      currentRoomId: currentRoomId,
      isInBreakoutRoom: isInBreakoutRoom,
      rooms: known.rooms,
    );
    final current = kept.currentRoom;
    return current == null || current.isMainRoom ? this : kept;
  }

  /// Jitsi learns a room is a breakout room only after joining it, so being
  /// in a known breakout room counts too.
  static BreakoutState _derive({
    required bool supported,
    required String? currentRoomId,
    required bool isInBreakoutRoom,
    required List<BreakoutRoom> rooms,
  }) {
    final state = BreakoutState(
      supported: supported,
      currentRoomId: currentRoomId,
      isInBreakoutRoom: isInBreakoutRoom,
      rooms: rooms,
    );
    final current = state.currentRoom;
    if (isInBreakoutRoom || current == null || current.isMainRoom) {
      return state;
    }
    return BreakoutState(
      supported: supported,
      currentRoomId: currentRoomId,
      isInBreakoutRoom: true,
      rooms: rooms,
    );
  }

  static BreakoutState? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final rooms = <BreakoutRoom>[];
    final rawRooms = raw['rooms'];
    if (rawRooms is List) {
      for (final item in rawRooms) {
        if (item is! Map) continue;
        final id = item['id']?.toString();
        final jid = item['jid']?.toString();
        if (id == null || id.isEmpty || jid == null) continue;
        final participants = <BreakoutParticipant>[];
        final rawParticipants = item['participants'];
        if (rawParticipants is List) {
          for (final p in rawParticipants) {
            if (p is! Map) continue;
            final pid = p['participantId']?.toString();
            if (pid == null || pid.isEmpty) continue;
            participants.add(BreakoutParticipant(
              participantId: pid,
              displayName: p['displayName']?.toString() ?? '',
            ));
          }
        }
        rooms.add(BreakoutRoom(
          id: id,
          jid: jid,
          name: item['name']?.toString() ?? '',
          isMainRoom: item['isMainRoom'] == true,
          participants: participants,
          podiumAccess: switch (item['podiumAccess']) {
            final String policy when policy.isNotEmpty => policy,
            _ => null,
          },
        ));
      }
    }
    rooms.sort((a, b) {
      if (a.isMainRoom != b.isMainRoom) return a.isMainRoom ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return _derive(
      supported: raw['supported'] == true,
      currentRoomId: raw['currentRoomId']?.toString(),
      isInBreakoutRoom: raw['isInBreakoutRoom'] == true,
      rooms: rooms,
    );
  }
}

/// Jitsi breakout rooms. Moving between rooms leaves one conference and
/// joins another on the same connection, so chat, polls and peers are per
/// room while the Podium outpost session stays the same.
///
/// Rooms created with Podium access rules are enforced by the Jitsi server:
/// entering one takes a short-lived pass from the Podium server, bound to this
/// connection's jid, as the room password.
mixin _CallBreakout on GetxController {
  String? jitsiIdOf(String uuid);
  String? knownUuidOf(String jitsiId);
  bool isHostUuid(String? uuid);
  bool get canModerate;
  bool get amIHost;
  String? get _callOutpostId;
  void _onRoomSwitched(BreakoutRoom? room);

  final breakout = BreakoutState.empty.obs;
  String? _lastRoomId;

  /// Podium access rules by uuid, as the server shows them to this user.
  final breakoutAccess = <String, BreakoutRoomAccess>{}.obs;
  final _serverProtection = false.obs;
  final _jitsiProtection = false.obs;

  /// Set once the Jitsi server made an open room out of a protected one.
  final _jitsiServerIgnoresAccess = false.obs;
  String? _localJid;
  final _pendingCreates = <String, _PendingBreakoutCreate>{};

  /// Policies seen in Jitsi that were looked up once already.
  final _askedPolicies = <String>{};
  Future<void>? _accessLoading;
  bool _accessReloadQueued = false;

  CallAccessRepository get _accessRepo => Get.find<CallAccessRepository>();

  /// Both the Podium server and this Jitsi build can protect rooms.
  bool get canProtectRooms =>
      _serverProtection.value &&
      _jitsiProtection.value &&
      !_jitsiServerIgnoresAccess.value;

  BreakoutRoomAccess? accessOf(BreakoutRoom room) {
    final policy = room.podiumAccess;
    return policy == null ? null : breakoutAccess[policy];
  }

  /// From the Jitsi `state` snapshot, sent again after every room switch.
  void _onBreakoutCapabilities(Map<String, dynamic> data) {
    if (data['podiumBreakoutAccess'] == true) _jitsiProtection.value = true;
    final jid = data['localJid'];
    if (jid is String && jid.isNotEmpty) _localJid = jid.toLowerCase();
  }

  Future<void> refreshBreakoutAccess() async {
    final outpostId = _callOutpostId;
    if (outpostId == null) return;
    final loading = _accessLoading;
    if (loading != null) {
      _accessReloadQueued = true;
      return loading;
    }
    _accessLoading = _loadBreakoutAccess(outpostId);
    try {
      await _accessLoading;
    } finally {
      _accessLoading = null;
    }
    if (_accessReloadQueued && !isClosed) {
      _accessReloadQueued = false;
      await refreshBreakoutAccess();
    }
  }

  Future<void> _loadBreakoutAccess(String outpostId) async {
    try {
      final list = await _accessRepo.getBreakoutRooms(outpostId);
      if (isClosed || outpostId != _callOutpostId) return;
      _serverProtection.value = list.protectionAvailable;
      breakoutAccess.assignAll({for (final r in list.rooms) r.uuid: r});
    } on ApiFailure catch (e) {
      l.w('cannot load breakout room access: $e');
      if (e.statusCode == 404) _serverProtection.value = false;
    }
  }

  /// A `breakout_rooms.updated` event: a host changed some room's rules.
  void _onBreakoutAccessEvent(Map<String, dynamic> data) {
    final outpostId = data['outpost_uuid']?.toString();
    if (outpostId != null && outpostId != _callOutpostId) return;
    refreshBreakoutAccess();
  }

  bool get breakoutSupported => breakout.value.supported;

  bool get inBreakoutRoom => breakout.value.isInBreakoutRoom;

  BreakoutRoom? get currentBreakoutRoom => breakout.value.currentRoom;

  void _onBreakoutRooms(dynamic raw) {
    var next = BreakoutState.tryParse(raw);
    if (next == null) return;
    next = next.orKnownRooms(breakout.value);
    breakout.value = next;
    _checkPendingCreates(next);
    final unknown = next.rooms
        .map((r) => r.podiumAccess)
        .whereNotNull()
        .where((p) => !breakoutAccess.containsKey(p) && _askedPolicies.add(p))
        .toList();
    if (unknown.isNotEmpty) refreshBreakoutAccess();
    final roomId = next.currentRoomId;
    if (roomId == null || roomId.isEmpty) return;
    final previous = _lastRoomId;
    _lastRoomId = roomId;
    if (previous != null && previous != roomId) {
      _onRoomSwitched(next.currentRoom);
    }
  }

  /// Creates a room. When rooms can be protected, every room gets Podium
  /// access rules, so hosts can restrict it later. Returns an error to show,
  /// or null.
  Future<String?> createBreakoutRoom({
    String? name,
    BreakoutAccessType access = BreakoutAccessType.open,
    String? password,
    List<String> invitedUuids = const [],
  }) async {
    if (!canModerate) return 'Only hosts can create rooms';
    var trimmed = name?.trim() ?? '';
    if (!canProtectRooms) {
      if (access != BreakoutAccessType.open) {
        return 'Protected rooms need an app and server update';
      }
      jitsiMeet.sendPodiumCommand('createBreakoutRoom', {
        if (trimmed.isNotEmpty) 'name': trimmed,
      });
      return null;
    }
    final outpostId = _callOutpostId;
    if (outpostId == null) return 'You are not in an outpost';
    if (trimmed.isEmpty) trimmed = _nextRoomName();
    final CreatedBreakoutRoom created;
    try {
      created = await _accessRepo.createBreakoutRoom(
        outpostUuid: outpostId,
        name: trimmed,
        accessType: access,
        password: access == BreakoutAccessType.password ? password : null,
        invitedUserUuids: invitedUuids,
      );
    } on ApiFailure catch (e) {
      return breakoutAccessError(e);
    }
    if (isClosed) return null;
    final policy = created.room.uuid;
    breakoutAccess[policy] = created.room;
    _pendingCreates[policy] = _PendingBreakoutCreate(
      name: trimmed,
      restricted: access != BreakoutAccessType.open,
      knownRoomIds: breakout.value.rooms.map((r) => r.id).toSet(),
      timer: Timer(
        const Duration(seconds: 12),
        () => _abandonCreate(
          policy,
          message: "The room wasn't created. Try again in a moment.",
        ),
      ),
    );
    jitsiMeet.sendPodiumCommand('createBreakoutRoom', {
      'name': trimmed,
      'podiumAccess': created.createToken,
    });
    return null;
  }

  String _nextRoomName() {
    final taken =
        breakout.value.breakoutRooms.map((r) => r.name.toLowerCase()).toSet();
    var n = breakout.value.breakoutRooms.length + 1;
    while (taken.contains('room $n')) {
      n++;
    }
    return 'Room $n';
  }

  /// A Jitsi server without Podium support ignores the rules and makes an
  /// open room; one with it refuses a bad token and makes none. Neither may
  /// leave behind rules nobody enforces.
  void _checkPendingCreates(BreakoutState state) {
    for (final entry in _pendingCreates.entries.toList()) {
      final pending = entry.value;
      if (state.rooms.any((r) => r.podiumAccess == entry.key)) {
        pending.timer.cancel();
        _pendingCreates.remove(entry.key);
        continue;
      }
      final unprotected = state.breakoutRooms.firstOrNullWhere((r) =>
          r.podiumAccess == null &&
          r.name == pending.name &&
          !pending.knownRoomIds.contains(r.id));
      if (unprotected != null) {
        _jitsiServerIgnoresAccess.value = true;
        if (!pending.restricted) {
          _abandonCreate(entry.key);
          continue;
        }
        jitsiMeet
            .sendPodiumCommand('removeBreakoutRoom', {'jid': unprotected.jid});
        _abandonCreate(
          entry.key,
          message: "This call's server can't protect rooms yet, so the room "
              'was not kept.',
        );
      }
    }
  }

  /// Drops [policy]'s rules, telling the host [message] if given.
  void _abandonCreate(String policy, {String? message}) {
    _pendingCreates.remove(policy)?.timer.cancel();
    breakoutAccess.remove(policy);
    _accessRepo.deleteBreakoutRoom(policy).catchError((Object e) {
      l.w('cannot delete breakout access $policy: $e');
      return false;
    });
    if (message != null && !isClosed) {
      Toast.error(title: 'Room not created', message: message);
    }
  }

  void removeBreakoutRoom(BreakoutRoom room) {
    if (!canModerate || room.isMainRoom) return;
    jitsiMeet.sendPodiumCommand('removeBreakoutRoom', {'jid': room.jid});
    final policy = room.podiumAccess;
    if (policy == null) return;
    breakoutAccess.remove(policy);
    _accessRepo.deleteBreakoutRoom(policy).catchError((Object e) {
      l.w('cannot delete breakout access $policy: $e');
      return false;
    });
  }

  /// Changes who may enter [room]. A null [password] keeps the current one.
  /// When the room gets stricter, people no longer allowed are sent back to
  /// the main room. Returns an error to show, or null.
  Future<String?> updateBreakoutAccess(
    BreakoutRoom room, {
    required String name,
    required BreakoutAccessType access,
    String? password,
    required List<String> invitedUuids,
  }) async {
    final policy = room.podiumAccess;
    if (policy == null) return "This room's access can't be changed";
    if (!amIHost) return 'Only hosts can change room access';
    final before = breakoutAccess[policy];
    final BreakoutRoomAccess updated;
    try {
      updated = await _accessRepo.updateBreakoutRoom(
        roomUuid: policy,
        name: name.trim().isEmpty ? null : name.trim(),
        accessType: access,
        password: access == BreakoutAccessType.password ? password : null,
        invitedUserUuids: invitedUuids,
      );
    } on ApiFailure catch (e) {
      return breakoutAccessError(e);
    }
    if (isClosed) return null;
    breakoutAccess[policy] = updated;
    final stricter = switch (access) {
      BreakoutAccessType.open => false,
      BreakoutAccessType.inviteOnly => true,
      BreakoutAccessType.password =>
        password != null || before?.accessType != BreakoutAccessType.password,
    };
    if (stricter) _sendOutUnpermitted(room, updated);
    return null;
  }

  void _sendOutUnpermitted(BreakoutRoom room, BreakoutRoomAccess access) {
    final latest =
        breakout.value.rooms.firstOrNullWhere((r) => r.id == room.id) ?? room;
    final main = breakout.value.mainRoom;
    if (main == null || !canModerate) return;
    final invited = access.invitedUserUuids?.toSet() ?? const <String>{};
    for (final participant in latest.participants) {
      final uuid = knownUuidOf(participant.participantId);
      if (uuid != null && (isHostUuid(uuid) || invited.contains(uuid))) {
        continue;
      }
      _sendToRoom(participant.participantId, main);
    }
  }

  /// Sends everyone in [room] back to the main room.
  void closeBreakoutRoom(BreakoutRoom room) {
    if (!canModerate || room.isMainRoom) return;
    jitsiMeet.sendPodiumCommand('closeBreakoutRoom', {'roomId': room.id});
  }

  void closeAllBreakoutRooms() {
    for (final room in breakout.value.breakoutRooms) {
      if (room.participants.isNotEmpty) closeBreakoutRoom(room);
    }
  }

  /// A host sending someone into a restricted room invites them first, so
  /// their pass request is accepted when Jitsi moves them.
  Future<void> sendParticipantToRoom(
    String participantId,
    BreakoutRoom room,
  ) async {
    if (!canModerate) return;
    final policy = room.podiumAccess;
    final uuid = knownUuidOf(participantId);
    if (policy != null && uuid != null && !_mayEnter(uuid, policy)) {
      try {
        final updated = await _accessRepo
            .inviteToBreakoutRoom(roomUuid: policy, userUuids: [uuid]);
        if (isClosed) return;
        breakoutAccess[policy] = updated;
      } on ApiFailure catch (e) {
        Toast.error(title: 'Could not move', message: breakoutAccessError(e));
        return;
      }
    }
    _sendToRoom(participantId, room);
  }

  bool _mayEnter(String uuid, String policy) {
    if (isHostUuid(uuid)) return true;
    final access = breakoutAccess[policy];
    if (access == null) return false;
    return access.accessType == BreakoutAccessType.open ||
        (access.invitedUserUuids?.contains(uuid) ?? false);
  }

  void _sendToRoom(String participantId, BreakoutRoom room) {
    jitsiMeet.sendPodiumCommand('sendParticipantToRoom', {
      'participantId': participantId,
      'roomId': room.id,
    });
  }

  /// Spreads the main room over the breakout rooms. With restricted rooms,
  /// invited people go to their room and everyone else to open rooms; people
  /// with nowhere to go stay in the main room.
  void autoAssignBreakoutRooms() {
    if (!canModerate) return;
    final state = breakout.value;
    final rooms = state.breakoutRooms;
    final main = state.mainRoom;
    if (rooms.isEmpty) return;
    if (main == null || rooms.every((r) => r.podiumAccess == null)) {
      jitsiMeet.sendPodiumCommand('autoAssignBreakoutRooms');
      return;
    }
    final load = {for (final r in rooms) r.id: r.participants.length};
    BreakoutRoom? leastFull(Iterable<BreakoutRoom> options) =>
        options.minBy((r) => load[r.id] ?? 0);
    final open = rooms
        .where((r) =>
            r.podiumAccess == null ||
            accessOf(r)?.accessType == BreakoutAccessType.open)
        .toList();
    final me = jitsiIdOf(myId);
    var stayed = 0;
    for (final participant in main.participants) {
      if (participant.participantId == me) continue;
      final uuid = knownUuidOf(participant.participantId);
      if (isHostUuid(uuid)) continue;
      final invitedTo = uuid == null
          ? const <BreakoutRoom>[]
          : rooms.where((r) =>
              r.podiumAccess != null &&
              (accessOf(r)?.invitedUserUuids?.contains(uuid) ?? false));
      final target = leastFull(invitedTo) ?? leastFull(open);
      if (target == null) {
        stayed++;
        continue;
      }
      load[target.id] = (load[target.id] ?? 0) + 1;
      _sendToRoom(participant.participantId, target);
    }
    if (stayed > 0) {
      Toast.info(
        title: 'Some people stayed',
        message: stayed == 1
            ? "1 person isn't invited to any room and there is no open room"
            : "$stayed people aren't invited to any room and there is no "
                'open room',
      );
    }
  }

  /// Joins [room], or the main room when null. Rooms with Podium access
  /// rules ask the server for a pass first.
  Future<BreakoutJoinResult> joinBreakoutRoom(
    BreakoutRoom? room, {
    String? password,
  }) async {
    if (room != null && room.id == currentBreakoutRoom?.id) {
      return BreakoutJoinResult.moved;
    }
    final policy = room?.podiumAccess;
    if (room == null || room.isMainRoom || policy == null) {
      jitsiMeet.sendPodiumCommand('moveToRoom', {
        if (room != null && !room.isMainRoom) 'roomId': room.id,
      });
      return BreakoutJoinResult.moved;
    }
    final jid = _localJid;
    if (!_jitsiProtection.value || jid == null) {
      return BreakoutJoinResult.unsupported;
    }
    try {
      final pass = await _accessRepo.getBreakoutRoomPass(
        roomUuid: policy,
        jid: jid,
        password: password,
      );
      if (isClosed) return BreakoutJoinResult.failed;
      jitsiMeet.sendPodiumCommand('moveToRoom', {
        'roomId': room.id,
        'password': pass,
      });
      return BreakoutJoinResult.moved;
    } on ApiFailure catch (e) {
      l.w('breakout pass refused: $e');
      return switch (e.statusCode) {
        428 => BreakoutJoinResult.passwordRequired,
        401 => BreakoutJoinResult.wrongPassword,
        403 => BreakoutJoinResult.notInvited,
        429 => BreakoutJoinResult.tooManyAttempts,
        404 => BreakoutJoinResult.gone,
        503 => BreakoutJoinResult.unsupported,
        _ => BreakoutJoinResult.failed,
      };
    }
  }

  void moveToRoom([BreakoutRoom? room]) => joinBreakoutRoom(room);

  BreakoutRoom? _roomById(String? roomId) {
    if (roomId == null || roomId.isEmpty) return null;
    return breakout.value.rooms.firstOrNullWhere(
      (r) =>
          r.id == roomId ||
          r.jid == roomId ||
          r.id.split('@').first == roomId,
    );
  }

  /// Jitsi itself asked to enter a protected room (a host moved us, or auto
  /// assign), which needs a pass from the Podium server.
  void _onProtectedMoveRequested(Map<String, dynamic> data) {
    final room = _roomById(data['roomId']?.toString());
    if (room == null) {
      l.w('protected move to unknown room ${data['roomId']}');
      return;
    }
    enterBreakoutRoom(room, movedByHost: true);
  }

  void _onBreakoutJoinDenied(Map<String, dynamic> data) {
    final room = _roomById(data['roomId']?.toString());
    Toast.error(
      title: "Couldn't join ${room?.label ?? 'the room'}",
      message: 'The room turned the pass down, so you are back in the main '
          'room. Ask a host to check your access.',
    );
    refreshBreakoutAccess();
  }

  void _disposeBreakout() {
    for (final pending in _pendingCreates.values) {
      pending.timer.cancel();
    }
    _pendingCreates.clear();
  }
}

enum BreakoutJoinResult {
  moved,
  passwordRequired,
  wrongPassword,
  notInvited,
  tooManyAttempts,
  gone,
  unsupported,
  failed,
}

class _PendingBreakoutCreate {
  final String name;

  /// Anything stricter than open; such a room may not exist unprotected.
  final bool restricted;
  final Set<String> knownRoomIds;
  final Timer timer;
  const _PendingBreakoutCreate({
    required this.name,
    required this.restricted,
    required this.knownRoomIds,
    required this.timer,
  });
}

/// Server refusals for breakout access, worded for people.
String breakoutAccessError(ApiFailure e) => switch (e.statusCode) {
      400 => e.message,
      401 => 'Wrong password',
      403 => 'Only hosts can do that',
      404 => 'That room is gone',
      409 => 'This outpost has too many rooms',
      422 => 'Everyone invited must be in the outpost',
      429 => 'Too many attempts. Wait a few minutes.',
      503 => 'Protected rooms are not set up on this server',
      _ => e.message,
    };
