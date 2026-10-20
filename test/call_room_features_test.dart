import 'package:flutter_test/flutter_test.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/services/music_source_service.dart';

void main() {
  group('AudioRoute.listFrom', () {
    test('keeps known types in speaker, phone, wired, wireless order', () {
      final routes = AudioRoute.listFrom([
        {'type': 'BLUETOOTH', 'uid': 'bt-1', 'name': 'AirPods'},
        {'type': 'speaker', 'selected': true},
        {'type': 'HEADPHONES'},
        {'type': 'UNKNOWN'},
        'garbage',
        {'type': 'EARPIECE'},
      ]);
      expect(
        routes.map((r) => r.type),
        ['SPEAKER', 'EARPIECE', 'HEADPHONES', 'BLUETOOTH'],
      );
      expect(routes.first.selected, isTrue);
      expect(routes.last.label, 'AirPods');
      expect(routes[1].label, 'Phone');
    });

    test('returns nothing for a non-list payload', () {
      expect(AudioRoute.listFrom(null), isEmpty);
      expect(AudioRoute.listFrom({'type': 'SPEAKER'}), isEmpty);
    });

    test('a Bluetooth device without a name falls back to its type', () {
      final route = AudioRoute.listFrom([
        {'type': 'BLUETOOTH', 'name': '  '},
      ]).single;
      expect(route.label, 'Bluetooth');
    });
  });

  group('ConnectionQualityUpdate.tryParse', () {
    test('clamps and rounds values', () {
      final update = ConnectionQualityUpdate.tryParse({
        'local': 120,
        'remote': {'abc': 12.6, 'def': -5, 'bad': 'x'},
      })!;
      expect(update.local, 100);
      expect(update.remote, {'abc': 13, 'def': 0});
    });

    test('is null when there is nothing usable', () {
      expect(ConnectionQualityUpdate.tryParse({}), isNull);
      expect(ConnectionQualityUpdate.tryParse({'remote': 'x'}), isNull);
    });
  });

  group('conferenceErrorMessage', () {
    test('ignores intentional endings', () {
      expect(conferenceErrorMessage(null), isNull);
      expect(conferenceErrorMessage(''), isNull);
      expect(conferenceErrorMessage('conference.kicked'), isNull);
    });

    test('maps known Jitsi errors to specific messages', () {
      expect(conferenceErrorMessage('conference.max_users')!.title,
          'Outpost is full');
      expect(
        conferenceErrorMessage('conference.connectionError.accessDenied')!
            .title,
        'No access',
      );
      expect(conferenceErrorMessage('connection.droppedError')!.title,
          'Connection lost');
      expect(conferenceErrorMessage('conference.gracefulShutdown')!.title,
          'Server unavailable');
      expect(
          conferenceErrorMessage('conference.max_users')!.isGeneric, isFalse);
    });

    test('falls back to a generic message', () {
      final failure = conferenceErrorMessage('something.else')!;
      expect(failure.isGeneric, isTrue);
      expect(failure.title, "Couldn't connect");
    });
  });

  group('BreakoutState', () {
    final raw = {
      'supported': true,
      'currentRoomId': 'abc123',
      'isInBreakoutRoom': true,
      'rooms': [
        {
          'id': 'zeta@breakout.example.com',
          'jid': 'zeta@breakout.example.com',
          'name': 'Zeta',
          'isMainRoom': false,
          'participants': [],
        },
        {
          'id': 'abc123@breakout.example.com',
          'jid': 'abc123@breakout.example.com',
          'name': 'alpha',
          'isMainRoom': false,
          'participants': [
            {'participantId': 'p1', 'displayName': 'Ana'},
            {'participantId': ''},
            'garbage',
          ],
        },
        {
          'id': 'outpost@conference.example.com',
          'jid': 'outpost@conference.example.com',
          'name': 'Outpost',
          'isMainRoom': true,
        },
        {'id': '', 'jid': 'x'},
      ],
    };

    test('parses rooms with the main room first, then by name', () {
      final state = BreakoutState.tryParse(raw)!;
      expect(state.supported, isTrue);
      expect(state.isInBreakoutRoom, isTrue);
      expect(state.rooms.map((r) => r.name), ['Outpost', 'alpha', 'Zeta']);
      expect(state.mainRoom!.label, 'Main room');
      expect(state.breakoutRooms, hasLength(2));
      expect(state.rooms[1].participants.single.participantId, 'p1');
    });

    test('matches the current room by id or by its node', () {
      final state = BreakoutState.tryParse(raw)!;
      expect(state.currentRoom!.name, 'alpha');
      final byFullId = BreakoutState.tryParse({
        ...raw,
        'currentRoomId': 'zeta@breakout.example.com',
      })!;
      expect(byFullId.currentRoom!.name, 'Zeta');
      final none = BreakoutState.tryParse({...raw, 'currentRoomId': null})!;
      expect(none.currentRoom, isNull);
    });

    test('is in a breakout room when the current room is one', () {
      final unflagged = {...raw, 'isInBreakoutRoom': false};
      expect(BreakoutState.tryParse(unflagged)!.isInBreakoutRoom, isTrue);
      final inMain = BreakoutState.tryParse({
        ...unflagged,
        'currentRoomId': 'outpost',
      })!;
      expect(inMain.isInBreakoutRoom, isFalse);
      final unknown = BreakoutState.tryParse({
        ...unflagged,
        'currentRoomId': 'gone',
      })!;
      expect(unknown.isInBreakoutRoom, isFalse);
    });

    test('rejects a non-map payload', () {
      expect(BreakoutState.tryParse('x'), isNull);
      expect(BreakoutState.tryParse(null), isNull);
    });
  });

  group('MusicTrack.tryParse', () {
    test('requires an id, title and http(s) url', () {
      expect(
        MusicTrack.tryParse(
            {'id': 'a', 'url': 'https://x.com/a.mp3', 'title': 'A'}),
        isNotNull,
      );
      expect(
        MusicTrack.tryParse({'id': 'a', 'url': 'file:///a.mp3', 'title': 'A'}),
        isNull,
      );
      expect(MusicTrack.tryParse({'url': 'https://x.com/a.mp3', 'title': 'A'}),
          isNull);
      expect(MusicTrack.tryParse('x'), isNull);
    });

    test('clips long text and drops empty artists and bad durations', () {
      final track = MusicTrack.tryParse({
        'id': 'a',
        'url': 'https://x.com/a.mp3',
        'title': 'x' * 300,
        'artist': '   ',
        'durationMs': -4,
      })!;
      expect(track.title.length, MusicTrack.maxTitleLength);
      expect(track.artist, isNull);
      expect(track.durationMs, isNull);
    });

    test('round-trips through json', () {
      const track = MusicTrack(
        id: 'a',
        url: 'https://x.com/a.mp3',
        title: 'Song',
        artist: 'Band',
        durationMs: 1000,
      );
      final parsed = MusicTrack.tryParse(track.toJson())!;
      expect(parsed.title, 'Song');
      expect(parsed.artist, 'Band');
      expect(parsed.durationMs, 1000);
    });
  });

  group('MusicBroadcast.tryParse', () {
    const track = MusicTrack(id: 'a', url: 'https://x.com/a.mp3', title: 'A');

    test('round-trips a playing state', () {
      const state = MusicBroadcast(
        byUuid: 'host',
        seq: 4,
        track: track,
        playing: true,
        positionMs: 1500,
        volume: 0.6,
        loop: true,
      );
      final parsed = MusicBroadcast.tryParse(state.toJson())!;
      expect(parsed.byUuid, 'host');
      expect(parsed.seq, 4);
      expect(parsed.track!.id, 'a');
      expect(parsed.playing, isTrue);
      expect(parsed.positionMs, 1500);
      expect(parsed.volume, 0.6);
      expect(parsed.loop, isTrue);
    });

    test('a missing track means stopped and never playing', () {
      final parsed =
          MusicBroadcast.tryParse({'by': 'host', 'seq': 1, 'playing': true})!;
      expect(parsed.stopped, isTrue);
      expect(parsed.playing, isFalse);
    });

    test('rejects bad senders, sequence numbers and tracks', () {
      expect(MusicBroadcast.tryParse({'seq': 1}), isNull);
      expect(MusicBroadcast.tryParse({'by': 'host'}), isNull);
      expect(
        MusicBroadcast.tryParse({
          'by': 'host',
          'seq': 1,
          'track': {'id': 'a', 'url': 'ftp://x', 'title': 'A'},
        }),
        isNull,
      );
    });

    test('clamps volume and position', () {
      final parsed = MusicBroadcast.tryParse(
          {'by': 'host', 'seq': 1, 'vol': 3, 'pos': -10})!;
      expect(parsed.volume, 1.0);
      expect(parsed.positionMs, 0);
    });
  });

  group('MusicSync', () {
    test('accepts newer sequence numbers and settles ties by uuid', () {
      expect(
        MusicSync.accepts(seq: 2, byUuid: 'a', lastSeq: 1, lastByUuid: 'b'),
        isTrue,
      );
      expect(
        MusicSync.accepts(seq: 1, byUuid: 'b', lastSeq: 2, lastByUuid: 'a'),
        isFalse,
      );
      expect(
        MusicSync.accepts(seq: 3, byUuid: 'b', lastSeq: 3, lastByUuid: 'a'),
        isTrue,
      );
      expect(
        MusicSync.accepts(seq: 3, byUuid: 'a', lastSeq: 3, lastByUuid: 'b'),
        isFalse,
      );
      expect(
        MusicSync.accepts(seq: 0, byUuid: 'a', lastSeq: 0, lastByUuid: null),
        isTrue,
      );
    });

    test('expected position advances only while playing', () {
      expect(
        MusicSync.expectedPositionMs(
            positionMs: 1000, elapsedMs: 500, playing: false, loop: false),
        1000,
      );
      expect(
        MusicSync.expectedPositionMs(
            positionMs: 1000, elapsedMs: 500, playing: true, loop: false),
        1500,
      );
      expect(
        MusicSync.expectedPositionMs(
            positionMs: 1000, elapsedMs: -50, playing: true, loop: false),
        1000,
      );
    });

    test('expected position wraps when looping and stops at the end', () {
      expect(
        MusicSync.expectedPositionMs(
          positionMs: 9000,
          elapsedMs: 2000,
          playing: true,
          loop: true,
          durationMs: 10000,
        ),
        1000,
      );
      expect(
        MusicSync.expectedPositionMs(
          positionMs: 9000,
          elapsedMs: 2000,
          playing: true,
          loop: false,
          durationMs: 10000,
        ),
        10000,
      );
    });

    test('seeks only beyond the drift tolerance', () {
      expect(MusicSync.needsSeek(1000, 1000 + MusicSync.driftToleranceMs),
          isFalse);
      expect(
          MusicSync.needsSeek(1000, 1001 + MusicSync.driftToleranceMs), isTrue);
      expect(MusicSync.needsSeek(5000, 3000), isTrue);
    });

    test('volume combines room and local levels and ducks for the mic', () {
      expect(
        MusicSync.effectiveVolume(
            room: 0.8, local: 0.5, muted: false, micLive: false),
        closeTo(0.4, 1e-9),
      );
      expect(
        MusicSync.effectiveVolume(
            room: 0.8, local: 0.5, muted: false, micLive: true),
        closeTo(0.4 * MusicSync.duckWhileTalking, 1e-9),
      );
      expect(
        MusicSync.effectiveVolume(
            room: 1, local: 1, muted: true, micLive: false),
        0,
      );
      expect(
        MusicSync.effectiveVolume(
            room: 2, local: 2, muted: false, micLive: false),
        1,
      );
    });
  });

  group('MusicSourceService', () {
    test('builds a track from a direct link', () {
      final track = MusicSourceService.trackFromLink(
          ' https://cdn.example.com/music/My_Song%202.mp3 ')!;
      expect(track.url, 'https://cdn.example.com/music/My_Song%202.mp3');
      expect(track.title, 'My Song 2');
      expect(track.id, startsWith('link-'));
    });

    test('prefers a given title and rejects non-web links', () {
      expect(
        MusicSourceService.trackFromLink('https://x.com/a.mp3', title: 'Intro')!
            .title,
        'Intro',
      );
      expect(MusicSourceService.trackFromLink('not a url'), isNull);
      expect(MusicSourceService.trackFromLink('file:///a.mp3'), isNull);
      expect(MusicSourceService.trackFromLink('https://'), isNull);
    });

    test('titles fall back for bare paths', () {
      expect(MusicSourceService.titleFromPath('/'), 'Link');
      expect(MusicSourceService.titleFromPath('/a/.mp3'), '.mp3');
      expect(MusicSourceService.titleFromPath('track.flac'), 'track');
    });
  });
}
