import 'package:flutter_test/flutter_test.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/providers/api/api_failure.dart';
import 'package:podium/providers/api/podium/models/breakout/breakout_access.dart';
import 'package:podium/providers/api/podium/models/users/blocked_user.dart';

void main() {
  group('BreakoutState podiumAccess', () {
    Map<String, dynamic> room(String id, Object? access) => {
          'id': '$id@breakout.meet',
          'jid': '$id@breakout.meet',
          'name': id,
          'isMainRoom': false,
          'podiumAccess': access,
          'participants': const [],
        };

    test('keeps the policy uuid and treats anything else as open', () {
      final state = BreakoutState.tryParse({
        'supported': true,
        'rooms': [
          room('a', 'policy-1'),
          room('b', ''),
          room('c', null),
          room('d', 42),
        ],
      })!;
      final byName = {for (final r in state.rooms) r.name: r.podiumAccess};
      expect(byName, {'a': 'policy-1', 'b': null, 'c': null, 'd': null});
    });
  });

  group('BreakoutRoomAccess', () {
    test('parses the list response', () {
      final list = BreakoutRoomsAccessList.fromJson({
        'protection_available': true,
        'rooms': [
          {
            'uuid': 'r1',
            'outpost_uuid': 'o1',
            'name': 'Q&A',
            'access_type': 'invite_only',
            'created_by_uuid': 'host',
            'is_invited': true,
            'can_join': true,
            'requires_password': false,
            'invited_user_uuids': ['u1', 'u2'],
          },
          {
            'uuid': 'r2',
            'outpost_uuid': 'o1',
            'name': 'Ideas',
            'access_type': 'password',
            'can_join': true,
            'requires_password': true,
          },
        ],
      });
      expect(list.protectionAvailable, isTrue);
      final [invite, password] = list.rooms;
      expect(invite.accessType, BreakoutAccessType.inviteOnly);
      expect(invite.isProtected, isTrue);
      expect(invite.invitedUserUuids, ['u1', 'u2']);
      expect(password.accessType, BreakoutAccessType.password);
      expect(password.requiresPassword, isTrue);
      expect(password.invitedUserUuids, isNull);
    });

    test('unknown access types read as open', () {
      expect(BreakoutAccessType.parse('weird'), BreakoutAccessType.open);
      expect(BreakoutAccessType.parse(null), BreakoutAccessType.open);
      expect(BreakoutAccessType.inviteOnly.value, 'invite_only');
    });

    test('parses a created room with its token', () {
      final created = CreatedBreakoutRoom.fromJson({
        'room': {
          'uuid': 'r1',
          'outpost_uuid': 'o1',
          'name': 'Room 1',
          'access_type': 'open',
        },
        'create_token': 'jwt',
      });
      expect(created.room.isProtected, isFalse);
      expect(created.createToken, 'jwt');
    });
  });

  test('BlockedUserModel tolerates missing fields', () {
    final user = BlockedUserModel.fromJson({
      'uuid': 'u1',
      'name': 'Ann',
      'blocked_at': '2026-10-20T10:00:00Z',
    });
    expect(user.uuid, 'u1');
    expect(user.image, isNull);
    expect(user.blockedAt, DateTime.utc(2026, 10, 20, 10));
    expect(BlockedUserModel.fromJson({'uuid': 'u2'}).blockedAt, isNull);
  });

  test('breakoutAccessError explains server refusals', () {
    expect(
      breakoutAccessError(const ApiFailure('x', statusCode: 409)),
      'This outpost has too many rooms',
    );
    expect(
      breakoutAccessError(const ApiFailure('Name too long', statusCode: 400)),
      'Name too long',
    );
    expect(
      breakoutAccessError(const ApiFailure('offline')),
      'offline',
    );
  });
}
