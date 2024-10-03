import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/utils/usersParser.dart';
import 'package:podium/contracts/chainIds.dart';

import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';

class UserProfileParamsKeys {
  static const userInfo = 'userInfo';
}

class ProfileController extends GetxController with BlockChainInteractions {
  final userInfo = Rxn<UserInfoModel>();
  final globalController = Get.find<GlobalController>();
  final connectedWallet = ''.obs;
  final isGettingTicketPrice = false.obs;
  final isBuyingArenaTicket = false.obs;
  final isBuyingFriendTechTicket = false.obs;
  final isFriendTechActive = false.obs;
  final friendTechPrice = 0.0.obs;
  final arenaTicketPrice = 0.0.obs;
  final activeFriendTechWallets = Rxn<UserActiveWalletOnFriendtech>();
  final mySharesOfFriendTechFromThisUser = 0.obs;
  final mySharesOfArenaFromThisUser = 0.obs;

  @override
  void onInit() {
    final stringedUserInfo = Get.parameters[UserProfileParamsKeys.userInfo]!;
    userInfo.value = singleUserParser(jsonDecode(stringedUserInfo));
    getPrices();
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

  getPrices() async {
    try {
      if (userInfo.value == null) {
        return;
      }
      isGettingTicketPrice.value = true;
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
    } catch (e) {
      log.e('Error getting prices: $e');
    } finally {
      isGettingTicketPrice.value = false;
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
      if (mySelectedWallet == WalletNames.particle) {
        bought = await particle_buyFriendTechTicket(
          sharesSubject: preferedAddress,
          chainId: baseChainId,
        );
      } else {
        bought = await ext_buyFirendtechTicket(
          sharesSubject: preferedAddress,
          chainId: baseChainId,
        );
      }
      if (bought) {
        Get.snackbar('Success', 'Friendtech ticket bought',
            colorText: Colors.green);
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
        );
      } else {
        bought = await ext_buySharesWithReferrer(
          sharesSubject: userInfo.value!.defaultWalletAddress,
          chainId: avalancheChainId,
        );
      }
      if (bought) {
        Get.snackbar('Success', 'Arena ticket bought', colorText: Colors.green);
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
