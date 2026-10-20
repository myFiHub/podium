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
  const BreakoutRoom({
    required this.id,
    required this.jid,
    required this.name,
    required this.isMainRoom,
    required this.participants,
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
        ));
      }
    }
    rooms.sort((a, b) {
      if (a.isMainRoom != b.isMainRoom) return a.isMainRoom ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return BreakoutState(
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
mixin _CallBreakout on GetxController {
  String? jitsiIdOf(String uuid);
  bool get canModerate;
  void _onRoomSwitched(BreakoutRoom? room);

  final breakout = BreakoutState.empty.obs;
  String? _lastRoomId;

  bool get breakoutSupported => breakout.value.supported;

  bool get inBreakoutRoom => breakout.value.isInBreakoutRoom;

  BreakoutRoom? get currentBreakoutRoom => breakout.value.currentRoom;

  void _onBreakoutRooms(dynamic raw) {
    final next = BreakoutState.tryParse(raw);
    if (next == null) return;
    breakout.value = next;
    final roomId = next.currentRoomId;
    if (roomId == null || roomId.isEmpty) return;
    final previous = _lastRoomId;
    _lastRoomId = roomId;
    if (previous != null && previous != roomId) {
      _onRoomSwitched(next.currentRoom);
    }
  }

  void createBreakoutRoom([String? name]) {
    if (!canModerate) return;
    final trimmed = name?.trim() ?? '';
    jitsiMeet.sendPodiumCommand('createBreakoutRoom', {
      if (trimmed.isNotEmpty) 'name': trimmed,
    });
  }

  void removeBreakoutRoom(BreakoutRoom room) {
    if (!canModerate || room.isMainRoom) return;
    jitsiMeet.sendPodiumCommand('removeBreakoutRoom', {'jid': room.jid});
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

  void sendParticipantToRoom(String participantId, BreakoutRoom room) {
    if (!canModerate) return;
    jitsiMeet.sendPodiumCommand('sendParticipantToRoom', {
      'participantId': participantId,
      'roomId': room.id,
    });
  }

  void autoAssignBreakoutRooms() {
    if (!canModerate || breakout.value.breakoutRooms.isEmpty) return;
    jitsiMeet.sendPodiumCommand('autoAssignBreakoutRooms');
  }

  /// Joins [room], or the main room when null.
  void moveToRoom([BreakoutRoom? room]) {
    if (room != null && room.id == currentBreakoutRoom?.id) return;
    jitsiMeet.sendPodiumCommand('moveToRoom', {
      if (room != null && !room.isMainRoom) 'roomId': room.id,
    });
  }
}
