import 'package:flutter_test/flutter_test.dart';
import 'package:podium/app/modules/global/utils/live_members.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';

LiveMember _member(String id, {bool stage = false, bool speaking = false}) {
  return LiveMember(
    uuid: id,
    address: id,
    aptos_address: id,
    can_speak: stage,
    is_speaking: speaking,
  );
}

void main() {
  test('speakers lead the stage, others keep their order', () {
    final a = _member('a', stage: true);
    final b = _member('b', stage: true, speaking: true);
    final c = _member('c');
    final d = _member('d', stage: true);
    final result =
        partitionLiveMembers([a, b, c, d], isOnStage: (m) => m.can_speak);
    expect(result.stage, [b, a, d]);
    expect(result.audience, [c]);
    expect(result.talking, 1);
  });

  test('a speaking audience member stays in the audience', () {
    final e = _member('e', speaking: true);
    final result = partitionLiveMembers([e], isOnStage: (m) => m.can_speak);
    expect(result.stage, isEmpty);
    expect(result.audience, [e]);
    expect(result.talking, 0);
  });

  test('sameMemberOrder compares identity and order', () {
    final a = _member('a');
    final b = _member('b');
    expect(sameMemberOrder([a, b], [a, b]), isTrue);
    expect(sameMemberOrder([a, b], [b, a]), isFalse);
    expect(sameMemberOrder([a], [_member('a')]), isFalse);
  });
}
