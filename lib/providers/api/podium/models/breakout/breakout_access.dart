/// Who may enter a breakout room. Hosts and invited people always can.
enum BreakoutAccessType {
  open('open'),
  password('password'),
  inviteOnly('invite_only');

  const BreakoutAccessType(this.value);

  final String value;

  static BreakoutAccessType parse(String? value) =>
      values.firstWhere((t) => t.value == value, orElse: () => open);
}

/// The server's access rules for one breakout room, as seen by the viewer.
class BreakoutRoomAccess {
  final String uuid;
  final String outpostUuid;
  final String name;
  final BreakoutAccessType accessType;
  final String? createdByUuid;
  final bool isInvited;
  final bool canJoin;
  final bool requiresPassword;

  /// Only sent to hosts.
  final List<String>? invitedUserUuids;

  const BreakoutRoomAccess({
    required this.uuid,
    required this.outpostUuid,
    required this.name,
    required this.accessType,
    this.createdByUuid,
    this.isInvited = false,
    this.canJoin = true,
    this.requiresPassword = false,
    this.invitedUserUuids,
  });

  bool get isProtected => accessType != BreakoutAccessType.open;

  factory BreakoutRoomAccess.fromJson(Map<String, dynamic> json) =>
      BreakoutRoomAccess(
        uuid: json['uuid'] as String,
        outpostUuid: json['outpost_uuid'] as String,
        name: json['name'] as String? ?? '',
        accessType: BreakoutAccessType.parse(json['access_type'] as String?),
        createdByUuid: json['created_by_uuid'] as String?,
        isInvited: json['is_invited'] as bool? ?? false,
        canJoin: json['can_join'] as bool? ?? true,
        requiresPassword: json['requires_password'] as bool? ?? false,
        invitedUserUuids: (json['invited_user_uuids'] as List?)
            ?.map((e) => e as String)
            .toList(),
      );
}

class BreakoutRoomsAccessList {
  /// False when the server can't sign passes, so only open rooms work.
  final bool protectionAvailable;
  final List<BreakoutRoomAccess> rooms;

  const BreakoutRoomsAccessList({
    required this.protectionAvailable,
    required this.rooms,
  });

  factory BreakoutRoomsAccessList.fromJson(Map<String, dynamic> json) =>
      BreakoutRoomsAccessList(
        protectionAvailable: json['protection_available'] as bool? ?? false,
        rooms: (json['rooms'] as List? ?? [])
            .map((e) =>
                BreakoutRoomAccess.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

/// A freshly created room, with the token Jitsi needs to tie it to its rules.
class CreatedBreakoutRoom {
  final BreakoutRoomAccess room;
  final String createToken;

  const CreatedBreakoutRoom({required this.room, required this.createToken});

  factory CreatedBreakoutRoom.fromJson(Map<String, dynamic> json) =>
      CreatedBreakoutRoom(
        room: BreakoutRoomAccess.fromJson(
          Map<String, dynamic>.from(json['room']),
        ),
        createToken: json['create_token'] as String,
      );
}
