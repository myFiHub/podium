import 'package:flutter_test/flutter_test.dart';
import 'package:podium/app/modules/checkTicket/ticket_access.dart';
import 'package:podium/app/modules/createOutpost/outpost_types.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/utils/format_amount.dart';

const _me = 'me';
const _pass = BuyableTicketTypes.onlyPodiumPassHolders;
const _arena = BuyableTicketTypes.onlyArenaTicketHolders;

OutpostModel _outpost({
  String enter = FreeOutpostAccessTypes.public,
  String speak = FreeOutpostSpeakerTypes.everyone,
  String creator = 'creator',
  bool member = false,
  List<InviteModel>? invites,
  List<TicketToEnterModel>? toEnter,
  List<TicketToSpeakModel>? toSpeak,
}) {
  return OutpostModel(
    uuid: 'o',
    created_at: 0,
    creator_joined: false,
    creator_user_uuid: creator,
    creator_user_image: '',
    enter_type: enter,
    has_adult_content: false,
    image: '',
    invites: invites,
    is_archived: false,
    is_recordable: false,
    last_active_at: 0,
    members_count: 0,
    name: 'o',
    scheduled_for: 0,
    speak_type: speak,
    subject: '',
    tags: const [],
    tickets_to_enter: toEnter,
    tickets_to_speak: toSpeak,
    i_am_member: member,
    online_users_count: 0,
    reminder_offset_minutes: null,
  );
}

TicketSeller _seller({
  String? access,
  String? speak,
  bool boughtAccess = false,
  bool boughtSpeak = false,
}) {
  return TicketSeller(
    userInfo: UserModel(uuid: 's', address: '0x1'),
    address: '0x1',
    accessTicketType: access,
    speakTicketType: speak,
    boughtTicketToAccess: boughtAccess,
    boughtTicketToSpeak: boughtSpeak,
  );
}

void main() {
  group('TicketAccessEvaluator free access', () {
    test('public outpost lets anyone in and speak', () {
      final e = TicketAccessEvaluator(_outpost(), myId: _me);
      expect(e.canEnterWithoutTicket, isTrue);
      expect(e.canSpeakWithoutTicket, isTrue);
    });

    test('link-only outpost needs the link', () {
      final o = _outpost(enter: FreeOutpostAccessTypes.onlyLink);
      expect(TicketAccessEvaluator(o, myId: _me).canEnterWithoutTicket, false);
      expect(
        TicketAccessEvaluator(o, myId: _me, joiningByLink: true)
            .canEnterWithoutTicket,
        isTrue,
      );
    });

    test('invited speakers need can_speak on their invite', () {
      final o = _outpost(
        enter: FreeOutpostAccessTypes.invited_users,
        speak: FreeOutpostSpeakerTypes.invited_users,
        invites: [InviteModel(invitee_uuid: _me, can_speak: false)],
      );
      final e = TicketAccessEvaluator(o, myId: _me);
      expect(e.canEnterWithoutTicket, isTrue);
      expect(e.canSpeakWithoutTicket, isFalse);
    });

    test('the creator can always speak, members can always enter', () {
      final o = _outpost(enter: _pass, speak: _pass, creator: _me, member: true);
      final e = TicketAccessEvaluator(o, myId: _me);
      expect(e.canSpeakWithoutTicket, isTrue);
      expect(e.canEnterWithoutTicket, isTrue);
    });
  });

  group('TicketAccessEvaluator.evaluate', () {
    final gated = _outpost(enter: _pass, speak: _pass);

    test('nothing bought means no access', () {
      final a = TicketAccessEvaluator(gated, myId: _me)
          .evaluate([_seller(access: _pass, speak: _pass)]);
      expect(a.canEnter, isFalse);
      expect(a.canSpeak, isFalse);
    });

    test('any single enter ticket is enough', () {
      final a = TicketAccessEvaluator(gated, myId: _me).evaluate([
        _seller(access: _pass),
        _seller(access: _pass, boughtAccess: true),
      ]);
      expect(a.canEnter, isTrue);
      expect(a.canSpeak, isFalse);
    });

    test('a bought flag without the matching grant does not count', () {
      final a = TicketAccessEvaluator(gated, myId: _me)
          .evaluate([_seller(access: _pass, boughtSpeak: true)]);
      expect(a.canSpeak, isFalse);
    });

    test('canStillBuySpeak only while a speak ticket is unbought', () {
      final e = TicketAccessEvaluator(gated, myId: _me);
      expect(e.canStillBuySpeak([_seller(speak: _pass)]), isTrue);
      expect(
        e.canStillBuySpeak([_seller(speak: _pass, boughtSpeak: true)]),
        isFalse,
      );
    });
  });

  group('TicketSeller', () {
    test('same type for enter and speak is one ticket', () {
      final s = _seller(access: _pass, speak: _pass);
      expect(s.oneTicketForBoth, isTrue);
      expect(s.hasSeparateTickets, isFalse);
      s.boughtTicketToAccess = true;
      expect(s.alreadyBoughtRequiredTickets, isTrue);
    });

    test('different types need both bought', () {
      final s = _seller(access: _pass, speak: _arena, boughtAccess: true);
      expect(s.hasSeparateTickets, isTrue);
      expect(s.alreadyBoughtRequiredTickets, isFalse);
      s.boughtTicketToSpeak = true;
      expect(s.alreadyBoughtRequiredTickets, isTrue);
    });
  });

  test('TicketSellerRefs splits podium, arena and direct sellers', () {
    final refs = TicketSellerRefs.from([
      (userUuid: 'u1', address: '0xa'),
      (userUuid: 'arena:42', address: '0xb'),
      (userUuid: null, address: '0xc'),
      (userUuid: '', address: '0xd'),
    ]);
    expect(refs.podiumUserIds, ['u1']);
    expect(refs.arenaUserIds, ['42']);
    expect(refs.directAddresses, ['0xc', '0xd']);
    expect(refs.addressByUserId, {'u1': '0xa'});
    expect(refs.sellerIds, {'u1', '42', '0xc', '0xd'});
  });

  test('formatAmount trims trailing zeros', () {
    expect(formatAmount(4.0, 'MOVE'), '4 MOVE');
    expect(formatAmount(0.0125, 'AVAX'), '0.0125 AVAX');
    expect(formatAmount(1.23456, 'ETH'), '1.2346 ETH');
    expect(formatAmount(10, 'MOVE'), '10 MOVE');
  });
}
