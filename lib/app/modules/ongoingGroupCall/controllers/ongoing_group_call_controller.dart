import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/ongoingGroupCall/utils.dart';
import 'package:podium/app/modules/ongoingGroupCall/widgets/cheerBooBottomSheet.dart';
import 'package:podium/env.dart';
import 'package:podium/models/firebase_Session_model.dart';
import 'package:podium/models/jitsi_member.dart';
import 'package:podium/utils/logger.dart';

const likeDislikeTimeoutInMilliSeconds = 10 * 1000; // 10 seconds
const amountToAddForLikeInSeconds = 10; // 10 seconds
const amountToReduceForDislikeInSeconds = 10; // 10 seconds

class OngoingGroupCallController extends GetxController
    with FireBaseUtils, BlockChainInteractions {
  final groupCallController = Get.find<GroupCallController>();
  final globalController = Get.find<GlobalController>();
  final firebaseSession = Rxn<FirebaseSession>();
  final mySession = Rxn<FirebaseSessionMember>();
  final jitsiMembers = Rxn<List<JitsiMember>>();
  final allRemainingTimesMap = Rx<Map<String, int>>({});
  final amIAdmin = false.obs;
  final remainingTimeTimer = (-1).obs;
  final amIMuted = true.obs;
  final timers = Rx<Map<String, int>>({});
  StreamSubscription<DatabaseEvent>? sessionTimersSubscription = null;
  StreamSubscription<DatabaseEvent>? mySessionSubscription = null;

  Timer? timer;

  @override
  void onInit() async {
    super.onInit();
    final ongoingGroupCallGroup = groupCallController.group.value!;
    final myUser = globalController.currentUserInfo.value!;
    if (myUser.id == ongoingGroupCallGroup.creator.id) {
      amIAdmin.value = true;
    }
    mySession.value = await getUserSessionData(
      groupId: ongoingGroupCallGroup.id,
      userId: myUser.id,
    );
    firebaseSession.value = await getSessionData(
      groupId: ongoingGroupCallGroup.id,
    );
    mySessionSubscription = startListeningToMyRemainingTalkingTime(
      groupId: ongoingGroupCallGroup.id,
      userId: myUser.id,
      onData: onRemainingTimeUpdate,
    );
    sessionTimersSubscription = startListeningToSessionTimers(
      sessionId: ongoingGroupCallGroup.id,
      onData: (d) {
        allRemainingTimesMap.value.addAll(d);
        allRemainingTimesMap.refresh();
      },
    );
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() async {
    super.onClose();
    stopTheTimer();
    stopSubscriptions();
    mySession.value = null;
    firebaseSession.value = null;
    timer?.cancel();
    await jitsiMeet.hangUp();
  }

  stopSubscriptions() {
    sessionTimersSubscription?.cancel();
    mySessionSubscription?.cancel();
  }

  onRemainingTimeUpdate(int? remainingTime) {
    log.d("remaining time is $remainingTime");
    remainingTimeTimer.value = remainingTime ?? 0;
    timer?.cancel();
    startTheTimer();
  }

  startTheTimer() {
    final latestSession = mySession.value;
    if (latestSession == null) {
      log.f("latest session is null");
      return;
    } else {
      // remaining talk time is in milliSeconds
      if (amIAdmin.value) {
        timer?.cancel();
        return;
      }
      if (remainingTimeTimer.value <= 0) {
        final meet = jitsiMeet;
        meet.setAudioMuted(true);
        return;
      }
      if (timer != null) {
        timer?.cancel();
      }
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (remainingTimeTimer.value > 0) {
          if (!amIMuted.value) {
            final v = remainingTimeTimer.value - 1000;
            remainingTimeTimer.value = v;
            final myUserId = globalController.currentUserInfo.value!.id;
            if (v == 0) {
              updateRemainingTimeInMySessionOnFirebase(v: v, userId: myUserId);
              t.cancel();
            } else {
              updateRemainingTimeInMySessionOnFirebase(v: v, userId: myUserId);
            }
          }
        } else {
          t.cancel();
        }
      });
    }
  }

  stopTheTimer() {
    timer?.cancel();
  }

  Future<void> addToTimer(
      {required int seconds, required String userId}) async {
    if (groupCallController.group.value == null) {
      Get.snackbar("Unknown error", "please join again");
      return;
    }
    final creatorId = groupCallController.group.value!.creator.id;
    if (creatorId == userId) {
      return;
    }
    log.d("adding ${seconds} seconds to ${userId}");
    final milliseconds = seconds * 1000;
    final remainingTalkTimeForUser = await getUserRemainingTalkTime(
      groupId: groupCallController.group.value!.id,
      userId: userId,
    );
    if (remainingTalkTimeForUser == null) {
      log.f("remaining talk time for user is null");
      return;
    } else {
      final v = remainingTalkTimeForUser + milliseconds;
      return await updateRemainingTimeInMySessionOnFirebase(
        v: v,
        userId: userId,
      );
    }
  }

  Future<void> reduceFromTimer(
      {required int seconds, required String userId}) async {
    if (groupCallController.group.value == null) {
      Get.snackbar("Unknown error", "please join again");
      return;
    }
    final creatorId = groupCallController.group.value!.creator.id;
    if (creatorId == userId) {
      return;
    }
    final milliseconds = seconds * 1000;
    final remainingTalkTimeForUser = await getUserRemainingTalkTime(
        groupId: groupCallController.group.value!.id, userId: userId);
    if (remainingTalkTimeForUser == null) {
      log.f("remaining talk time for user is null");
      return;
    }
    final v = remainingTalkTimeForUser - milliseconds;
    if (v <= 0) {
      stopTheTimer();
    }

    return updateRemainingTimeInMySessionOnFirebase(
        v: v <= 0 ? 0 : v, userId: userId);
  }

  Future<void> updateRemainingTimeInMySessionOnFirebase(
      {required int v, required String userId}) {
    final latestSession = mySession.value;
    if (latestSession == null) {
      log.f("latest session is null");
      return Future.value();
    } else {
      return updateRemainingTimeOnFirebase(
        newValue: v,
        groupId: groupCallController.group.value!.id,
        userId: userId,
      );
    }
  }

  onLikeClicked(String userId) async {
    log.d("Like clicked $userId");
    final key = generateKeyForStorageAndObserver(
        userId: userId,
        groupId: groupCallController.group.value!.id,
        like: true);
    timers.value[key] = DateTime.now().millisecondsSinceEpoch +
        likeDislikeTimeoutInMilliSeconds;
    timers.refresh();
    await addToTimer(
      seconds: amountToAddForLikeInSeconds,
      userId: userId,
    );
  }

  onDislikeClicked(String userId) async {
    log.d("Dislike clicked $userId");
    final key = generateKeyForStorageAndObserver(
        userId: userId,
        groupId: groupCallController.group.value!.id,
        like: false);
    timers.value[key] = DateTime.now().millisecondsSinceEpoch +
        likeDislikeTimeoutInMilliSeconds;
    timers.refresh();
    await reduceFromTimer(
      seconds: amountToReduceForDislikeInSeconds,
      userId: userId,
    );
  }

  cheerBoo({required String userId, required bool cheer}) async {
    late String targetAddress;
    final bool canContinue = checkWalletConnected(
      afterConnection: () {
        cheerBoo(userId: userId, cheer: cheer);
      },
    );

    if (!canContinue) {
      Get.snackbar(
        "external wallet connection required",
        "please connect your wallet first",
        colorText: Colors.orange,
      );
      return;
    }
    final particleUserWallets = await getParticleAuthWalletsForUser(userId);
    if (particleUserWallets.length > 0) {
      targetAddress = particleUserWallets[0].address;
    } else {
      targetAddress = await getUserLocalWalletAddress(userId);
    }

    if (canContinue && targetAddress != '') {
      late List<String> receiverAddresses;
      final myUser = globalController.currentUserInfo.value!;
      final myParticleUser = globalController.particleAuthUserInfo.value;
      if (myUser.localWalletAddress == targetAddress ||
          (myParticleUser != null &&
              myParticleUser.wallets![0].publicAddress == targetAddress)) {
        receiverAddresses = await getListOfUserWalletsPresentInSession(
          firebaseSession.value!.id,
        );
      } else {
        receiverAddresses = [targetAddress];
      }
      if (receiverAddresses.length == 0) {
        log.e("No wallets found in session");
        Get.snackbar("Error", "receiver wallet not found");
        return;
      }
      final String? amount =
          await Get.bottomSheet(CheerBooBottomSheet(isCheer: cheer));
      if (amount == null) {
        log.e("Amount not selected");
        return;
      }
      late double parsedAmount;
      late int finalAmountOfTimeToAdd;
      try {
        // check if amount is integer
        parsedAmount = double.parse(amount);
        final parsedMin = double.parse(Env.minimumCheerBooAmount);
        final divided = parsedAmount / parsedMin;
        final parsedMultiplier = double.parse(Env.cheerBooTimeMultiplication);
        finalAmountOfTimeToAdd = (divided * parsedMultiplier).toInt();
      } catch (e) {
        log.e("something went wrong parsing amount");
        Get.snackbar("Error", "Amount is not a number");
        return;
      }

      ///////////////////////
      final res = await cheerOrBoo(
        target: targetAddress,
        receiverAddresses: receiverAddresses,
        amount: parsedAmount,
        cheer: cheer,
      );
      if (res != null) {
        try {
          if ((res as String).startsWith('0x')) {
            log.d("Cheer successful, amount: $amount");
            log.d("final amount of time to add $finalAmountOfTimeToAdd");
            cheer
                ? addToTimer(
                    seconds: finalAmountOfTimeToAdd,
                    userId: userId,
                  )
                : reduceFromTimer(
                    seconds: finalAmountOfTimeToAdd,
                    userId: userId,
                  );
          }
        } catch (e) {
          log.e("Error updating remaining time");
        }
        log.i("Cheer successful");
        Get.snackbar("Success", "Cheer successful");
      } else {
        log.e("Cheer failed");
        Get.snackbar("Error", "Cheer failed");
      }
      ///////////////////////
    } else if (targetAddress == '') {
      log.e("User has not connected wallet for some reason");
      Get.snackbar("Error", "User has not connected wallet for some reason");
      return;
    }
  }

  checkWalletConnected({void Function()? afterConnection}) {
    final connectedWalletAddress =
        globalController.connectedWalletAddress.value;
    if (connectedWalletAddress == '') {
      globalController.connectToWallet(afterConnection: () {
        afterConnection!();
      });
      return false;
    }
    return true;
  }
}
