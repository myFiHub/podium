import 'dart:convert';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/aptosClient.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/models/cheerBooEvent.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

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
  final isFriendTechActive = false.obs;
  final friendTechPrice = 0.0.obs;
  final arenaTicketPrice = 0.0.obs;
  final podiumPassPrice = 0.0.obs;
  final podiumPassSellPrice = 0.0.obs;
  final activeFriendTechWallets = Rxn<UserActiveWalletOnFriendtech>();
  final loadingArenaPrice = false.obs;
  final loadingFriendTechPrice = false.obs;
  final loadingPodiumPassPrice = false.obs;
  final mySharesOfFriendTechFromThisUser = 0.obs;
  final mySharesOfArenaFromThisUser = 0.obs;
  final mySharesOfPodiumPassFromThisUser = 0.obs;
  final isGettingPayments = false.obs;
  final payments = Rx(Payments());

  @override
  void onInit() {
    super.onInit();
    final stringedUserInfo = Get.parameters[UserProfileParamsKeys.userInfo]!;
    userInfo.value = UserModel.fromJson(jsonDecode(stringedUserInfo));
    Future.wait<void>([getPrices(), _getPayments()]);
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  updateUserInfo() async {
    final info = await HttpApis.podium.getUserData(userInfo.value!.uuid);
    if (info != null) {
      userInfo.value = info;
    }
  }

  _getPayments() async {
    isGettingPayments.value = true;
    final (received, paid) = (
      [], []
      // getReceivedPayments(
      //   userId: userInfo.value!.uuid,
      // ),
      // getInitiatedPayments(
      //   userId: userInfo.value!.uuid,
      // )
    );
    final _payments = Payments(
      numberOfCheersReceived: 0,
      numberOfBoosReceived: 0,
      numberOfCheersSent: 0,
      numberOfBoosSent: 0,
    );

    received.forEach((element) {
      if (element.type == PaymentTypes.cheer) {
        _payments.numberOfCheersReceived++;
      } else if (element.type == PaymentTypes.boo) {
        _payments.numberOfBoosReceived++;
      }
    });
    paid.forEach((element) {
      if (element.type == PaymentTypes.cheer) {
        _payments.numberOfCheersSent++;
      } else if (element.type == PaymentTypes.boo) {
        _payments.numberOfBoosSent++;
      }
    });
    isGettingPayments.value = false;
    payments.value = _payments;
    payments.refresh();
  }

  getPrices() async {
    try {
      if (userInfo.value == null) {
        return;
      }
      isGettingTicketPrice.value = true;
      await Future.wait<void>([
        getFriendTechPriceAndMyShare(),
        getArenaPriceAndMyShares(),
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
    final (price, sellPrice, podiumPassShares) = await (
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
    if (price != null && price != BigInt.zero) {
      //  price in aptos move
      podiumPassPrice.value = price;
    }
    if (sellPrice != null && sellPrice != BigInt.zero) {
      //  price in aptos move
      podiumPassSellPrice.value = bigIntCoinToMoveOnAptos(sellPrice);
    }
  }

  buyOrSellPodiumPass() async {
    isBuyingPodiumPass.value = true;
    final myShares = mySharesOfPodiumPassFromThisUser.value;
    if (myShares > 0) {
      // _sellPodiumPass();
      _buyPodiumPass();
    } else {
      _buyPodiumPass();
    }
  }

  _sellPodiumPass() async {
    try {
      final sold = await AptosMovement.sellTicketOnPodiumPass(
        sellerAddress: userInfo.value!.aptos_address!,
        numberOfTickets: 1,
      );
      if (sold == null) {
        return;
      }
      if (sold == true) {
        Toast.success(title: 'Success', message: 'Podium pass sold');
        mySharesOfPodiumPassFromThisUser.value--;
      }
    } catch (e) {
      l.e(e);
    } finally {
      isBuyingPodiumPass.value = false;
      getPodiumPassPriceAndMyShares(delay: 5);
    }
  }

  _buyPodiumPass() async {
    try {
      final price = await AptosMovement.getTicketPriceForPodiumPass(
        sellerAddress: userInfo.value!.aptos_address!,
        numberOfTickets: 1,
      );
      if (price == null) {
        Toast.error(title: 'Error', message: 'Error getting podium pass price');
        return;
      }
      podiumPassPrice.value = price;
      final success = await AptosMovement.buyTicketFromTicketSellerOnPodiumPass(
        sellerAddress: userInfo.value!.aptos_address!,
        sellerName: userInfo.value!.name ?? '',
        numberOfTickets: 1,
      );
      if (success == null) {
        return;
      }
      if (success == true) {
        Toast.success(title: 'Success', message: 'Podium pass bought');
        mySharesOfPodiumPassFromThisUser.value++;
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
}
