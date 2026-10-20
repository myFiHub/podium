import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:podium/app/services/replay/replay_archive.dart';
import 'package:podium/app/services/replay/replay_format.dart';
import 'package:podium/app/services/replay/replay_timeline.dart';

ReplayMeta _meta({
  String id = '20261019-120000-abcd',
  int version = ReplayFormat.version,
  List<ReplayClip> clips = const [],
}) =>
    ReplayMeta(
      id: id,
      version: version,
      outpost: const ReplayOutpost(
        uuid: 'o1',
        name: 'Friday AMA',
        subject: 'Anything',
        creator: ReplayPerson(uuid: 'host', name: 'Host'),
      ),
      recordedBy: const ReplayPerson(uuid: 'me', name: 'Me'),
      startedAt: DateTime.utc(2026, 10, 19, 12),
      appVersion: '1.1.5',
      platform: 'ios',
      durationMs: 60000,
      clips: clips,
    );

Map<String, dynamic> _member(
  String uuid, {
  bool speaking = false,
  int remaining = 120,
}) =>
    ReplayMember(
      uuid: uuid,
      address: 'addr-$uuid',
      name: 'Name $uuid',
      canSpeak: true,
      isSpeaking: speaking,
      remainingTime: remaining,
    ).toJson();

ReplayEvent _ws(int t, String name, Map<String, dynamic> data) =>
    ReplayEvent(t, ReplayEventType.ws, {'name': name, 'data': data});

void main() {
  group('format', () {
    test('meta round-trips through JSON', () {
      final meta = _meta(clips: const [
        ReplayClip(
          index: 1,
          startMs: 1000,
          endMs: 5000,
          sharerUuid: 'a',
          sharerName: 'Ann',
          width: 1280,
          height: 720,
          encoded: true,
        ),
      ]);
      final decoded = ReplayMeta.decode(meta.encode())!;
      expect(decoded.id, meta.id);
      expect(decoded.outpost.name, 'Friday AMA');
      expect(decoded.startedAt, meta.startedAt);
      expect(decoded.clips.single.file, 'screen/clip_001.mp4');
      expect(decoded.clips.single.endMs, 5000);
      expect(decoded.isSupported, isTrue);
    });

    test('rejects other files and unsafe ids', () {
      expect(ReplayMeta.decode('{"format":"other"}'), isNull);
      expect(ReplayMeta.decode('not json'), isNull);
      final json = _meta().toJson()..['id'] = '../escape';
      expect(ReplayMeta.tryParse(json), isNull);
    });

    test('newer versions parse but are unsupported', () {
      final meta = ReplayMeta.decode(_meta(version: 99).encode())!;
      expect(meta.isSupported, isFalse);
    });

    test('event lines skip a line cut off by a crash and sort by time', () {
      final content = [
        const ReplayEvent(200, 'chat', {'text': 'b'}).toLine(),
        const ReplayEvent(100, 'chat', {'text': 'a'}).toLine(),
        const ReplayEvent(100, 'chat', {'text': 'a2'}).toLine(),
        '{"t":300,"type":"ch',
      ].join();
      final events = ReplayEvent.parseLines(content);
      expect(events.map((e) => e.data['text']), ['a', 'a2', 'b']);
    });

    test('state round-trips', () {
      const state = ReplayState(
        status: ReplayStatus.failed,
        clips: [
          ReplayClip(index: 2, startMs: 0, sharerUuid: 'a', sharerName: 'A'),
        ],
        error: 'boom',
      );
      final decoded = ReplayState.decode(state.encode())!;
      expect(decoded.status, ReplayStatus.failed);
      expect(decoded.error, 'boom');
      expect(decoded.clips.single.endMs, isNull);
    });
  });

  group('timeline', () {
    test('tracks speaking and counts talk time down while speaking', () {
      final timeline = ReplayTimeline(
        durationMs: 60000,
        clips: const [],
        events: [
          ReplayEvent(0, ReplayEventType.members, {
            'members': [_member('a'), _member('b')],
          }),
          _ws(1000, 'user.started_speaking', {'address': 'addr-a'}),
          _ws(11000, 'user.stopped_speaking', {'address': 'addr-a'}),
          _ws(20000, 'remaining_time.updated', {
            'address': 'addr-b',
            'remaining_time': 30,
          }),
        ],
      );
      final at6 = timeline.stateAt(6000);
      expect(at6.members.first.speaking, isTrue);
      expect(at6.members.first.remainingSeconds, 115);
      final at15 = timeline.stateAt(15000);
      expect(at15.members.first.speaking, isFalse);
      expect(at15.members.first.remainingSeconds, 110);
      expect(timeline.stateAt(25000).members.last.remainingSeconds, 30);
    });

    test('seeking back matches playing forward across checkpoints', () {
      final events = <ReplayEvent>[
        ReplayEvent(0, ReplayEventType.members, {
          'members': [_member('a')],
        }),
        for (var i = 1; i <= 900; i++)
          _ws(
            i * 10,
            i.isOdd ? 'user.started_speaking' : 'user.stopped_speaking',
            {'address': 'addr-a'},
          ),
      ];
      final timeline = ReplayTimeline(
        events: events,
        clips: const [],
        durationMs: 10000,
      );
      expect(timeline.stateAt(4505).members.single.speaking, isFalse);
      expect(timeline.stateAt(4515).members.single.speaking, isTrue);
      expect(timeline.stateAt(15).members.single.speaking, isTrue);
    });

    test('joins, leaves, hands, poll and dominant speaker', () {
      final timeline = ReplayTimeline(
        durationMs: 60000,
        clips: const [],
        events: [
          ReplayEvent(0, ReplayEventType.members, {
            'members': [_member('a')],
          }),
          _ws(1000, 'user.joined', {
            'address': 'addr-c',
            'uuid': 'c',
            'name': 'Cat',
          }),
          const ReplayEvent(2000, ReplayEventType.hands, {
            'uuids': ['c'],
          }),
          const ReplayEvent(2500, ReplayEventType.dominantSpeaker, {'uuid': 'a'}),
          const ReplayEvent(3000, ReplayEventType.poll, {
            'poll': {'id': 'p1', 'q': 'Yes?'},
          }),
          _ws(4000, 'user.left', {'address': 'addr-a'}),
        ],
      );
      final at3 = timeline.stateAt(3000);
      expect(at3.members.map((m) => m.member.uuid), ['a', 'c']);
      expect(at3.raisedHands, ['c']);
      expect(at3.dominantSpeakerUuid, 'a');
      expect(at3.poll?['id'], 'p1');
      expect(timeline.stateAt(5000).members.map((m) => m.member.uuid), ['c']);
      expect(timeline.stateAt(500).poll, isNull);
    });

    test('chat, moments and clips by time', () {
      final timeline = ReplayTimeline(
        durationMs: 60000,
        clips: const [
          ReplayClip(
            index: 1,
            startMs: 10000,
            endMs: 20000,
            sharerUuid: 'a',
            sharerName: 'A',
            encoded: true,
          ),
        ],
        events: [
          ReplayEvent(0, ReplayEventType.members, {
            'members': [_member('a'), _member('b')],
          }),
          const ReplayEvent(1000, ReplayEventType.chat, {
            'uuid': 'a',
            'name': 'Ann',
            'text': 'hi',
          }),
          const ReplayEvent(3000, ReplayEventType.reaction, {
            'uuid': 'b',
            'name': 'Bob',
            'emoji': '🔥',
          }),
          _ws(4000, 'user.cheered', {
            'address': 'addr-b',
            'react_to_user_address': 'addr-a',
            'amount': 5,
          }),
        ],
      );
      expect(timeline.chatUntil(999), isEmpty);
      expect(timeline.chatUntil(1000).single.text, 'hi');
      final moments = timeline.momentsBetween(2000, 4000);
      expect(moments.map((m) => m.emoji), ['🔥', '🎉']);
      expect(moments.last.label, 'Name b cheered Name a (5)');
      expect(timeline.momentsBetween(3000, 3500), isEmpty);
      expect(timeline.clipAt(9999), isNull);
      expect(timeline.clipAt(10000)?.index, 1);
      expect(timeline.clipAt(20000), isNull);
    });
  });

  group('archive', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('replay_test');
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    Future<String> writeReplay(ReplayMeta meta, {bool withAudio = true}) async {
      final dir = Directory(p.join(tmp.path, 'src'));
      await Directory(p.join(dir.path, 'screen')).create(recursive: true);
      await File(p.join(dir.path, ReplayFormat.meta)).writeAsString(meta.encode());
      await File(p.join(dir.path, ReplayFormat.events))
          .writeAsString(const ReplayEvent(0, 'chat', {'text': 'x'}).toLine());
      if (withAudio) {
        await File(p.join(dir.path, ReplayFormat.audio)).writeAsBytes([1, 2, 3]);
      }
      for (final clip in meta.clips) {
        await File(p.join(dir.path, clip.file)).writeAsBytes([4, 5]);
      }
      final out = p.join(tmp.path, 'out.podium');
      await ReplayArchive.pack(
        dir.path,
        [...ReplayFormat.exported, for (final c in meta.clips) c.file],
        out,
      );
      return out;
    }

    test('a packed replay extracts with its clips', () async {
      final meta = _meta(clips: const [
        ReplayClip(
          index: 1,
          startMs: 0,
          endMs: 100,
          sharerUuid: 'a',
          sharerName: 'A',
          encoded: true,
        ),
      ]);
      final path = await writeReplay(meta);
      final staging = p.join(tmp.path, 'staging');
      final extracted = await ReplayArchive.extract(path, staging);
      expect(extracted.id, meta.id);
      expect(
        await File(p.join(staging, 'screen/clip_001.mp4')).readAsBytes(),
        [4, 5],
      );
      expect(await File(p.join(staging, ReplayFormat.audio)).exists(), isTrue);
    });

    test('rejects a replay missing its audio', () async {
      final path = await writeReplay(_meta(), withAudio: false);
      expect(
        ReplayArchive.extract(path, p.join(tmp.path, 'staging')),
        throwsA(isA<ReplayImportException>()),
      );
    });

    test('rejects replays from a newer app', () async {
      final path = await writeReplay(_meta(version: 2));
      expect(
        ReplayArchive.extract(path, p.join(tmp.path, 'staging')),
        throwsA(
          isA<ReplayImportException>().having(
            (e) => e.message,
            'message',
            contains('Update Podium'),
          ),
        ),
      );
    });

    test('rejects files that are not replays', () async {
      final path = p.join(tmp.path, 'random.podium');
      await File(path).writeAsString('hello');
      expect(
        ReplayArchive.extract(path, p.join(tmp.path, 'staging')),
        throwsA(isA<ReplayImportException>()),
      );
    });

    test('never writes entries outside the replay folder', () async {
      final archive = Archive()
        ..add(ArchiveFile.bytes(
          ReplayFormat.meta,
          utf8.encode(_meta().encode()),
        ))
        ..add(ArchiveFile.bytes(ReplayFormat.audio, [1]))
        ..add(ArchiveFile.bytes(ReplayFormat.events, [10]))
        ..add(ArchiveFile.bytes('../evil.txt', [6]))
        ..add(ArchiveFile.bytes('screen/../../evil2.txt', [6]));
      final path = p.join(tmp.path, 'evil.podium');
      await File(path).writeAsBytes(ZipEncoder().encode(archive));
      final staging = p.join(tmp.path, 'deep', 'staging');
      await ReplayArchive.extract(path, staging);
      expect(await File(p.join(tmp.path, 'deep', 'evil.txt')).exists(), isFalse);
      expect(await File(p.join(tmp.path, 'evil2.txt')).exists(), isFalse);
      expect(await File(p.join(staging, ReplayFormat.audio)).exists(), isTrue);
    });
  });
}
