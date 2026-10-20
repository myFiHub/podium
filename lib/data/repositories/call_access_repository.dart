import 'package:podium/providers/api/podium/models/breakout/breakout_access.dart';
import 'package:podium/providers/api/podium/models/users/blocked_user.dart';
import 'package:podium/providers/api/podium/podium.dart';

/// Blocking people and breakout room access rules. Everything here throws
/// [ApiFailure].
class CallAccessRepository {
  CallAccessRepository(this._api);

  final PodiumApi _api;

  Future<void> blockUser(String uuid, {required bool block}) =>
      _api.blockUser(uuid, block: block);

  Future<List<BlockedUserModel>> getBlockedUsers() => _api.getBlockedUsers();

  Future<BreakoutRoomsAccessList> getBreakoutRooms(String outpostUuid) =>
      _api.getBreakoutRooms(outpostUuid);

  Future<CreatedBreakoutRoom> createBreakoutRoom({
    required String outpostUuid,
    required String name,
    required BreakoutAccessType accessType,
    String? password,
    List<String> invitedUserUuids = const [],
  }) =>
      _api.createBreakoutRoom(
        outpostUuid: outpostUuid,
        name: name,
        accessType: accessType,
        password: password,
        invitedUserUuids: invitedUserUuids,
      );

  Future<BreakoutRoomAccess> updateBreakoutRoom({
    required String roomUuid,
    String? name,
    BreakoutAccessType? accessType,
    String? password,
    List<String>? invitedUserUuids,
  }) =>
      _api.updateBreakoutRoom(
        roomUuid: roomUuid,
        name: name,
        accessType: accessType,
        password: password,
        invitedUserUuids: invitedUserUuids,
      );

  Future<BreakoutRoomAccess> inviteToBreakoutRoom({
    required String roomUuid,
    required List<String> userUuids,
  }) =>
      _api.inviteToBreakoutRoom(roomUuid: roomUuid, userUuids: userUuids);

  Future<bool> deleteBreakoutRoom(String roomUuid) =>
      _api.deleteBreakoutRoom(roomUuid);

  Future<String> getBreakoutRoomPass({
    required String roomUuid,
    required String jid,
    String? password,
  }) =>
      _api.getBreakoutRoomPass(
        roomUuid: roomUuid,
        jid: jid,
        password: password,
      );
}
