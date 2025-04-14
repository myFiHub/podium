import 'dart:convert';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/aptosClient.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/outpostDetail/controllers/outpost_detail_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/follow/follower.dart';
import 'package:podium/providers/api/podium/models/pass/buyer.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
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
  final isGettingPayments = false.obs;
  final payments = Rx(Payments());
  final loadingUserID = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final stringedUserInfo = Get.parameters[UserProfileParamsKeys.userInfo]!;
    userInfo.value = UserModel.fromJson(jsonDecode(stringedUserInfo));
    payments.value = Payments(
      numberOfCheersReceived: userInfo.value!.received_cheer_count,
      numberOfBoosReceived: userInfo.value!.received_boo_count,
      numberOfCheersSent: userInfo.value!.sent_cheer_count,
      numberOfBoosSent: userInfo.value!.sent_boo_count,
    );
    updateTheData();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  updateTheData() async {
    mySharesOfPodiumPassFromThisUser.value = 0;
    await Future.wait<void>([
      getPrices(),
      getFollowers(),
      getFollowings(),
      getPassBuyers(),
    ]);
  }

  getFollowers({bool silent = false}) async {
    if (!silent) {
      isGettingFollowers.value = true;
    }
    final followersList = await HttpApis.podium.getFollowersOfUser(
      uuid: userInfo.value!.uuid,
    );
    followers.value = followersList;
    if (!silent) {
      isGettingFollowers.value = false;
    }
  }

  getFollowings({bool silent = false}) async {
    if (!silent) {
      isGettingFollowings.value = true;
    }
    final followingsList = await HttpApis.podium.getFollowingsOfUser(
      uuid: userInfo.value!.uuid,
    );
    followings.value = followingsList;
    if (!silent) {
      isGettingFollowings.value = false;
    }
  }

  getUserInfo() async {
    final info = await HttpApis.podium.getUserData(userInfo.value!.uuid);
    if (info != null) {
      userInfo.value = info;
      payments.value = Payments(
        numberOfCheersReceived: info.received_cheer_count,
        numberOfBoosReceived: info.received_boo_count,
        numberOfCheersSent: info.sent_cheer_count,
        numberOfBoosSent: info.sent_boo_count,
      );
    }
  }

  openUserProfilePage({required String uuid}) async {
    if (uuid == userInfo.value!.uuid || loadingUserID != '') {
      return;
    }
    loadingUserID.value = uuid;
    final isMyUser = uuid == myId;
    if (isMyUser) {
      Navigate.to(
        type: NavigationTypes.toNamed,
        route: Routes.MY_PROFILE,
      );
      return;
    }
    final user = await HttpApis.podium.getUserData(uuid);
    if (user != null) {
      userInfo.value = user;
      await updateTheData();
    }

    loadingUserID.value = '';
  }

  updateMyFollowState(UserModel user) {
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

  alsoUpdateOutpostListMembersIfExists(String uuid) {
    if (Get.isRegistered<OutpostDetailController>()) {
      final outpostDetailController = Get.find<OutpostDetailController>();
      outpostDetailController.updatedFollowDataForMember(uuid);
    }
  }

  updateFollowState(FollowerModel user) {
    if (user.uuid == userInfo.value!.uuid) {
      userInfo.value = userInfo.value!.copyWith.followed_by_me(
        !user.followed_by_me,
      );
    }
    final indexOfUserInListOfFollowers = followers.value.indexWhere(
      (element) => element.uuid == user.uuid,
    );
    if (indexOfUserInListOfFollowers != -1) {
      followers.value[indexOfUserInListOfFollowers] =
          followers.value[indexOfUserInListOfFollowers].copyWith.followed_by_me(
        !user.followed_by_me,
      );
    }
    final indexOfUserInListOfFollowings = followings.value.indexWhere(
      (element) => element.uuid == user.uuid,
    );
    if (indexOfUserInListOfFollowings != -1) {
      followings.value[indexOfUserInListOfFollowings] = followings
          .value[indexOfUserInListOfFollowings].copyWith
          .followed_by_me(
        !user.followed_by_me,
      );
    }
    final indexOfUserInListOfPassBuyers = podiumPassBuyers.value.indexWhere(
      (element) => element.uuid == user.uuid,
    );
    if (indexOfUserInListOfPassBuyers != -1) {
      podiumPassBuyers.value[indexOfUserInListOfPassBuyers] = podiumPassBuyers
          .value[indexOfUserInListOfPassBuyers].copyWith
          .followed_by_me(
        !user.followed_by_me,
      );
    }
    followers.refresh();
    followings.refresh();
    podiumPassBuyers.refresh();
    alsoUpdateOutpostListMembersIfExists(user.uuid);
  }

  getPrices() async {
    try {
      if (userInfo.value == null) {
        return;
      }
      isGettingTicketPrice.value = true;
      await Future.wait<void>([
        // getFriendTechPriceAndMyShare(),
        // getArenaPriceAndMyShares(),
        getPodiumPassPriceAndMyShares(),
      ]);
      //
    } catch (e) {
      l.e('Error getting prices: $e');
    } finally {
      isGettingTicketPrice.value = false;
    }
  }

  getFriendTechPriceAndMyShare({int delay = 0}) async {
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

  getArenaPriceAndMyShares({int delay = 0}) async {
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

  getPodiumPassPriceAndMyShares({int delay = 0}) async {
    loadingPodiumPassPrice.value = true;
    if (delay > 0) {
      await Future.delayed(Duration(seconds: delay));
    }
    final (buyPrice, sellPrice, podiumPassShares) = await (
      AptosMovement.getTicketPriceForPodiumPass(
        sellerAddress: userInfo.value!.aptos_address!,
        numberOfTickets: 1,
      ),
      AptosMovement.getTicketSellPriceForPodiumPass(
        sellerAddress: userInfo.value!.aptos_address!,
        numberOfTickets: 1,
      ),
      AptosMovement.getMyBalanceOnPodiumPass(
        sellerAddress: userInfo.value!.aptos_address!,
      )
    ).wait;
    if (podiumPassShares != null) {
      if (podiumPassShares.toInt() > 0) {
        mySharesOfPodiumPassFromThisUser.value = podiumPassShares.toInt();
      }
    }
    loadingPodiumPassPrice.value = false;
    if (buyPrice != null && buyPrice != BigInt.zero) {
      //  price in aptos move
      podiumPassBuyPrice.value = buyPrice;
    }
    if (sellPrice != null && sellPrice != BigInt.zero) {
      //  price in aptos move
      podiumPassSellPrice.value = bigIntCoinToMoveOnAptos(sellPrice);
    }
  }

  sellPodiumPass() async {
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
        Toast.success(title: 'Success', message: 'Podium pass sold');
        mySharesOfPodiumPassFromThisUser.value--;

        getPassBuyers();

        getPodiumPassPriceAndMyShares(delay: 5);
      }
    } catch (e) {
      l.e(e);
    } finally {
      isSellingPodiumPass.value = false;
    }
  }

  buyPodiumPass() async {
    isBuyingPodiumPass.value = true;
    try {
      final price = await AptosMovement.getTicketPriceForPodiumPass(
        sellerAddress: userInfo.value!.aptos_address!,
        numberOfTickets: 1,
      );
      if (price == null) {
        Toast.error(title: 'Error', message: 'Error getting podium pass price');
        return;
      }
      final myReferrerUuid = userInfo.value!.referrer_user_uuid;
      String referrer = '';
      if (myReferrerUuid != null) {
        final myReferrer = await HttpApis.podium.getUserData(myReferrerUuid);
        referrer = myReferrer?.aptos_address ?? '';
      }

      final (success, hash) =
          await AptosMovement.buyTicketFromTicketSellerOnPodiumPass(
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
        Toast.success(title: 'Success', message: 'Podium pass bought');
        mySharesOfPodiumPassFromThisUser.value++;
        getPassBuyers();
        getPodiumPassPriceAndMyShares(delay: 5);
      } else {
        Toast.error(title: 'Error', message: 'Error buying podium pass');
      }
    } catch (e) {
      l.e(e);
    } finally {
      isBuyingPodiumPass.value = false;
    }
  }

  buyFriendTechTicket() async {
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
          title: 'Success',
          message: 'Bought Friendtech Key',
        );
        getFriendTechPriceAndMyShare(delay: 5);
      } else {
        Toast.error(
          title: 'Error',
          message: 'Error buying Friendtech key',
        );
      }
    } catch (e) {
    } finally {
      isBuyingFriendTechTicket.value = false;
    }
  }

  buyArenaTicket() async {
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
        Toast.success(title: 'Success', message: 'Arena ticket bought');
        getArenaPriceAndMyShares(delay: 5);
      } else {
        Toast.error(title: 'Error', message: 'Error buying Arena ticket');
      }
    } catch (e) {
    } finally {
      isBuyingArenaTicket.value = false;
    }
  }

  getPassBuyers() async {
    isGettingPassBuyers.value = true;
    final buyers = await HttpApis.podium.podiumPassBuyers(
      uuid: userInfo.value!.uuid,
    );
    podiumPassBuyers.value = buyers;
    isGettingPassBuyers.value = false;
  }
}
