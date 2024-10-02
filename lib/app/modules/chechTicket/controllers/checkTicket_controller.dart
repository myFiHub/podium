import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/firebase_particle_user.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';

class TicketSeller {
  final UserInfoModel userInfo;
  bool boughtTicketToSpeak;
  bool boughtTicketToAccess;
  bool buying;
  bool checking;
  String? speakTicketType;
  String? accessTicketType;

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

  TicketSeller({
    required this.userInfo,
    required this.boughtTicketToSpeak,
    required this.boughtTicketToAccess,
    required this.checking,
    required this.address,
    required this.buying,
    this.speakTicketType,
    this.accessTicketType,
  });
  copyWith({
    UserInfoModel? userInfo,
    bool? boughtTicketToSpeak,
    bool? boughtTicketToAccess,
    bool? buying,
    bool? checking,
    String? speakTicketType,
    String? accessTicketType,
    String? address,
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
    );
  }
}

class CheckticketController extends GetxController
    with FireBaseUtils, BlockChainInteractions {
  final globalController = Get.find<GlobalController>();
  final GroupsController groupsController = Get.find<GroupsController>();
  final Map<String, UserInfoModel> usersToBuyTicketFromInOrderToHaveAccess = {};
  final Map<String, UserInfoModel> usersToBuyTicketFromInOrderToSpeak = {};
  final allUsersToBuyTicketFrom = Rx<Map<String, TicketSeller>>({});

  final loadingUsers = false.obs;
  final group = Rxn<FirebaseGroup>();

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
    log.f('CheckticketController closed');
  }

  _fakeUserModel(String address) {
    final fakeUser = UserInfoModel(
      id: address,
      fullName: 'Direct Address',
      avatar: '',
      email: '',
      localWalletAddress: address,
      following: [],
      numberOfFollowers: 0,
      savedParticleUserInfo: FirebaseParticleAuthUserInfo(
        wallets: [
          ParticleAuthWallet(
            address: address,
            chain: 'evm_chain',
          )
        ],
        uuid: '',
      ),
    );
    return fakeUser;
  }

  (List<UserInfoModel>, List<UserInfoModel>) _generateFakeUsers() {
    final requiredDirectAddressesToAccess =
        group.value!.requiredAddressesToEnter;
    final requiredDirectAddressesToSpeak =
        group.value!.requiredAddressesToSpeak;

    List<UserInfoModel> fakeUsersToBuyTicketFromInOrderToHaveAccess = [];
    List<UserInfoModel> fakeUsersToBuyTicketFromInOrderToSpeak = [];

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
    loadingUsers.value = true;
    final requiredTicketsToAccess = group.value!.ticketsRequiredToAccess;
    final requiredTicketsToSpeak = group.value!.ticketsRequiredToSpeak;

    final accessIds = requiredTicketsToAccess.map((e) => e.userId).toList();
    final speakIds = requiredTicketsToSpeak.map((e) => e.userId).toList();
    final [usersForAccess, usersForSpeak] = await Future.wait([
      getUsersByIds(accessIds),
      getUsersByIds(speakIds),
    ]);

    final (fakeUsersToAccess, fakeUsersToSpeak) = _generateFakeUsers();

    // add fake users to the list
    usersForAccess.addAll(fakeUsersToAccess);
    usersForSpeak.addAll(fakeUsersToSpeak);
    accessIds.addAll(fakeUsersToAccess.map((e) => e.id).toList());
    speakIds.addAll(fakeUsersToSpeak.map((e) => e.id).toList());
    // end of adding fake users

    usersForAccess.forEach((element) {
      usersToBuyTicketFromInOrderToHaveAccess[element.id] = element;
    });
    usersForSpeak.forEach((element) {
      usersToBuyTicketFromInOrderToSpeak[element.id] = element;
    });
    loadingUsers.value = false;
    final mergedUsers = {
      ...usersToBuyTicketFromInOrderToHaveAccess,
      ...usersToBuyTicketFromInOrderToSpeak,
    };
    mergedUsers.forEach((key, value) {
      final requiredAccessTypeForThisUser =
          accessIds.contains(key) ? group.value!.accessType : null;
      final requiredSpeakTypeForThisUser =
          speakIds.contains(key) ? group.value!.speakerType : null;
      allUsersToBuyTicketFrom.value[key] = TicketSeller(
        userInfo: value,
        boughtTicketToAccess: false,
        boughtTicketToSpeak: false,
        speakTicketType: requiredSpeakTypeForThisUser,
        accessTicketType: requiredAccessTypeForThisUser,
        checking: true,
        buying: false,
        address: value.defaultWalletAddress ?? '',
      );
    });
    allUsersToBuyTicketFrom.refresh();

    final results = await Future.wait(
      allUsersToBuyTicketFrom.value.entries.map(
        (e) => checkIfIveBoughtTheTicketFromUser(
          e.value.userInfo,
          e.value.userInfo.id,
        ),
      ),
    );
    final allKeys = allUsersToBuyTicketFrom.value.keys.toList();
    for (var i = 0; i < results.length; i++) {
      final access = results[i];
      final key = allKeys[i];

      final ticketTypeToSpeakForThisSeller =
          allUsersToBuyTicketFrom.value[key]?.speakTicketType;
      final ticketTypeToAccessForThisSeller =
          allUsersToBuyTicketFrom.value[key]?.accessTicketType;

      allUsersToBuyTicketFrom.value[key] =
          allUsersToBuyTicketFrom.value[key]!.copyWith(
        speakTicketType: ticketTypeToSpeakForThisSeller,
        accessTicketType: ticketTypeToAccessForThisSeller,
        boughtTicketToAccess: access.canEnter,
        boughtTicketToSpeak: access.canSpeak,
        checking: false,
        buying: false,
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
    );
    final accessResult = GroupAccesses(
      canEnter: isAccessBuyableByTicket ? canEnter : canEnterWithoutTicket,
      canSpeak: isSpeakBuyableByTicket ? canSpeak : canSpeakWithoutATicket,
    );
    return accessResult;
  }

  buyTicket({
    required TicketSeller ticketSeller,
  }) async {
    if (ticketSeller.accessTicketType != null &&
        ticketSeller.speakTicketType != null &&
        ticketSeller.accessTicketType != ticketSeller.speakTicketType) {
      log.f('FIXME: we should show a dialog to ask which ticket to buy');
      Get.snackbar(
          "Update Required", "Please update the app to buy tickets about258");
      allUsersToBuyTicketFrom.value[ticketSeller.userInfo.id]!.buying = false;
      allUsersToBuyTicketFrom.refresh();
      return;
    }
    try {
      final groupAccessType = group.value!.accessType;
      final groupSpeakerType = group.value!.speakerType;
      final unsupportedAccessTicket = (groupAccessType !=
              BuyableTicketTypes.onlyArenaTicketHolders &&
          groupAccessType != BuyableTicketTypes.onlyFriendTechTicketHolders &&
          isAccessBuyableByTicket);
      final unsupportedSpeakTicket = (groupSpeakerType !=
              BuyableTicketTypes.onlyArenaTicketHolders &&
          groupSpeakerType != BuyableTicketTypes.onlyFriendTechTicketHolders &&
          isSpeakBuyableByTicket);

      if (unsupportedAccessTicket || unsupportedSpeakTicket) {
        log.f('FIXME: add support for other ticket types');
        Get.snackbar(
          "Update Required",
          "Please update the app to buy tickets",
          colorText: Colors.orange,
        );
        allUsersToBuyTicketFrom.value[ticketSeller.userInfo.id]!.buying = false;
        allUsersToBuyTicketFrom.refresh();
        return;
      }
      if (ticketSeller.shouldOnlyBuyOneTicket) {
        final ticketAccessType =
            ticketSeller.accessTicketType ?? ticketSeller.speakTicketType;

        if (ticketAccessType == BuyableTicketTypes.onlyArenaTicketHolders) {
          await buyTicketFromTicketSellerOnArena(ticketSeller: ticketSeller);
        } else if (ticketAccessType ==
            BuyableTicketTypes.onlyFriendTechTicketHolders) {
          await buyTicketFromTicketSellerOnFriendTech(
            ticketSeller: ticketSeller,
          );
        } else {
          log.f('FIXME: add support for other ticket types');
          Get.snackbar(
              "Update Required", "Please update the app to buy tickets");
          allUsersToBuyTicketFrom.value[ticketSeller.userInfo.id]!.buying =
              false;
          allUsersToBuyTicketFrom.refresh();
        }
      } else {
        Get.snackbar("Update required", "tickets are not on same chain");
      }
    } catch (e) {
    } finally {
      allUsersToBuyTicketFrom.value[ticketSeller.userInfo.id]!.buying = false;
      allUsersToBuyTicketFrom.refresh();
    }
  }

  Future<bool> buyTicketFromTicketSellerOnFriendTech({
    required TicketSeller ticketSeller,
  }) async {
    final selectedWallet = await choseAWallet(chainId: baseChainId);
    allUsersToBuyTicketFrom.value[ticketSeller.userInfo.id]!.buying = true;
    allUsersToBuyTicketFrom.refresh();
    if (selectedWallet == null) {
      allUsersToBuyTicketFrom.value[ticketSeller.userInfo.id]!.buying = false;
      allUsersToBuyTicketFrom.refresh();
      return false;
    }
    bool bought = false;
    if (selectedWallet == WalletNames.particle) {
      bought = await particle_buyFriendTechTicket(
        sharesSubject: ticketSeller.userInfo.defaultWalletAddress ?? '',
        // temp chainId hardcoded
        chainId: baseChainId,
      );
    } else {
      bought = await ext_buyFirendtechTicket(
        sharesSubject: ticketSeller.userInfo.defaultWalletAddress ?? '',
        // temp chainId hardcoded
        chainId: baseChainId,
        numberOfTickets: 1,
      );
    }
    allUsersToBuyTicketFrom.value[ticketSeller.userInfo.id]!.buying = false;
    if (ticketSeller.accessTicketType ==
            BuyableTicketTypes.onlyArenaTicketHolders ||
        ticketSeller.speakTicketType ==
            BuyableTicketTypes.onlyArenaTicketHolders) {
      allUsersToBuyTicketFrom
          .value[ticketSeller.userInfo.id]!.boughtTicketToAccess = bought;
    }
    if (ticketSeller.speakTicketType ==
            BuyableTicketTypes.onlyArenaTicketHolders ||
        ticketSeller.accessTicketType ==
            BuyableTicketTypes.onlyArenaTicketHolders) {
      allUsersToBuyTicketFrom
          .value[ticketSeller.userInfo.id]!.boughtTicketToSpeak = bought;
    }
    allUsersToBuyTicketFrom.refresh();
    return bought;
  }

  Future<bool> buyTicketFromTicketSellerOnArena({
    required TicketSeller ticketSeller,
  }) async {
    final selectedWallet = await choseAWallet(chainId: avalancheChainId);
    allUsersToBuyTicketFrom.value[ticketSeller.userInfo.id]!.buying = true;
    allUsersToBuyTicketFrom.refresh();
    if (selectedWallet == null) {
      allUsersToBuyTicketFrom.value[ticketSeller.userInfo.id]!.buying = false;
      allUsersToBuyTicketFrom.refresh();
      return false;
    }
    bool bought = false;
    if (selectedWallet == WalletNames.particle) {
      bought = await particle_buySharesWithReferrer(
        sharesSubject: ticketSeller.userInfo.defaultWalletAddress ?? '',
        chainId: externalWalletChianId,
      );
    } else {
      bought = await ext_buySharesWithReferrer(
        sharesSubject: ticketSeller.userInfo.defaultWalletAddress ?? '',
        chainId: externalWalletChianId,
      );
      log.d('bought: $bought');
    }
    allUsersToBuyTicketFrom.value[ticketSeller.userInfo.id]!.buying = false;
    if (ticketSeller.accessTicketType ==
        BuyableTicketTypes.onlyArenaTicketHolders) {
      allUsersToBuyTicketFrom
          .value[ticketSeller.userInfo.id]!.boughtTicketToAccess = bought;
    }
    if (ticketSeller.speakTicketType ==
        BuyableTicketTypes.onlyArenaTicketHolders) {
      allUsersToBuyTicketFrom
          .value[ticketSeller.userInfo.id]!.boughtTicketToSpeak = bought;
    }
    allUsersToBuyTicketFrom.refresh();
    return bought;
  }

  bool get isAccessBuyableByTicket {
    return accessIsBuyableByTicket(group.value!);
  }

  bool get isSpeakBuyableByTicket {
    return speakIsBuyableByTicket(group.value!);
  }

  bool get canSpeakWithoutATicket {
    return canISpeak(group: group.value!);
  }

  bool get canEnterWithoutTicket {
    final g = group.value!;
    return canEnterWithoutATicket(g);
  }

  Future<GroupAccesses> checkIfIveBoughtTheTicketFromUser(
    UserInfoModel user,
    String userId,
  ) async {
    final myUser = globalController.currentUserInfo.value!;
    if (userId == myUser.id)
      return GroupAccesses(canEnter: true, canSpeak: true);
    GroupAccesses access = GroupAccesses(canEnter: false, canSpeak: false);
    final List<Future> arrayToCall = [];
    if (allUsersToBuyTicketFrom.value[userId]?.accessTicketType != null) {
      if (group.value!.accessType ==
          BuyableTicketTypes.onlyArenaTicketHolders) {
        arrayToCall.add(particle_getMyShares_arena(
          sharesSubject: user.defaultWalletAddress ?? '',
          chainId: particleChianId,
        ));
      } else if (group.value!.accessType ==
          BuyableTicketTypes.onlyFriendTechTicketHolders) {
        arrayToCall.add(particle_getUserShares_friendTech(
          defaultWallet: user.defaultWalletAddress!,
          particleWallet: user.particleWalletAddress!,
          // chainId: particleChianId,
          //temporarlly use hadcoded chainId
          chainId: baseChainId,
        ));
      } else {
        log.f('FIXME: add support for other ticket types ');
      }
    }
    if (arrayToCall.isEmpty) {
      arrayToCall.add(Future(() => BigInt.zero));
    }

    if (allUsersToBuyTicketFrom.value[userId]?.speakTicketType != null) {
      if (group.value!.speakerType ==
          BuyableTicketTypes.onlyArenaTicketHolders) {
        arrayToCall.add(particle_getMyShares_arena(
          sharesSubject: user.defaultWalletAddress ?? '',
          chainId: particleChianId,
        ));
      } else if (group.value!.accessType ==
          BuyableTicketTypes.onlyFriendTechTicketHolders) {
        arrayToCall.add(particle_getUserShares_friendTech(
          defaultWallet: user.defaultWalletAddress!,
          particleWallet: user.particleWalletAddress!,
          chainId: baseChainId,
        ));
      } else {
        log.f('FIXME: add support for other ticket types');
      }
    }
    if (arrayToCall.length == 1) {
      arrayToCall.add(Future(() => BigInt.zero));
    }

    final results = await Future.wait(arrayToCall);
    final accessTicket = results[0] as BigInt?;
    if (accessTicket != null && accessTicket > BigInt.zero) {
      access.canEnter = true;
    }
    final speakTicket = results[1] as BigInt?;
    if (speakTicket != null && speakTicket > BigInt.zero) {
      access.canSpeak = true;
    }

    return access;
  }
}

accessIsBuyableByTicket(FirebaseGroup group) {
  final groupAccessType = group.accessType;
  return groupAccessType == BuyableTicketTypes.onlyArenaTicketHolders ||
      groupAccessType == BuyableTicketTypes.onlyFriendTechTicketHolders ||
      groupAccessType == BuyableTicketTypes.onlyPodiumPassHolders;
}

speakIsBuyableByTicket(FirebaseGroup group) {
  final groupSpeakType = group.speakerType;
  return groupSpeakType == BuyableTicketTypes.onlyArenaTicketHolders ||
      groupSpeakType == BuyableTicketTypes.onlyFriendTechTicketHolders ||
      groupSpeakType == BuyableTicketTypes.onlyPodiumPassHolders;
}

canEnterWithoutATicket(FirebaseGroup group) {
  final globalController = Get.find<GlobalController>();
  final g = group;
  final amIInvited = g.invitedMembers[myId] != null;
  final link = globalController.deepLinkRoute;
  final cameHereByLink = g.accessType == FreeRoomAccessTypes.onlyLink &&
      link != null &&
      link.isNotEmpty &&
      link.contains(g.id);
  if (g.accessType == FreeRoomAccessTypes.onlyLink) {
    return cameHereByLink;
  }
  if (g.accessType == FreeRoomAccessTypes.invitees) {
    return amIInvited;
  }
  if (g.accessType == FreeRoomAccessTypes.public) {
    return true;
  }
  return false;
}
