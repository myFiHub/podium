import 'package:get/get.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/aptosClient.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/arena/models/user.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/logger.dart';

class TicketSeller {
  final UserModel userInfo;
  bool boughtTicketToSpeak;
  bool boughtTicketToAccess;
  bool buying;
  bool checking;
  String? speakTicketType;
  String? accessTicketType;
  String? accessPriceFullString;
  String? speakPriceFullString;

  final String address;

  get hasSeparateTickets =>
      speakTicketType != null &&
      accessTicketType != null &&
      speakTicketType != accessTicketType;

  get alreadyBoughtRequiredTickets {
    if (hasSeparateTickets) {
      return boughtTicketToAccess && boughtTicketToSpeak;
    } else if (shouldOnlyBuyOneTicket) {
      return boughtTicketToAccess || boughtTicketToSpeak;
    }
    return false;
  }

  get shouldOnlyBuyOneTicket => !hasSeparateTickets;

  get shouldBuyAccessTicket =>
      accessTicketType != null && !boughtTicketToAccess;
  get shouldBuySpeakTicket => speakTicketType != null && !boughtTicketToSpeak;

  TicketSeller({
    required this.userInfo,
    required this.boughtTicketToSpeak,
    required this.boughtTicketToAccess,
    required this.checking,
    required this.address,
    required this.buying,
    this.speakTicketType,
    this.accessTicketType,
    this.accessPriceFullString,
    this.speakPriceFullString,
  });
  copyWith({
    UserModel? userInfo,
    bool? boughtTicketToSpeak,
    bool? boughtTicketToAccess,
    bool? buying,
    bool? checking,
    String? speakTicketType,
    String? accessTicketType,
    String? address,
    String? accessPriceFullString,
    String? speakPriceFullString,
  }) {
    return TicketSeller(
      userInfo: userInfo ?? this.userInfo,
      boughtTicketToSpeak: boughtTicketToSpeak ?? this.boughtTicketToSpeak,
      boughtTicketToAccess: boughtTicketToAccess ?? this.boughtTicketToAccess,
      buying: buying ?? this.buying,
      checking: checking ?? this.checking,
      speakTicketType: speakTicketType ?? this.speakTicketType,
      accessTicketType: accessTicketType ?? this.accessTicketType,
      address: address ?? this.address,
      accessPriceFullString:
          accessPriceFullString ?? this.accessPriceFullString,
      speakPriceFullString: speakPriceFullString ?? this.speakPriceFullString,
    );
  }
}

class CheckticketController extends GetxController {
  final globalController = Get.find<GlobalController>();
  final OutpostsController outpostsController = Get.find<OutpostsController>();
  final Map<String, UserModel> usersToBuyTicketFromInOrderToHaveAccess = {};
  final Map<String, UserModel> usersToBuyTicketFromInOrderToSpeak = {};
  final allUsersToBuyTicketFrom = Rx<Map<String, TicketSeller>>({});

  final loadingUsers = false.obs;
  final outpost = Rxn<OutpostModel>();

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    // checkTickets();
  }

  @override
  void onClose() {
    super.onClose();
    l.f('CheckticketController closed');
  }

  _fakeUserModel(String address) {
    final fakeUser = UserModel(
      uuid: address,
      name: 'Direct Address',
      email: '',
      external_wallet_address: address,
      address: address,
    );
    return fakeUser;
  }

  userModelFromStarsArenaUserInfo({required StarsArenaUser user}) {
    final fakeUser = UserInfoModel(
      id: user.id,
      fullName: user.twitterName,
      avatar: user.twitterPicture,
      email: '',
      evm_externalWalletAddress: user.mainAddress,
      evmInternalWalletAddress: user.mainAddress,
      following: [],
      numberOfFollowers: 0,
    );
    return fakeUser;
  }

  (List<UserModel>, List<UserModel>) _generateFakeUsers() {
    final requiredDirectAddressesToAccess =
        (outpost.value!.tickets_to_enter ?? [])
            .where((e) => e.user_uuid == null || e.user_uuid == '')
            .map((e) => e.address)
            .toList();
    final requiredDirectAddressesToSpeak =
        (outpost.value!.tickets_to_speak ?? [])
            .where((e) => e.user_uuid == null || e.user_uuid == '')
            .map((e) => e.address)
            .toList();

    List<UserModel> fakeUsersToBuyTicketFromInOrderToHaveAccess = [];
    List<UserModel> fakeUsersToBuyTicketFromInOrderToSpeak = [];

    requiredDirectAddressesToSpeak.forEach((element) {
      fakeUsersToBuyTicketFromInOrderToSpeak.add(_fakeUserModel(element));
    });

    requiredDirectAddressesToAccess.forEach((element) {
      fakeUsersToBuyTicketFromInOrderToHaveAccess.add(_fakeUserModel(element));
    });
    return (
      fakeUsersToBuyTicketFromInOrderToHaveAccess,
      fakeUsersToBuyTicketFromInOrderToSpeak
    );
  }

  Future<GroupAccesses> checkTickets() async {
    allUsersToBuyTicketFrom.value = {};
    loadingUsers.value = true;
    final requiredTicketsToAccess = outpost.value!.tickets_to_enter ?? [];
    final requiredTicketsToSpeak = outpost.value!.tickets_to_speak ?? [];

    final accessIds = requiredTicketsToAccess
        .map((e) => e.user_uuid ?? '')
        .where((e) => !(e).contains(arenaUserIdPrefix))
        .where((e) => e.isNotEmpty)
        .toList();
    final speakIds = requiredTicketsToSpeak
        .map((e) => e.user_uuid ?? '')
        .where((e) => !(e).contains(arenaUserIdPrefix))
        .where((e) => e.isNotEmpty)
        .toList();
    final [usersForAccess, usersForSpeak] = await Future.wait([
      HttpApis.podium.getUsersByIds(accessIds),
      HttpApis.podium.getUsersByIds(speakIds),
    ]);
// when we were saving a user that was added by handle, we added $arenaUserIdPrefix at the start ot the user id
// now we should fetch them separately and add them to ticket list

    final directArenaAccessIds = requiredTicketsToAccess
        .map((e) => e.user_uuid)
        .where((e) => e?.contains(arenaUserIdPrefix) ?? false)
        .map((e) => e?.replaceAll(arenaUserIdPrefix, '') ?? '')
        .toList();
    final directArenaSpeakIds = requiredTicketsToSpeak
        .map((e) => e.user_uuid)
        .where((e) => e?.contains(arenaUserIdPrefix) ?? false)
        .map((e) => e?.replaceAll(arenaUserIdPrefix, '') ?? '')
        .toList();

    final directArenaUsersForAccess = await Future.wait(directArenaAccessIds
        .map((e) => HttpApis.arenaApi.getUserFromStarsArenaById(e)));
    final directArenaUsersForSpeak = await Future.wait(directArenaSpeakIds
        .map((e) => HttpApis.arenaApi.getUserFromStarsArenaById(e)));
    directArenaUsersForAccess.forEach((res) {
      if (res != null) {
        usersForAccess.add(userModelFromStarsArenaUserInfo(user: res));
      }
    });
    directArenaUsersForSpeak.forEach((res) {
      if (res != null) {
        usersForSpeak.add(userModelFromStarsArenaUserInfo(user: res));
      }
    });

// end of direct arena user adding

    // these loops are crutial to set the local wallet address to the user
    // because when creating the group, addres saved for buyin should have been activated,
    // that was the address that was SAVED in ticketsRequiredToAccess or ticketsRequiredToSpeak
    for (var i = 0; i < requiredTicketsToAccess.length; i++) {
      final user = requiredTicketsToAccess[i];
      if (user.user_uuid?.contains(arenaUserIdPrefix) ??
          false ||
              // if the group is podium pass holders, we don't need to set the wallet address
              outpost.value!.enter_type ==
                  BuyableTicketTypes.onlyPodiumPassHolders) {
        continue;
      }

      final userInfo = usersForAccess
          .firstWhere((element) => element.uuid == user.user_uuid);
      userInfo.external_wallet_address = user.address;
      usersForAccess[i] = userInfo;
    }
    for (var i = 0; i < requiredTicketsToSpeak.length; i++) {
      final user = requiredTicketsToSpeak[i];
      if (user.user_uuid?.contains(arenaUserIdPrefix) ??
          false ||
              // if the group is podium pass holders, we don't need to set the wallet address
              outpost.value!.speak_type ==
                  BuyableTicketTypes.onlyPodiumPassHolders) {
        continue;
      }
      final userInfo =
          usersForSpeak.firstWhere((element) => element.uuid == user.user_uuid);
      userInfo.external_wallet_address = user.address;
      usersForSpeak[i] = userInfo;
    }
    // fake users should be added after the real users have been added and modified

    final (fakeUsersToAccess, fakeUsersToSpeak) = _generateFakeUsers();

    // add fake users to the list
    usersForAccess.addAll(fakeUsersToAccess);
    usersForSpeak.addAll(fakeUsersToSpeak);
    accessIds.addAll(fakeUsersToAccess.map((e) => e.uuid).toList());
    speakIds.addAll(fakeUsersToSpeak.map((e) => e.uuid).toList());
    // end of adding fake users

    usersForAccess.forEach((element) {
      usersToBuyTicketFromInOrderToHaveAccess[element.uuid] = element;
    });
    usersForSpeak.forEach((element) {
      usersToBuyTicketFromInOrderToSpeak[element.uuid] = element;
    });
    loadingUsers.value = false;
    final mergedUsers = {
      ...usersToBuyTicketFromInOrderToHaveAccess,
      ...usersToBuyTicketFromInOrderToSpeak,
    };
    mergedUsers.forEach((key, value) {
      final requiredAccessTypeForThisUser =
          (accessIds.contains(key) || directArenaAccessIds.contains(key))
              ? outpost.value!.enter_type
              : null;
      final requiredSpeakTypeForThisUser =
          (speakIds.contains(key) || directArenaSpeakIds.contains(key))
              ? outpost.value!.speak_type
              : null;
      allUsersToBuyTicketFrom.value[key] = TicketSeller(
        userInfo: value,
        boughtTicketToAccess: false,
        boughtTicketToSpeak: false,
        speakTicketType: requiredSpeakTypeForThisUser,
        accessTicketType: requiredAccessTypeForThisUser,
        checking: true,
        buying: false,
        address: value.defaultWalletAddress,
      );
    });
    allUsersToBuyTicketFrom.refresh();

    final entries = allUsersToBuyTicketFrom.value.entries.toList();
    final Map<String, Map<String, TicketSeller>> ticketTypeCalls = {
      BuyableTicketTypes.onlyArenaTicketHolders: {},
      BuyableTicketTypes.onlyFriendTechTicketHolders: {},
      BuyableTicketTypes.onlyPodiumPassHolders: {},
    };
    for (final entry in entries) {
      final key = entry.key;
      final ticketSeller = entry.value;
      if (ticketSeller.accessTicketType ==
              BuyableTicketTypes.onlyArenaTicketHolders ||
          ticketSeller.speakTicketType ==
              BuyableTicketTypes.onlyArenaTicketHolders) {
        ticketTypeCalls[BuyableTicketTypes.onlyArenaTicketHolders]![key] =
            ticketSeller;
      } else if (ticketSeller.accessTicketType ==
              BuyableTicketTypes.onlyFriendTechTicketHolders ||
          ticketSeller.speakTicketType ==
              BuyableTicketTypes.onlyFriendTechTicketHolders) {
        ticketTypeCalls[BuyableTicketTypes.onlyFriendTechTicketHolders]![key] =
            ticketSeller;
      } else if (ticketSeller.accessTicketType ==
              BuyableTicketTypes.onlyPodiumPassHolders ||
          ticketSeller.speakTicketType ==
              BuyableTicketTypes.onlyPodiumPassHolders) {
        ticketTypeCalls[BuyableTicketTypes.onlyPodiumPassHolders]![key] =
            ticketSeller;
      }
    }

    final arenaTicketSellers =
        ticketTypeCalls[BuyableTicketTypes.onlyArenaTicketHolders]!
            .values
            .toList();
    final friendTechTicketSellers =
        ticketTypeCalls[BuyableTicketTypes.onlyFriendTechTicketHolders]!
            .values
            .toList();
    final podiumTicketSellers =
        ticketTypeCalls[BuyableTicketTypes.onlyPodiumPassHolders]!
            .values
            .toList();
    final FriendTechCallArray = friendTechTicketSellers
        .map((e) => checkIfIveBoughtTheTicketFromUser(e.userInfo))
        .toList();
    final ArenaCallArray = arenaTicketSellers
        .map((e) => checkIfIveBoughtTheTicketFromUser(e.userInfo))
        .toList();
    final PodiumCallArray = podiumTicketSellers
        .map((e) => checkIfIveBoughtTheTicketFromUser(e.userInfo))
        .toList();
    final [FriendTechResults, arenaResults, podiumPassResults] =
        await Future.wait([
      Future.wait(FriendTechCallArray),
      Future.wait(ArenaCallArray),
      Future.wait(PodiumCallArray),
    ]);
    for (var i = 0; i < arenaResults.length; i++) {
      final seller = arenaTicketSellers[i];
      final userId = seller.userInfo.uuid;
      final access = arenaResults[i];
      final ticketTypeToSpeakForThisSeller =
          allUsersToBuyTicketFrom.value[userId]?.speakTicketType;
      final ticketTypeToAccessForThisSeller =
          allUsersToBuyTicketFrom.value[userId]?.accessTicketType;
      final original = allUsersToBuyTicketFrom.value[userId];
      allUsersToBuyTicketFrom.value[userId] = TicketSeller(
        accessTicketType: ticketTypeToAccessForThisSeller,
        speakTicketType: ticketTypeToSpeakForThisSeller,
        userInfo: original!.userInfo,
        address: original.address,
        boughtTicketToSpeak: original.boughtTicketToSpeak || access.canSpeak,
        boughtTicketToAccess: original.boughtTicketToAccess || access.canEnter,
        checking: false,
        buying: false,
        accessPriceFullString: access.accessPriceFullString,
        speakPriceFullString: access.speakPriceFullString,
      );
    }

    for (var i = 0; i < FriendTechResults.length; i++) {
      final seller = friendTechTicketSellers[i];
      final userId = seller.userInfo.uuid;
      final access = FriendTechResults[i];
      final ticketTypeToSpeakForThisSeller =
          allUsersToBuyTicketFrom.value[userId]?.speakTicketType;
      final ticketTypeToAccessForThisSeller =
          allUsersToBuyTicketFrom.value[userId]?.accessTicketType;
      final original = allUsersToBuyTicketFrom.value[userId];
      allUsersToBuyTicketFrom.value[userId] = TicketSeller(
        accessTicketType: ticketTypeToAccessForThisSeller,
        speakTicketType: ticketTypeToSpeakForThisSeller,
        userInfo: original!.userInfo,
        address: original.address,
        boughtTicketToSpeak: original.boughtTicketToSpeak || access.canSpeak,
        boughtTicketToAccess: original.boughtTicketToAccess || access.canEnter,
        checking: false,
        buying: false,
        accessPriceFullString: access.accessPriceFullString,
        speakPriceFullString: access.speakPriceFullString,
      );
    }

    for (var i = 0; i < podiumPassResults.length; i++) {
      final seller = podiumTicketSellers[i];
      final userId = seller.userInfo.uuid;
      final access = podiumPassResults[i];
      final original = allUsersToBuyTicketFrom.value[userId];
      allUsersToBuyTicketFrom.value[userId] = TicketSeller(
        accessTicketType: original!.accessTicketType,
        speakTicketType: original.speakTicketType,
        userInfo: original.userInfo,
        address: original.address,
        boughtTicketToSpeak: original.boughtTicketToSpeak || access.canSpeak,
        boughtTicketToAccess: original.boughtTicketToAccess || access.canEnter,
        checking: false,
        buying: false,
        accessPriceFullString: access.accessPriceFullString,
        speakPriceFullString: access.speakPriceFullString,
      );
    }
    allUsersToBuyTicketFrom.refresh();
    return checkAccess();
  }

  GroupAccesses checkAccess() {
    final canSpeak = allUsersToBuyTicketFrom.value.entries.any(
          (element) =>
              element.value.boughtTicketToSpeak == true &&
              element.value.speakTicketType != null,
        ) ||
        canSpeakWithoutATicket;

    final canEnter = allUsersToBuyTicketFrom.value.entries.any(
          (element) =>
              element.value.boughtTicketToAccess == true &&
              element.value.accessTicketType != null,
        ) ||
        canEnterWithoutTicket;
    final accessResult = GroupAccesses(
      canEnter: isAccessBuyableByTicket ? canEnter : canEnterWithoutTicket,
      canSpeak: isSpeakBuyableByTicket ? canSpeak : canSpeakWithoutATicket,
    );
    return accessResult;
  }

  buyTicket({
    required TicketSeller ticketSeller,
  }) async {
    try {
      final groupAccessType = outpost.value!.enter_type;
      final groupSpeakerType = outpost.value!.speak_type;
      final unsupportedAccessTicket = (groupAccessType !=
              BuyableTicketTypes.onlyArenaTicketHolders &&
          groupAccessType != BuyableTicketTypes.onlyFriendTechTicketHolders &&
          groupAccessType != BuyableTicketTypes.onlyPodiumPassHolders &&
          isAccessBuyableByTicket);
      final unsupportedSpeakTicket = (groupSpeakerType !=
              BuyableTicketTypes.onlyArenaTicketHolders &&
          groupSpeakerType != BuyableTicketTypes.onlyFriendTechTicketHolders &&
          groupSpeakerType != BuyableTicketTypes.onlyPodiumPassHolders &&
          isSpeakBuyableByTicket);

      if (unsupportedAccessTicket || unsupportedSpeakTicket) {
        l.f('FIXME: add support for other ticket types');

        Toast.warning(
          title: "Update Required",
          message: "Please update the app to buy tickets",
        );
        allUsersToBuyTicketFrom.value[ticketSeller.userInfo.uuid]!.buying =
            false;
        allUsersToBuyTicketFrom.refresh();
        return;
      }
      if (ticketSeller.shouldBuyAccessTicket ||
          ticketSeller.shouldBuySpeakTicket) {
        // buy access tickets first
        if (((ticketSeller.accessTicketType ==
                BuyableTicketTypes.onlyArenaTicketHolders &&
            ticketSeller.shouldBuyAccessTicket))) {
          await buyTicketFromTicketSellerOnArena(ticketSeller: ticketSeller);
        } else if (((ticketSeller.accessTicketType ==
                BuyableTicketTypes.onlyFriendTechTicketHolders &&
            ticketSeller.shouldBuyAccessTicket))) {
          await buyTicketFromTicketSellerOnFriendTech(
            ticketSeller: ticketSeller,
          );
        } else if (ticketSeller.accessTicketType ==
                BuyableTicketTypes.onlyPodiumPassHolders &&
            ticketSeller.shouldBuyAccessTicket) {
          await buyTicketFromTicketSellerOnPodiumPass(
            ticketSeller: ticketSeller,
          );
          // End buy access tickets first
          // then buy speak tickets
        } else if (ticketSeller.speakTicketType ==
                BuyableTicketTypes.onlyArenaTicketHolders &&
            ticketSeller.shouldBuySpeakTicket) {
          await buyTicketFromTicketSellerOnArena(ticketSeller: ticketSeller);
        } else if (ticketSeller.speakTicketType ==
                BuyableTicketTypes.onlyFriendTechTicketHolders &&
            ticketSeller.shouldBuySpeakTicket) {
          await buyTicketFromTicketSellerOnFriendTech(
            ticketSeller: ticketSeller,
          );
        } else if (ticketSeller.speakTicketType ==
                BuyableTicketTypes.onlyPodiumPassHolders &&
            ticketSeller.shouldBuySpeakTicket) {
          await buyTicketFromTicketSellerOnPodiumPass(
              ticketSeller: ticketSeller);
          // End buy speak tickets
        } else {
          l.f('FIXME: add support for other ticket types');

          Toast.warning(
            title: "Update Required",
            message: "Please update the app to buy tickets",
          );

          allUsersToBuyTicketFrom.value[ticketSeller.userInfo.uuid]!.buying =
              false;
          allUsersToBuyTicketFrom.refresh();
        }
      } else {
        Toast.warning(
          title: "Update required",
          message: "tickets are not on same chain",
        );
      }
    } catch (e) {
      l.e(e);
      Toast.error(
        title: "Error",
        message: e.toString(),
      );
    } finally {
      allUsersToBuyTicketFrom.value[ticketSeller.userInfo.uuid]!.buying = false;
      allUsersToBuyTicketFrom.refresh();
    }
  }

  Future<bool> buyTicketFromTicketSellerOnPodiumPass({
    required TicketSeller ticketSeller,
  }) async {
    allUsersToBuyTicketFrom.value[ticketSeller.userInfo.uuid]!.buying = true;
    allUsersToBuyTicketFrom.refresh();
    bool? bought = false;
    String referrer = '';

    final myReferrer = myUser.referer_user_uuid;
    if (myReferrer != null) {
      final referrerInfo = await getUserById(myReferrer);
      if (referrerInfo != null) {
        referrer = referrerInfo.aptosInternalWalletAddress;
      }
    }

    bought = await AptosMovement.buyTicketFromTicketSellerOnPodiumPass(
      sellerAddress: ticketSeller.userInfo.aptos_address!,
      sellerName: ticketSeller.userInfo.name!,
      referrer: referrer,
    );
    if (bought == null) {
      return false;
    }
    allUsersToBuyTicketFrom.value[ticketSeller.userInfo.uuid]!.buying = false;

    if (ticketSeller.speakTicketType ==
        BuyableTicketTypes.onlyPodiumPassHolders) {
      allUsersToBuyTicketFrom
          .value[ticketSeller.userInfo.uuid]!.boughtTicketToSpeak = bought;
    }
    if (ticketSeller.accessTicketType ==
        BuyableTicketTypes.onlyPodiumPassHolders) {
      allUsersToBuyTicketFrom
          .value[ticketSeller.userInfo.uuid]!.boughtTicketToAccess = bought;
    }
    allUsersToBuyTicketFrom.refresh();
    return bought;
  }

  Future<bool> buyTicketFromTicketSellerOnFriendTech({
    required TicketSeller ticketSeller,
  }) async {
    final selectedWallet = await choseAWallet(chainId: baseChainId);
    allUsersToBuyTicketFrom.value[ticketSeller.userInfo.uuid]!.buying = true;
    allUsersToBuyTicketFrom.refresh();
    if (selectedWallet == null) {
      allUsersToBuyTicketFrom.value[ticketSeller.userInfo.uuid]!.buying = false;
      allUsersToBuyTicketFrom.refresh();
      return false;
    }
    bool bought = false;

    final activeWallets = await internal_friendTech_getActiveUserWallets(
      internalWalletAddress: ticketSeller.userInfo.address,
      externalWalletAddress: ticketSeller.userInfo.defaultWalletAddress,
      chainId: baseChainId,
    );
    if (!activeWallets.hasActiveWallet) {
      Toast.warning(
        title: "User not activated",
        message: "",
      );
      allUsersToBuyTicketFrom.value[ticketSeller.userInfo.uuid]!.buying = false;
      allUsersToBuyTicketFrom.refresh();
      return false;
    }
    final preferedWalletAddress = activeWallets.preferedWalletAddress;
    if (selectedWallet == WalletNames.internal_EVM) {
      bought = await internal_buyFriendTechTicket(
        sharesSubject: preferedWalletAddress,
        // temp chainId hardcoded
        chainId: baseChainId,
        targetUserId: ticketSeller.userInfo.uuid,
      );
    } else {
      bought = await ext_buyFirendtechTicket(
        sharesSubject: preferedWalletAddress,
        // temp chainId hardcoded
        chainId: baseChainId,
        targetUserId: ticketSeller.userInfo.uuid,
      );
    }
    allUsersToBuyTicketFrom.value[ticketSeller.userInfo.uuid]!.buying = false;

    if (ticketSeller.speakTicketType ==
        BuyableTicketTypes.onlyFriendTechTicketHolders) {
      allUsersToBuyTicketFrom
          .value[ticketSeller.userInfo.uuid]!.boughtTicketToSpeak = bought;
    }
    if (ticketSeller.accessTicketType ==
        BuyableTicketTypes.onlyFriendTechTicketHolders) {
      allUsersToBuyTicketFrom
          .value[ticketSeller.userInfo.uuid]!.boughtTicketToAccess = bought;
    }

    allUsersToBuyTicketFrom.refresh();
    return bought;
  }

  Future<bool> buyTicketFromTicketSellerOnArena({
    required TicketSeller ticketSeller,
  }) async {
    final selectedWallet = await choseAWallet(chainId: avalancheChainId);
    allUsersToBuyTicketFrom.value[ticketSeller.userInfo.uuid]!.buying = true;
    allUsersToBuyTicketFrom.refresh();
    if (selectedWallet == null) {
      allUsersToBuyTicketFrom.value[ticketSeller.userInfo.uuid]!.buying = false;
      allUsersToBuyTicketFrom.refresh();
      return false;
    }
    bool bought = false;
    String referrer = '';
    final myReferrer = myUser.referer_user_uuid;
    if (myReferrer != null) {
      final referrerInfo = await getUserById(myReferrer);
      if (referrerInfo != null) {
        referrer = referrerInfo.defaultWalletAddress;
      }
    }
    if (selectedWallet == WalletNames.internal_EVM) {
      bought = await internal_buySharesWithReferrer(
        sharesSubject: ticketSeller.userInfo.defaultWalletAddress,
        chainId: avalancheChainId,
        targetUserId: ticketSeller.userInfo.uuid,
        referrerAddress: referrer.isEmpty ? null : referrer,
      );
    } else {
      bought = await ext_buySharesWithReferrer(
        sharesSubject: ticketSeller.userInfo.defaultWalletAddress,
        chainId: externalWalletChianId,
        targetUserId: ticketSeller.userInfo.uuid,
        referrerAddress: referrer.isEmpty ? null : referrer,
      );
      l.d('bought: $bought');
    }
    allUsersToBuyTicketFrom.value[ticketSeller.userInfo.uuid]!.buying = false;
    if (ticketSeller.accessTicketType ==
        BuyableTicketTypes.onlyArenaTicketHolders) {
      allUsersToBuyTicketFrom
          .value[ticketSeller.userInfo.uuid]!.boughtTicketToAccess = bought;
    }
    if (ticketSeller.speakTicketType ==
        BuyableTicketTypes.onlyArenaTicketHolders) {
      allUsersToBuyTicketFrom
          .value[ticketSeller.userInfo.uuid]!.boughtTicketToSpeak = bought;
    }
    allUsersToBuyTicketFrom.refresh();
    return bought;
  }

  bool get isAccessBuyableByTicket {
    return accessIsBuyableByTicket(outpost.value!);
  }

  bool get isSpeakBuyableByTicket {
    return speakIsBuyableByTicket(outpost.value!);
  }

  bool get canSpeakWithoutATicket {
    return canISpeakWithoutTicket(outpost: outpost.value!);
  }

  bool get canEnterWithoutTicket {
    final g = outpost.value!;
    return canEnterWithoutATicket(g);
  }

  Future<GroupAccesses> checkIfIveBoughtTheTicketFromUser(
    UserModel user,
  ) async {
    final userId = user.uuid;
    final myUser = globalController.myUserInfo.value!;
    if (userId == myUser.uuid)
      return GroupAccesses(canEnter: true, canSpeak: true);
    GroupAccesses access = GroupAccesses(canEnter: false, canSpeak: false);

    // check if user has access, using any ticket
    if (allUsersToBuyTicketFrom.value[userId]?.accessTicketType != null) {
      if (outpost.value!.enter_type ==
          BuyableTicketTypes.onlyArenaTicketHolders) {
        final (myShares, price) = await (
          getMyShares_arena(
            sharesSubject: user.defaultWalletAddress,
            chainId: avalancheChainId,
          ),
          getBuyPriceForArenaTicket(
            sharesSubject: user.defaultWalletAddress,
            chainId: avalancheChainId,
          )
        ).wait;
        if (myShares != null && myShares > BigInt.zero) {
          access.canEnter = true;
        } else {
          final priceDouble = bigIntWeiToDouble(price ?? BigInt.zero);
          final priceStringFull = priceDouble.toString() +
              ' ${chainInfoByChainId(avalancheChainId).currency}';
          access.accessPriceFullString = priceStringFull;
        }
      } else if (outpost.value!.enter_type ==
          BuyableTicketTypes.onlyFriendTechTicketHolders) {
        final (myShares, price) = await (
          internal_getUserShares_friendTech(
            defaultWallet: user.defaultWalletAddress,
            internalWallet: user.address,
            chainId: baseChainId,
          ),
          internal_getFriendTechTicketPrice(
              sharesSubject: user.defaultWalletAddress, chainId: baseChainId)
        ).wait;
        if (myShares > BigInt.zero) {
          access.canEnter = true;
        } else {
          final priceDouble = bigIntWeiToDouble(price ?? BigInt.zero);
          final priceStringFull = priceDouble.toString() +
              ' ${chainInfoByChainId(baseChainId).currency}';
          access.accessPriceFullString = priceStringFull;
        }
      } else if (outpost.value!.enter_type ==
          BuyableTicketTypes.onlyPodiumPassHolders) {
        final (myShares, price) = await (
          AptosMovement.getMyBalanceOnPodiumPass(
            sellerAddress: user.aptos_address!,
          ),
          AptosMovement.getTicketPriceForPodiumPass(
            sellerAddress: user.aptos_address!,
          )
        ).wait;
        if (myShares != null && myShares > BigInt.zero) {
          access.canEnter = true;
        } else {
          final p = price ?? BigInt.zero;
          final priceStringFull = p.toString() +
              ' ${chainInfoByChainId(movementAptosNetwork.chainId).currency}';
          access.accessPriceFullString = priceStringFull;
        }
      } else {
        l.f('FIXME: add support for other ticket types ');
      }
    }

    if (allUsersToBuyTicketFrom.value[userId]?.speakTicketType != null) {
      if (outpost.value!.speak_type ==
          BuyableTicketTypes.onlyArenaTicketHolders) {
        final (myShares, price) = await (
          getMyShares_arena(
            sharesSubject: user.defaultWalletAddress,
            chainId: avalancheChainId,
          ),
          getBuyPriceForArenaTicket(
            sharesSubject: user.defaultWalletAddress,
            chainId: avalancheChainId,
          )
        ).wait;
        if (myShares != null && myShares > BigInt.zero) {
          access.canSpeak = true;
        } else {
          final priceDouble = bigIntWeiToDouble(price ?? BigInt.zero);
          final priceStringFull = priceDouble.toString() +
              ' ${chainInfoByChainId(avalancheChainId).currency}';
          access.speakPriceFullString = priceStringFull;
        }
      } else if (outpost.value!.speak_type ==
          BuyableTicketTypes.onlyFriendTechTicketHolders) {
        final (myShares, price) = await (
          internal_getUserShares_friendTech(
            defaultWallet: user.defaultWalletAddress,
            internalWallet: user.address,
            chainId: baseChainId,
          ),
          internal_getFriendTechTicketPrice(
              sharesSubject: user.defaultWalletAddress, chainId: baseChainId)
        ).wait;
        if (myShares > BigInt.zero) {
          access.canSpeak = true;
        } else {
          final priceDouble = bigIntWeiToDouble(price ?? BigInt.zero);
          final priceStringFull = priceDouble.toString() +
              ' ${chainInfoByChainId(baseChainId).currency}';
          access.speakPriceFullString = priceStringFull;
        }
      } else if (outpost.value!.speak_type ==
          BuyableTicketTypes.onlyPodiumPassHolders) {
        final (myShares, price) = await (
          AptosMovement.getMyBalanceOnPodiumPass(
            sellerAddress: user.aptos_address!,
          ),
          AptosMovement.getTicketPriceForPodiumPass(
            sellerAddress: user.aptos_address!,
          )
        ).wait;
        if (myShares != null && myShares > BigInt.zero) {
          access.canSpeak = true;
        } else {
          final p = price ?? BigInt.zero;
          final priceStringFull = p.toString() +
              ' ${chainInfoByChainId(movementAptosNetwork.chainId).currency}';
          access.speakPriceFullString = priceStringFull;
        }
      } else {
        l.f('FIXME: add support for other ticket types');
      }
    }

    return access;
  }
}

accessIsBuyableByTicket(OutpostModel group) {
  final groupAccessType = group.enter_type;
  return groupAccessType == BuyableTicketTypes.onlyArenaTicketHolders ||
      groupAccessType == BuyableTicketTypes.onlyFriendTechTicketHolders ||
      groupAccessType == BuyableTicketTypes.onlyPodiumPassHolders;
}

speakIsBuyableByTicket(OutpostModel group) {
  final groupSpeakType = group.speak_type;
  return groupSpeakType == BuyableTicketTypes.onlyArenaTicketHolders ||
      groupSpeakType == BuyableTicketTypes.onlyFriendTechTicketHolders ||
      groupSpeakType == BuyableTicketTypes.onlyPodiumPassHolders;
}

canEnterWithoutATicket(OutpostModel group) {
  final globalController = Get.find<GlobalController>();
  final g = group;
  final amIInvited = g.i_am_member;
  final link = globalController.deepLinkRoute;
  final cameHereByLink = g.enter_type == FreeOutpostAccessTypes.onlyLink &&
      link.isNotEmpty &&
      link.contains(g.uuid);
  if (g.enter_type == FreeOutpostAccessTypes.onlyLink) {
    return cameHereByLink;
  }
  if (g.enter_type == FreeOutpostAccessTypes.invitees) {
    return amIInvited;
  }
  if (g.enter_type == FreeOutpostAccessTypes.public) {
    return true;
  }
  return false;
}
