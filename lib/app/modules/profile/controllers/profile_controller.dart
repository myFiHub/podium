import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/usersParser.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/models/cheerBooEvent.dart';

import 'package:podium/models/user_info_model.dart';
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

class ProfileController extends GetxController
    with BlockChainInteractions, FireBaseUtils {
  final userInfo = Rxn<UserInfoModel>();
  final globalController = Get.find<GlobalController>();
  final groupsController = Get.find<GroupsController>();
  final connectedWallet = ''.obs;
  final isGettingTicketPrice = false.obs;
  final isBuyingArenaTicket = false.obs;
  final isBuyingFriendTechTicket = false.obs;
  final isFriendTechActive = false.obs;
  final friendTechPrice = 0.0.obs;
  final arenaTicketPrice = 0.0.obs;
  final activeFriendTechWallets = Rxn<UserActiveWalletOnFriendtech>();
  final loadingArenaPrice = false.obs;
  final loadingFriendTechPrice = false.obs;
  final mySharesOfFriendTechFromThisUser = 0.obs;
  final mySharesOfArenaFromThisUser = 0.obs;
  final isGettingPayments = false.obs;
  final payments = Rx(Payments());

  @override
  void onInit() {
    final stringedUserInfo = Get.parameters[UserProfileParamsKeys.userInfo]!;
    userInfo.value = singleUserParser(jsonDecode(stringedUserInfo));
    Future.wait<void>([getPrices(), _getPayments()]);
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  _getPayments() async {
    isGettingPayments.value = true;
    final (received, paid) = await (
      getReceivedPayments(
        userId: userInfo.value!.id,
      ),
      getInitiatedPayments(
        userId: userInfo.value!.id,
      )
    ).wait;
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
      // should not do these awaits together, since they are on different chains
      await getArenaPriceAndMyShares();
      await getFriendTechPriceAndMyShare();
      //
    } catch (e) {
      log.e('Error getting prices: $e');
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
      particle_friendTech_getActiveUserWallets(
        particleAddress: userInfo.value!.particleWalletAddress,
        chainId: baseChainId,
      ),
      particle_getUserShares_friendTech(
        defaultWallet: userInfo.value!.defaultWalletAddress,
        particleWallet: userInfo.value!.particleWalletAddress,
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
      final price = await particle_getFriendTechTicketPrice(
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
      particle_getBuyPrice(
        sharesSubject: userInfo.value!.defaultWalletAddress,
        shareAmount: 1,
        chainId: avalancheChainId,
      ),
      particle_getMyShares_arena(
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
      if (mySelectedWallet == WalletNames.particle) {
        bought = await particle_buyFriendTechTicket(
          sharesSubject: preferedAddress,
          chainId: baseChainId,
          targetUserId: userInfo.value!.id,
        );
      } else {
        bought = await ext_buyFirendtechTicket(
          sharesSubject: preferedAddress,
          chainId: baseChainId,
          targetUserId: userInfo.value!.id,
        );
      }
      if (bought) {
        mySharesOfFriendTechFromThisUser.value++;
        Get.snackbar('Success', 'Friendtech ticket bought',
            colorText: Colors.green);
        getFriendTechPriceAndMyShare(delay: 5);
      } else {
        Get.snackbar('Error', 'Error buying Friendtech ticket',
            colorText: Colors.red);
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
      if (mySelectedWallet == WalletNames.particle) {
        bought = await particle_buySharesWithReferrer(
          sharesSubject: userInfo.value!.defaultWalletAddress,
          chainId: avalancheChainId,
          targetUserId: userInfo.value!.id,
        );
      } else {
        bought = await ext_buySharesWithReferrer(
          sharesSubject: userInfo.value!.defaultWalletAddress,
          chainId: avalancheChainId,
          targetUserId: userInfo.value!.id,
        );
      }
      if (bought) {
        mySharesOfArenaFromThisUser.value++;
        Get.snackbar('Success', 'Arena ticket bought', colorText: Colors.green);
        getArenaPriceAndMyShares(delay: 5);
      } else {
        Get.snackbar('Error', 'Error buying Arena ticket',
            colorText: Colors.red);
      }
    } catch (e) {
    } finally {
      isBuyingArenaTicket.value = false;
    }
  }
}
