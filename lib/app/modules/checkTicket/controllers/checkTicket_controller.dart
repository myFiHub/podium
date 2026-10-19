import 'package:get/get.dart';
import 'package:podium/app/modules/checkTicket/ticket_access.dart';
import 'package:podium/app/modules/createOutpost/outpost_types.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/aptosClient.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/arena/models/user.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/format_amount.dart';
import 'package:podium/utils/logger.dart';

export 'package:podium/app/modules/checkTicket/ticket_access.dart';

typedef _Quote = ({bool owned, String? price});

class CheckticketController extends GetxController {
  final _userRepository = Get.find<UserRepository>();

  /// Keyed by seller id: Podium uuid, Stars Arena id, or wallet address.
  final allUsersToBuyTicketFrom = Rx<Map<String, TicketSeller>>({});

  final loadingUsers = false.obs;
  final outpost = Rxn<OutpostModel>();
  bool joiningByLink = false;

  TicketAccessEvaluator get _evaluator => TicketAccessEvaluator(
        outpost.value!,
        myId: myId,
        joiningByLink: joiningByLink,
      );

  bool get isAccessBuyableByTicket => _evaluator.isAccessBuyable;
  bool get isSpeakBuyableByTicket => _evaluator.isSpeakBuyable;
  bool get canSpeakWithoutATicket => _evaluator.canSpeakWithoutTicket;
  bool get canEnterWithoutTicket => _evaluator.canEnterWithoutTicket;

  OutpostAccesses checkAccess() =>
      _evaluator.evaluate(allUsersToBuyTicketFrom.value.values);

  bool get canStillBuySpeak =>
      _evaluator.canStillBuySpeak(allUsersToBuyTicketFrom.value.values);

  Future<OutpostAccesses> checkTickets() async {
    final outpost = this.outpost.value!;
    allUsersToBuyTicketFrom.value = {};
    loadingUsers.value = true;
    final toEnter = TicketSellerRefs.toEnter(outpost);
    final toSpeak = TicketSellerRefs.toSpeak(outpost);
    final users = await _resolveSellers(outpost, toEnter, toSpeak);
    final enterIds = toEnter.sellerIds;
    final speakIds = toSpeak.sellerIds;
    final sellers = {
      for (final MapEntry(key: id, value: user) in users.entries)
        id: TicketSeller(
          userInfo: user,
          address: user.defaultWalletAddress,
          accessTicketType: enterIds.contains(id) ? outpost.enter_type : null,
          speakTicketType: speakIds.contains(id) ? outpost.speak_type : null,
        ),
    };
    allUsersToBuyTicketFrom.value = sellers;
    loadingUsers.value = false;

    final list = sellers.values.toList();
    final held = await Future.wait(list.map(_checkHeldTickets));
    for (var i = 0; i < list.length; i++) {
      list[i]
        ..boughtTicketToAccess = held[i].canEnter
        ..boughtTicketToSpeak = held[i].canSpeak
        ..accessPriceFullString = held[i].accessPriceFullString
        ..speakPriceFullString = held[i].speakPriceFullString
        ..checking = false;
    }
    allUsersToBuyTicketFrom.refresh();
    return checkAccess();
  }

  Future<Map<String, UserModel>> _resolveSellers(
    OutpostModel outpost,
    TicketSellerRefs toEnter,
    TicketSellerRefs toSpeak,
  ) async {
    final podiumIds = {...toEnter.podiumUserIds, ...toSpeak.podiumUserIds};
    final arenaIds = {...toEnter.arenaUserIds, ...toSpeak.arenaUserIds};
    final (podiumUsers, arenaUsers) = await (
      _userRepository.getUsersByIds(podiumIds.toList()),
      Future.wait(arenaIds.map(HttpApis.arenaApi.getUserFromStarsArenaById)),
    ).wait;

    final users = <String, UserModel>{};
    for (final user in podiumUsers) {
      // Tickets are bought on the wallet saved when the outpost was created,
      // which may not be the user's current one. Podium passes use aptos.
      final enterAddress = toEnter.addressByUserId[user.uuid];
      final speakAddress = toSpeak.addressByUserId[user.uuid];
      if (enterAddress != null &&
          outpost.enter_type != BuyableTicketTypes.onlyPodiumPassHolders) {
        user.external_wallet_address = enterAddress;
      }
      if (speakAddress != null &&
          outpost.speak_type != BuyableTicketTypes.onlyPodiumPassHolders) {
        user.external_wallet_address = speakAddress;
      }
      users[user.uuid] = user;
    }
    for (final user in arenaUsers.nonNulls) {
      users[user.id] = _userFromArena(user);
    }
    for (final address in {
      ...toEnter.directAddresses,
      ...toSpeak.directAddresses,
    }) {
      users[address] = _userFromAddress(address);
    }
    return users;
  }

  UserModel _userFromAddress(String address) => UserModel(
        uuid: address,
        name: 'Direct Address',
        email: '',
        external_wallet_address: address,
        address: address,
        aptos_address: address,
      );

  UserModel _userFromArena(StarsArenaUser user) => UserModel(
        uuid: user.id,
        name: user.twitterName,
        image: user.twitterPicture,
        email: '',
        external_wallet_address: user.mainAddress,
        address: user.mainAddress,
        followers_count: 0,
      );

  Future<OutpostAccesses> _checkHeldTickets(TicketSeller seller) async {
    final user = seller.userInfo;
    if (user.uuid == myId) {
      return OutpostAccesses(canEnter: true, canSpeak: true);
    }
    final accessType = seller.accessTicketType;
    final speakType = seller.speakTicketType;
    final accessQuote = accessType == null ? null : _quote(accessType, user);
    final speakQuote = speakType == null
        ? null
        : speakType == accessType
            ? accessQuote
            : _quote(speakType, user);
    final (enter, speak) = await (
      accessQuote ?? Future<_Quote?>.value(),
      speakQuote ?? Future<_Quote?>.value(),
    ).wait;
    return OutpostAccesses(
      canEnter: enter?.owned ?? false,
      canSpeak: speak?.owned ?? false,
      accessPriceFullString: enter?.price,
      speakPriceFullString: speak?.price,
    );
  }

  /// Whether I already hold [user]'s ticket of [type], and its price if not.
  Future<_Quote> _quote(String type, UserModel user) async {
    switch (type) {
      case BuyableTicketTypes.onlyArenaTicketHolders:
        final (shares, price) = await (
          getMyShares_arena(
            sharesSubject: user.defaultWalletAddress,
            chainId: avalancheChainId,
          ),
          getBuyPriceForArenaTicket(
            sharesSubject: user.defaultWalletAddress,
            chainId: avalancheChainId,
          ),
        ).wait;
        return _toQuote(
          owned: (shares ?? BigInt.zero) > BigInt.zero,
          price: bigIntWeiToDouble(price ?? BigInt.zero),
          chainId: avalancheChainId,
        );
      case BuyableTicketTypes.onlyFriendTechTicketHolders:
        final (shares, price) = await (
          internal_getUserShares_friendTech(
            defaultWallet: user.defaultWalletAddress,
            internalWallet: user.address,
            chainId: baseChainId,
          ),
          internal_getFriendTechTicketPrice(
            sharesSubject: user.defaultWalletAddress,
            chainId: baseChainId,
          ),
        ).wait;
        return _toQuote(
          owned: shares > BigInt.zero,
          price: bigIntWeiToDouble(price ?? BigInt.zero),
          chainId: baseChainId,
        );
      case BuyableTicketTypes.onlyPodiumPassHolders:
        final (passes, price) = await (
          AptosMovement.getMyBalanceOnPodiumPass(
            sellerAddress: user.aptos_address!,
          ),
          AptosMovement.getTicketPriceForPodiumPass(
            sellerAddress: user.aptos_address!,
          ),
        ).wait;
        return _toQuote(
          owned: (passes ?? BigInt.zero) > BigInt.zero,
          price: price ?? 0,
          chainId: movementAptosNetwork.chainId,
        );
      default:
        l.f('FIXME: add support for ticket type $type');
        return (owned: false, price: null);
    }
  }

  _Quote _toQuote({
    required bool owned,
    required double price,
    required String chainId,
  }) {
    if (owned) return (owned: true, price: null);
    return (
      owned: false,
      price: formatAmount(price, chainInfoByChainId(chainId).currency),
    );
  }

  Future<void> buyTicket({required TicketSeller ticketSeller}) async {
    final seller = allUsersToBuyTicketFrom.value[ticketSeller.userInfo.uuid];
    if (seller == null || seller.buying) return;

    // Access first; a separate speak ticket is bought on the next tap.
    final type = seller.shouldBuyAccessTicket
        ? seller.accessTicketType
        : seller.shouldBuySpeakTicket
            ? seller.speakTicketType
            : null;
    if (type == null) return;
    if (!BuyableTicketTypes.all.contains(type)) {
      l.f('FIXME: add support for ticket type $type');
      Toast.warning(
        title: "Update Required",
        message: "Please update the app to buy tickets",
      );
      return;
    }

    seller.buying = true;
    allUsersToBuyTicketFrom.refresh();
    try {
      final bought = switch (type) {
        BuyableTicketTypes.onlyArenaTicketHolders => await _buyOnArena(seller),
        BuyableTicketTypes.onlyFriendTechTicketHolders =>
          await _buyOnFriendTech(seller),
        _ => await _buyPodiumPass(seller),
      };
      if (bought) {
        if (seller.accessTicketType == type) seller.boughtTicketToAccess = true;
        if (seller.speakTicketType == type) seller.boughtTicketToSpeak = true;
      }
    } catch (e) {
      l.e(e);
      Toast.error(
        title: "Purchase failed",
        message: "Could not complete the ticket purchase. Please try again.",
      );
    } finally {
      seller.buying = false;
      allUsersToBuyTicketFrom.refresh();
    }
  }

  Future<UserModel?> _myReferrer() async {
    final referrerId = myUser.referrer_user_uuid;
    if (referrerId == null) return null;
    return _userRepository.getUserData(referrerId);
  }

  Future<bool> _buyPodiumPass(TicketSeller seller) async {
    final referrer = await _myReferrer();
    final (success, _) = await AptosMovement.buyPodiumPassFromUser(
      sellerAddress: seller.userInfo.aptos_address!,
      sellerName: seller.userInfo.name!,
      sellerUuid: seller.userInfo.uuid,
      referrer: referrer?.aptos_address ?? '',
    );
    return success ?? false;
  }

  Future<bool> _buyOnFriendTech(TicketSeller seller) async {
    final selectedWallet = await choseAWallet(chainId: baseChainId);
    if (selectedWallet == null) return false;
    final user = seller.userInfo;
    final activeWallets = await internal_friendTech_getActiveUserWallets(
      internalWalletAddress: user.address,
      externalWalletAddress: user.defaultWalletAddress,
      chainId: baseChainId,
    );
    if (!activeWallets.hasActiveWallet) {
      Toast.warning(title: "User not activated", message: "");
      return false;
    }
    final subject = activeWallets.preferedWalletAddress;
    if (selectedWallet == WalletNames.internal_EVM) {
      return internal_buyFriendTechTicket(
        sharesSubject: subject,
        chainId: baseChainId,
        targetUserId: user.uuid,
      );
    }
    return ext_buyFirendtechTicket(
      sharesSubject: subject,
      chainId: baseChainId,
      targetUserId: user.uuid,
    );
  }

  Future<bool> _buyOnArena(TicketSeller seller) async {
    final selectedWallet = await choseAWallet(chainId: avalancheChainId);
    if (selectedWallet == null) return false;
    final user = seller.userInfo;
    final referrerWallet = (await _myReferrer())?.defaultWalletAddress;
    final referrer = (referrerWallet?.isEmpty ?? true) ? null : referrerWallet;
    if (selectedWallet == WalletNames.internal_EVM) {
      return internal_buySharesWithReferrer(
        sharesSubject: user.defaultWalletAddress,
        chainId: avalancheChainId,
        targetUserId: user.uuid,
        referrerAddress: referrer,
      );
    }
    return ext_buySharesWithReferrer(
      sharesSubject: user.defaultWalletAddress,
      chainId: externalWalletChianId,
      targetUserId: user.uuid,
      referrerAddress: referrer,
    );
  }
}

bool accessIsBuyableByTicket(OutpostModel outpost) =>
    TicketAccessEvaluator(outpost, myId: myId).isAccessBuyable;

bool speakIsBuyableByTicket(OutpostModel outpost) =>
    TicketAccessEvaluator(outpost, myId: myId).isSpeakBuyable;

bool canEnterWithoutATicket(OutpostModel outpost,
        {bool joiningByLink = false}) =>
    TicketAccessEvaluator(outpost, myId: myId, joiningByLink: joiningByLink)
        .canEnterWithoutTicket;

bool isInvitedToOutpost(OutpostModel outpost) =>
    TicketAccessEvaluator(outpost, myId: myId).isInvited;
