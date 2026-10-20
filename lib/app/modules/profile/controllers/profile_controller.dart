import 'dart:convert';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/blockchain/blockchain.dart';
import 'package:podium/app/modules/global/utils/aptosClient.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/outpostDetail/controllers/outpost_detail_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/podium/models/follow/follower.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/pass/buyer.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/server_features.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';

class UserProfileParamsKeys {
  static const userInfo = 'userInfo';
}

class Payments {
  int numberOfCheersReceived = 0;
  int numberOfBoosReceived = 0;
  int numberOfCheersSent = 0;
  int numberOfBoosSent = 0;
  Payments(
      {this.numberOfCheersReceived = 0,
      this.numberOfBoosReceived = 0,
      this.numberOfCheersSent = 0,
      this.numberOfBoosSent = 0});
}

class ProfileController extends GetxController {
  final _userRepository = Get.find<UserRepository>();
  final userInfo = Rxn<UserModel>();
  final globalController = Get.find<GlobalController>();
  final groupsController = Get.find<OutpostsController>();
  final connectedWallet = ''.obs;
  final isGettingTicketPrice = false.obs;
  final isBuyingArenaTicket = false.obs;
  final isBuyingFriendTechTicket = false.obs;
  final isBuyingPodiumPass = false.obs;
  final isSellingPodiumPass = false.obs;
  final isFriendTechActive = false.obs;
  final friendTechPrice = 0.0.obs;
  final arenaTicketPrice = 0.0.obs;
  final podiumPassBuyPrice = 0.0.obs;
  final podiumPassSellPrice = 0.0.obs;
  final activeFriendTechWallets = Rxn<UserActiveWalletOnFriendtech>();
  final loadingArenaPrice = false.obs;
  final loadingFriendTechPrice = false.obs;
  final loadingPodiumPassPrice = false.obs;
  final mySharesOfFriendTechFromThisUser = 0.obs;
  final mySharesOfArenaFromThisUser = 0.obs;
  final mySharesOfPodiumPassFromThisUser = 0.obs;
  final followers = Rx<List<FollowerModel>>([]);
  final followings = Rx<List<FollowerModel>>([]);
  final podiumPassBuyers = Rx<List<PodiumPassBuyerModel>>([]);
  final isGettingFollowers = false.obs;
  final isGettingFollowings = false.obs;
  final isGettingPassBuyers = false.obs;
  final payments = Rx(Payments());
  final loadingUserID = ''.obs;

  /// The live outpost this user is hosting, if any.
  final liveOutpost = Rxn<OutpostModel>();

  /// Podium Pass trades go through the user's Aptos wallet.
  bool get hasPassWallet => userInfo.value?.aptos_address?.isNotEmpty ?? false;

  bool get followsMe => followings.value.any((f) => f.uuid == myId);

  /// Followers of this user that the viewer also follows.
  List<FollowerModel> get followersIFollow =>
      followers.value.where((f) => f.followed_by_me && f.uuid != myId).toList();

  @override
  void onInit() {
    super.onInit();
    final stringedUserInfo = Get.parameters[UserProfileParamsKeys.userInfo]!;
    _setUser(UserModel.fromJson(jsonDecode(stringedUserInfo)));
    updateTheData();
  }

  void _setUser(UserModel user) {
    userInfo.value = user;
    payments.value = Payments(
      numberOfCheersReceived: user.received_cheer_count,
      numberOfBoosReceived: user.received_boo_count,
      numberOfCheersSent: user.sent_cheer_count,
      numberOfBoosSent: user.sent_boo_count,
    );
  }

  Future<void> updateTheData({bool silent = false}) async {
    if (!silent) {
      mySharesOfPodiumPassFromThisUser.value = 0;
      podiumPassBuyPrice.value = 0;
      podiumPassSellPrice.value = 0;
      liveOutpost.value = null;
    }
    await Future.wait<void>([
      getPrices(),
      getFollowers(silent: silent),
      getFollowings(silent: silent),
      getPassBuyers(silent: silent),
      _loadLiveOutpost(),
    ]);
  }

  /// Pull-to-refresh: reloads everything without blanking what's shown.
  Future<void> refreshAll() async {
    await Future.wait<void>([
      getUserInfo(),
      updateTheData(silent: true),
    ]);
  }

  Future<void> _loadLiveOutpost() async {
    final features = Get.find<ServerFeatures>();
    if (!features.discovery.value) return;
    final uuid = userInfo.value!.uuid;
    try {
      final live = await Get.find<OutpostRepository>().getLiveOutposts(
        limit: 50,
      );
      if (uuid != userInfo.value?.uuid) return;
      liveOutpost.value = live
          .map((d) => d.outpost)
          .where((o) => o.creator_user_uuid == uuid)
          .firstOrNull;
    } catch (e) {
      l.e('Error loading live outpost: $e');
    }
  }

  Future<void> getFollowers({bool silent = false}) async {
    if (!silent) {
      isGettingFollowers.value = true;
    }
    final followersList = await _userRepository.getFollowersOfUser(
      uuid: userInfo.value!.uuid,
    );
    followers.value = followersList;
    if (!silent) {
      isGettingFollowers.value = false;
    }
  }

  Future<void> getFollowings({bool silent = false}) async {
    if (!silent) {
      isGettingFollowings.value = true;
    }
    final followingsList = await _userRepository.getFollowingsOfUser(
      uuid: userInfo.value!.uuid,
    );
    followings.value = followingsList;
    if (!silent) {
      isGettingFollowings.value = false;
    }
  }

  Future<void> getUserInfo() async {
    final info = await _userRepository.getUserData(userInfo.value!.uuid);
    if (info != null) _setUser(info);
  }

  Future<void> openUserProfilePage({required String uuid}) async {
    if (uuid == userInfo.value!.uuid || loadingUserID.value != '') {
      return;
    }
    if (uuid == myId) {
      Navigate.to(
        type: NavigationTypes.toNamed,
        route: Routes.MY_PROFILE,
      );
      return;
    }
    loadingUserID.value = uuid;
    try {
      final user = await _userRepository.getUserData(uuid);
      if (user != null) {
        _setUser(user);
        await updateTheData();
      }
    } finally {
      loadingUserID.value = '';
    }
  }

  void updateMyFollowState(UserModel user) {
    final opposite = user.followed_by_me != null ? !user.followed_by_me! : true;

    userInfo.value = userInfo.value!.copyWith.followed_by_me(opposite);
    final doIExistInFollowersList = followers.value.firstWhereOrNull(
      (element) => element.uuid == myId,
    );
    if (doIExistInFollowersList == null) {
      // add me on top of followers list
      followers.value = [
        FollowerModel(
            address: myUser.address,
            followed_by_me: opposite,
            image: myUser.image!,
            name: myUser.name!,
            uuid: myId),
        ...followers.value
      ];
    } else {
      // remove me from List of followers
      followers.value =
          followers.value.where((element) => element.uuid != myId).toList();
    }
    alsoUpdateOutpostListMembersIfExists(user.uuid);
    // is outpostDetails page  registered
  }

  void alsoUpdateOutpostListMembersIfExists(String uuid) {
    if (Get.isRegistered<OutpostDetailController>()) {
      final outpostDetailController = Get.find<OutpostDetailController>();
      outpostDetailController.updatedFollowDataForMember(uuid);
    }
  }

  /// Applies a follow or unfollow of [uuid] to every list on the page.
  void setFollowedByMe(String uuid, bool followed) {
    if (uuid == userInfo.value!.uuid) {
      userInfo.value = userInfo.value!.copyWith.followed_by_me(followed);
    }
    followers.value = [
      for (final f in followers.value)
        f.uuid == uuid ? f.copyWith.followed_by_me(followed) : f,
    ];
    followings.value = [
      for (final f in followings.value)
        f.uuid == uuid ? f.copyWith.followed_by_me(followed) : f,
    ];
    podiumPassBuyers.value = [
      for (final b in podiumPassBuyers.value)
        b.uuid == uuid ? b.copyWith.followed_by_me(followed) : b,
    ];
    alsoUpdateOutpostListMembersIfExists(uuid);
  }

  Future<void> getPrices() async {
    try {
      if (userInfo.value == null) {
        return;
      }
      isGettingTicketPrice.value = true;
      await Future.wait<void>([
        getPodiumPassPriceAndMyShares(),
      ]);
      //
    } catch (e) {
      l.e('Error getting prices: $e');
    } finally {
      isGettingTicketPrice.value = false;
    }
  }

  Future<void> getFriendTechPriceAndMyShare({int delay = 0}) async {
    loadingFriendTechPrice.value = true;
    if (delay > 0) {
      await Future.delayed(Duration(seconds: delay));
    }
    final (activeWallets, myShares) = await (
      internal_friendTech_getActiveUserWallets(
        internalWalletAddress: userInfo.value!.address,
        chainId: baseChainId,
      ),
      internal_getUserShares_friendTech(
        defaultWallet: userInfo.value!.defaultWalletAddress,
        internalWallet: userInfo.value!.address,
        chainId: baseChainId,
      )
    ).wait;
    if (myShares.toInt() > 0) {
      mySharesOfFriendTechFromThisUser.value = myShares.toInt();
    }
    activeFriendTechWallets.value = activeWallets;
    isFriendTechActive.value = activeWallets.hasActiveWallet;
    if (isFriendTechActive.value) {
      final preferedAddress = activeWallets.preferedWalletAddress;
      final price = await internal_getFriendTechTicketPrice(
        sharesSubject: preferedAddress,
        chainId: baseChainId,
      );
      if (price != null && price != BigInt.zero) {
        //  price in eth
        final priceInEth = price / BigInt.from(10).pow(18);
        friendTechPrice.value = priceInEth.toDouble();
      }
    }
    loadingFriendTechPrice.value = false;
  }

  Future<void> getArenaPriceAndMyShares({int delay = 0}) async {
    loadingArenaPrice.value = true;

    if (delay > 0) {
      await Future.delayed(Duration(seconds: delay));
    }
    final (price, arenaShares) = await (
      getBuyPriceForArenaTicket(
        sharesSubject: userInfo.value!.defaultWalletAddress,
        shareAmount: 1,
        chainId: avalancheChainId,
      ),
      getMyShares_arena(
        sharesSubject: userInfo.value!.defaultWalletAddress,
        chainId: avalancheChainId,
      )
    ).wait;
    if (arenaShares != null) {
      if (arenaShares.toInt() > 0) {
        mySharesOfArenaFromThisUser.value = arenaShares.toInt();
      }
    }
    if (price != null && price != BigInt.zero) {
      //  price in eth
      final priceInEth = price / BigInt.from(10).pow(18);
      arenaTicketPrice.value = priceInEth.toDouble();
    }
    loadingArenaPrice.value = false;
  }

  Future<void> getPodiumPassPriceAndMyShares({int delay = 0}) async {
    if (!hasPassWallet) return;
    final sellerAddress = userInfo.value!.aptos_address!;
    loadingPodiumPassPrice.value = true;
    if (delay > 0) {
      await Future.delayed(Duration(seconds: delay));
    }
    final (buyPrice, sellPrice, podiumPassShares) = await (
      AptosMovement.getTicketPriceForPodiumPass(
        sellerAddress: sellerAddress,
        numberOfTickets: 1,
      ),
      AptosMovement.getTicketSellPriceForPodiumPass(
        sellerAddress: sellerAddress,
        numberOfTickets: 1,
      ),
      AptosMovement.getMyBalanceOnPodiumPass(
        sellerAddress: sellerAddress,
      )
    ).wait;
    if (sellerAddress != userInfo.value?.aptos_address) {
      loadingPodiumPassPrice.value = false;
      return;
    }
    if (podiumPassShares != null) {
      if (podiumPassShares.toInt() > 0) {
        mySharesOfPodiumPassFromThisUser.value = podiumPassShares.toInt();
      }
    }
    loadingPodiumPassPrice.value = false;
    if (buyPrice != null && buyPrice != 0) {
      //  price in aptos move
      podiumPassBuyPrice.value = buyPrice;
    }
    if (sellPrice != null && sellPrice != BigInt.zero) {
      //  price in aptos move
      podiumPassSellPrice.value = bigIntCoinToMoveOnAptos(sellPrice);
    }
  }

  Future<void> sellPodiumPass() async {
    if (!hasPassWallet) return;
    isSellingPodiumPass.value = true;
    try {
      final (sold, hash) = await AptosMovement.sellTicketOnPodiumPass(
        sellerAddress: userInfo.value!.aptos_address!,
        sellerUuid: userInfo.value!.uuid,
        numberOfTickets: 1,
      );
      if (sold == null) {
        return;
      }
      if (sold == true) {
        Toast.success(message: 'Podium pass sold');
        mySharesOfPodiumPassFromThisUser.value--;

        getPassBuyers(silent: true);

        getPodiumPassPriceAndMyShares(delay: 5);
      }
    } catch (e) {
      l.e(e);
    } finally {
      isSellingPodiumPass.value = false;
    }
  }

  Future<void> buyPodiumPass() async {
    if (!hasPassWallet) return;
    isBuyingPodiumPass.value = true;
    try {
      final price = await AptosMovement.getTicketPriceForPodiumPass(
        sellerAddress: userInfo.value!.aptos_address!,
        numberOfTickets: 1,
      );
      if (price == null) {
        Toast.error(message: 'Error getting podium pass price');
        return;
      }
      final myReferrerUuid = userInfo.value!.referrer_user_uuid;
      String referrer = '';
      if (myReferrerUuid != null) {
        final myReferrer = await _userRepository.getUserData(myReferrerUuid);
        referrer = myReferrer?.aptos_address ?? '';
      }

      final (success, hash) = await AptosMovement.buyPodiumPassFromUser(
        sellerAddress: userInfo.value!.aptos_address!,
        sellerName: userInfo.value!.name ?? '',
        referrer: referrer,
        numberOfTickets: 1,
        sellerUuid: userInfo.value!.uuid,
      );
      if (success == null) {
        return;
      }
      if (success == true) {
        Toast.success(message: 'Podium pass bought');
        mySharesOfPodiumPassFromThisUser.value++;
        getPassBuyers(silent: true);
        getPodiumPassPriceAndMyShares(delay: 5);
      } else {
        Toast.error(message: 'Error buying podium pass');
      }
    } catch (e) {
      l.e(e);
    } finally {
      isBuyingPodiumPass.value = false;
    }
  }

  Future<void> buyFriendTechTicket() async {
    try {
      final activeWallets = activeFriendTechWallets.value!;
      final preferedAddress = activeWallets.preferedWalletAddress;
      final mySelectedWallet = await choseAWallet(chainId: baseChainId);
      if (mySelectedWallet == null) {
        return;
      }
      isBuyingFriendTechTicket.value = true;
      bool bought = false;
      if (mySelectedWallet == WalletNames.internal_EVM) {
        bought = await internal_buyFriendTechTicket(
          sharesSubject: preferedAddress,
          chainId: baseChainId,
          targetUserId: userInfo.value!.uuid,
        );
      } else {
        bought = await ext_buyFirendtechTicket(
          sharesSubject: preferedAddress,
          chainId: baseChainId,
          targetUserId: userInfo.value!.uuid,
        );
      }
      if (bought) {
        mySharesOfFriendTechFromThisUser.value++;
        Toast.success(
          message: 'Bought Friendtech Key',
        );
        getFriendTechPriceAndMyShare(delay: 5);
      } else {
        Toast.error(
          message: 'Error buying Friendtech key',
        );
      }
    } finally {
      isBuyingFriendTechTicket.value = false;
    }
  }

  Future<void> buyArenaTicket() async {
    try {
      final mySelectedWallet = await choseAWallet(chainId: avalancheChainId);
      if (mySelectedWallet == null) {
        return;
      }
      isBuyingArenaTicket.value = true;
      bool bought = false;
      if (mySelectedWallet == WalletNames.internal_EVM) {
        bought = await internal_buySharesWithReferrer(
          sharesSubject: userInfo.value!.defaultWalletAddress,
          chainId: avalancheChainId,
          targetUserId: userInfo.value!.uuid,
        );
      } else {
        bought = await ext_buySharesWithReferrer(
          sharesSubject: userInfo.value!.defaultWalletAddress,
          chainId: avalancheChainId,
          targetUserId: userInfo.value!.uuid,
        );
      }
      if (bought) {
        mySharesOfArenaFromThisUser.value++;
        Toast.success(message: 'Arena ticket bought');
        getArenaPriceAndMyShares(delay: 5);
      } else {
        Toast.error(message: 'Error buying Arena ticket');
      }
    } finally {
      isBuyingArenaTicket.value = false;
    }
  }

  Future<void> getPassBuyers({bool silent = false}) async {
    if (!silent) {
      isGettingPassBuyers.value = true;
    }
    final buyers = await _userRepository.podiumPassBuyers(
      uuid: userInfo.value!.uuid,
    );
    podiumPassBuyers.value = buyers;
    if (!silent) {
      isGettingPassBuyers.value = false;
    }
  }
}
