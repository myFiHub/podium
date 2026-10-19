import 'package:podium/app/modules/createOutpost/outpost_types.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/utils/constants.dart';

class OutpostAccesses {
  bool canEnter;
  bool canSpeak;
  String? accessPriceFullString;
  String? speakPriceFullString;
  OutpostAccesses({
    required this.canEnter,
    required this.canSpeak,
    this.accessPriceFullString,
    this.speakPriceFullString,
  });
}

/// Someone whose ticket grants entry and/or speaking in an outpost.
class TicketSeller {
  final UserModel userInfo;
  final String address;
  bool boughtTicketToSpeak;
  bool boughtTicketToAccess;
  bool buying;
  bool checking;
  final String? speakTicketType;
  final String? accessTicketType;
  String? accessPriceFullString;
  String? speakPriceFullString;

  TicketSeller({
    required this.userInfo,
    required this.address,
    this.boughtTicketToSpeak = false,
    this.boughtTicketToAccess = false,
    this.buying = false,
    this.checking = true,
    this.speakTicketType,
    this.accessTicketType,
    this.accessPriceFullString,
    this.speakPriceFullString,
  });

  bool get grantsAccess => accessTicketType != null;
  bool get grantsSpeak => speakTicketType != null;

  /// A single purchase covers both entering and speaking.
  bool get oneTicketForBoth =>
      grantsAccess && grantsSpeak && accessTicketType == speakTicketType;

  bool get hasSeparateTickets =>
      grantsAccess && grantsSpeak && accessTicketType != speakTicketType;

  bool get shouldBuyAccessTicket => grantsAccess && !boughtTicketToAccess;
  bool get shouldBuySpeakTicket => grantsSpeak && !boughtTicketToSpeak;

  bool get alreadyBoughtRequiredTickets => hasSeparateTickets
      ? boughtTicketToAccess && boughtTicketToSpeak
      : boughtTicketToAccess || boughtTicketToSpeak;
}

/// Ticket holders an outpost lists for one permission, split by how they are
/// looked up: Podium users, Stars Arena users, or bare wallet addresses.
class TicketSellerRefs {
  final List<String> podiumUserIds;
  final List<String> arenaUserIds;
  final List<String> directAddresses;

  /// Wallet address saved with each Podium user's ticket.
  final Map<String, String> addressByUserId;

  const TicketSellerRefs({
    required this.podiumUserIds,
    required this.arenaUserIds,
    required this.directAddresses,
    required this.addressByUserId,
  });

  factory TicketSellerRefs.from(
    Iterable<({String? userUuid, String address})> tickets,
  ) {
    final podium = <String>[];
    final arena = <String>[];
    final direct = <String>[];
    final addresses = <String, String>{};
    for (final ticket in tickets) {
      final id = ticket.userUuid ?? '';
      if (id.isEmpty) {
        direct.add(ticket.address);
      } else if (id.contains(arenaUserIdPrefix)) {
        arena.add(id.replaceAll(arenaUserIdPrefix, ''));
      } else {
        podium.add(id);
        addresses[id] = ticket.address;
      }
    }
    return TicketSellerRefs(
      podiumUserIds: podium,
      arenaUserIds: arena,
      directAddresses: direct,
      addressByUserId: addresses,
    );
  }

  factory TicketSellerRefs.toEnter(OutpostModel outpost) =>
      TicketSellerRefs.from((outpost.tickets_to_enter ?? [])
          .map((t) => (userUuid: t.user_uuid, address: t.address)));

  factory TicketSellerRefs.toSpeak(OutpostModel outpost) =>
      TicketSellerRefs.from((outpost.tickets_to_speak ?? [])
          .map((t) => (userUuid: t.user_uuid, address: t.address)));

  /// Ids the resolved sellers end up keyed by.
  Set<String> get sellerIds =>
      {...podiumUserIds, ...arenaUserIds, ...directAddresses};
}

/// Decides what the current user may do in an outpost, given the tickets they
/// hold. Pure, so it can be unit tested without GetX.
class TicketAccessEvaluator {
  const TicketAccessEvaluator(
    this.outpost, {
    required this.myId,
    this.joiningByLink = false,
  });

  final OutpostModel outpost;
  final String myId;
  final bool joiningByLink;

  bool get isAccessBuyable =>
      BuyableTicketTypes.all.contains(outpost.enter_type);
  bool get isSpeakBuyable =>
      BuyableTicketTypes.all.contains(outpost.speak_type);

  bool get isInvited =>
      outpost.invites?.any((e) => e.invitee_uuid == myId) ?? false;

  bool get canEnterWithoutTicket {
    if (outpost.i_am_member) return true;
    return switch (outpost.enter_type) {
      FreeOutpostAccessTypes.public => true,
      FreeOutpostAccessTypes.onlyLink => joiningByLink,
      FreeOutpostAccessTypes.invited_users => isInvited,
      _ => false,
    };
  }

  bool get canSpeakWithoutTicket {
    if (outpost.creator_user_uuid == myId) return true;
    return switch (outpost.speak_type) {
      FreeOutpostSpeakerTypes.everyone => true,
      FreeOutpostSpeakerTypes.invited_users =>
        outpost.invites?.any((e) => e.invitee_uuid == myId && e.can_speak) ??
            false,
      _ => false,
    };
  }

  /// Any one ticket of a kind is enough; nobody has to buy them all.
  OutpostAccesses evaluate(Iterable<TicketSeller> sellers) {
    final boughtEnter =
        sellers.any((s) => s.grantsAccess && s.boughtTicketToAccess);
    final boughtSpeak =
        sellers.any((s) => s.grantsSpeak && s.boughtTicketToSpeak);
    return OutpostAccesses(
      canEnter: canEnterWithoutTicket || (isAccessBuyable && boughtEnter),
      canSpeak: canSpeakWithoutTicket || (isSpeakBuyable && boughtSpeak),
    );
  }

  /// Whether buying one more ticket would unlock speaking.
  bool canStillBuySpeak(Iterable<TicketSeller> sellers) =>
      sellers.any((s) => s.shouldBuySpeakTicket);
}
