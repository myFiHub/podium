import 'dart:async';

import 'package:ably_flutter/ably_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:particle_auth_core/particle_auth_core.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingGroupCall/utils.dart';
import 'package:podium/app/modules/ongoingGroupCall/widgets/cheerBooBottomSheet.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/env.dart';
import 'package:podium/models/cheerBooEvent.dart';
import 'package:podium/models/firebase_Session_model.dart';
import 'package:podium/models/jitsi_member.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/logger.dart';

const likeDislikeTimeoutInMilliSeconds = 10 * 1000; // 10 seconds
const amountToAddForLikeInSeconds = 10; // 10 seconds
const amountToReduceForDislikeInSeconds = 10; // 10 seconds

class MyTalkTimer {
  int startedAt = DateTime.now().millisecondsSinceEpoch;
  int endedAt = 0;
  startTimer() {
    startedAt = DateTime.now().millisecondsSinceEpoch;
  }

  endTimer() {
    endedAt = DateTime.now().millisecondsSinceEpoch;
  }

  int get timeElapsedInSeconds {
    final elapsed =
        int.parse(((endedAt - startedAt) / 1000).toStringAsFixed(0));
    if (elapsed < 0) {
      return 0;
    }
    return elapsed;
  }
}

class InteractionKeys {
  static const action = 'action';
  static const initiatorId = 'initiatorId';
  static const targetId = 'targetId';
}

class Reaction {
  String targetId;
  String reaction;
  Reaction({required this.targetId, required this.reaction});
}

class ReactionLogElement {
  FirebaseSessionMember target;
  FirebaseSessionMember initiator;
  String reaction;
  int addedAt = DateTime.now().millisecondsSinceEpoch;

  ReactionLogElement({
    required this.target,
    required this.initiator,
    required this.reaction,
  });
}

class OngoingGroupCallController extends GetxController {
  final groupCallController = Get.find<GroupCallController>();
  final globalController = Get.find<GlobalController>();
  final firebaseSession = Rxn<FirebaseSession>();
  final mySession = Rxn<FirebaseSessionMember>();
  final jitsiMembers = Rxn<List<JitsiMember>>();
  final allRemainingTimesMap = Rx<Map<String, int>>({});
  final talkTimer = MyTalkTimer();
  final amIAdmin = false.obs;
  final remainingTimeTimer = (-1).obs;
  final amIMuted = true.obs;
  final timers = Rx<Map<String, int>>({});
  final talkingIds = Rx<List<String>>([]);

  final reactionLog = Rx<List<ReactionLogElement>>([]);

  final lastReaction = Rx<Reaction>(
    Reaction(targetId: '', reaction: ''),
  );
  StreamSubscription<DatabaseEvent>? sessionMembersSubscription = null;
  StreamSubscription<DatabaseEvent>? mySessionSubscription = null;
  StreamSubscription<PresenceMessage>? presenceUpdateStream = null;

  Timer? timer;

  @override
  void onInit() async {
    super.onInit();
    final ongoingGroupCallGroup = groupCallController.group.value!;

    final channel = realtimeInstance.channels.get(ongoingGroupCallGroup.id);
    presenceUpdateStream = channel.presence
        .subscribe(action: PresenceAction.update)
        .listen((message) {
      if (!(message.data is String)) {
        if (message.data is Map &&
            eventNames
                .isInteraction((message.data as Map)[InteractionKeys.action])) {
          final data = message.data as Map;
          final initiatorId = data[InteractionKeys.initiatorId];
          final targetId = data[InteractionKeys.targetId];
          final action = data[InteractionKeys.action];
          _handleInteractionEvent(
            action: action,
            initiatorId: initiatorId,
            targetId: targetId,
          );
        }
      }
    });

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
    sessionMembersSubscription = startListeningToSessionMembers(
      sessionId: ongoingGroupCallGroup.id,
      onData: (sessionMembers) {
        final Map<String, int> remainingTimeMap = {};
        final membersList = sessionMembers.values.toList();
        // sort based on last talking time to show the most recent talker first
        membersList
            .sort((a, b) => b.startedToTalkAt.compareTo(a.startedToTalkAt));
        // final talkingIdsList = membersList
        //     .where((element) => element.isTalking)
        //     .map((e) => e.id)
        //     .toList();
        // if (talkingIdsList.length != talkingIds.value.length) {
        //   talkingIds.value = talkingIdsList;
        //   final GroupCallController groupCallController =
        //       Get.find<GroupCallController>();
        //   groupCallController.updateTalkingMembers(
        //     ids: talkingIdsList,
        //   );
        // }
        sessionMembers.forEach((key, value) {
          remainingTimeMap[key] = value.remainingTalkTime;
        });
        allRemainingTimesMap.value.addAll(remainingTimeMap);
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
    presenceUpdateStream?.cancel();
    stopTheTimer();
    stopSubscriptions();
    mySession.value = null;
    firebaseSession.value = null;
    timer?.cancel();
    await jitsiMeet.hangUp();
  }

  _addToReactionLog({required ReactionLogElement element}) {
    // max length of reaction log is 5
    if (reactionLog.value.length >= 5) {
      reactionLog.value.removeAt(0);
    }
    reactionLog.value.add(element);
    reactionLog.refresh();
  }

  stopSubscriptions() {
    sessionMembersSubscription?.cancel();
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
            if (v == 0) {
              updateRemainingTimeInMySessionOnFirebase(v: v, userId: myId);
              t.cancel();
            } else {
              updateRemainingTimeInMySessionOnFirebase(v: v, userId: myId);
            }
          }
        } else {
          t.cancel();
        }
      });
    }
  }

  _handleInteractionEvent({
    required String action,
    required String initiatorId,
    required String targetId,
  }) {
    final initiatorUser = firebaseSession.value!.members[initiatorId];
    final targetUser = firebaseSession.value!.members[targetId];

    // final userWidgetLocation=
    // log.d(
    //     "action: $action, initiator: ${initiatorUser!.name}, target: ${targetUser!.name}");
    final element = ReactionLogElement(
      initiator: initiatorUser!,
      target: targetUser!,
      reaction: action,
    );
    _addToReactionLog(element: element);
    lastReaction.value = Reaction(targetId: targetId, reaction: action);
    update(['confetti' + targetId]);
    Future.delayed(Duration(milliseconds: 10), () {
      lastReaction.value = Reaction(targetId: '', reaction: '');
    });
    // lastReaction.value = Reaction(targetId: '', reaction: '');
    // final initiatorUser=groupCallController.
  }

  updateMyLastTalkingTime() async {
    final myUserId = globalController.currentUserInfo.value?.id;
    final group = groupCallController.group.value;
    if (group == null) {
      return;
    }
    final isGroupCallRegistered = Get.isRegistered<GroupCallController>();
    if (isGroupCallRegistered) {
      final GroupCallController groupCallController =
          Get.find<GroupCallController>();
      final canSpeak = groupCallController.canTalk.value;
      if (myUserId != null && canSpeak && amIMuted.value == false) {
        await setIsTalkingInSession(
          sessionId: firebaseSession.value!.id,
          userId: myUserId,
          isTalking: true,
          startedToTalkAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
    }
  }

  stopTheTimer() async {
    await setIsTalkingInSession(
      sessionId: firebaseSession.value!.id,
      userId: myId,
      isTalking: false,
    );
    timer?.cancel();
  }

  Future<void> addToTimer(
      {required int seconds, required String userId}) async {
    if (groupCallController.group.value == null) {
      Toast.error(message: "Unknown error, please join again");
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
      Toast.error(message: "Unknown error, please join again");
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
    sendGroupPeresenceEvent(
        groupId: groupCallController.group.value!.id,
        eventName: eventNames.like,
        eventData: {
          InteractionKeys.initiatorId: myId,
          InteractionKeys.targetId: userId,
          InteractionKeys.action: eventNames.like,
        });
    final myUser = globalController.currentUserInfo.value!;
    final key = generateKeyForStorageAndObserver(
      userId: userId,
      groupId: groupCallController.group.value!.id,
      like: true,
    );
    timers.value[key] = DateTime.now().millisecondsSinceEpoch +
        likeDislikeTimeoutInMilliSeconds;
    timers.refresh();
    await addToTimer(
      seconds: amountToAddForLikeInSeconds,
      userId: userId,
    );
    analytics.logEvent(
      name: 'like',
      parameters: {
        'targetUser': userId,
        'groupId': groupCallController.group.value!.id,
        'fromUser': myUser.id,
      },
    );
  }

  onDislikeClicked(String userId) async {
    sendGroupPeresenceEvent(
        groupId: groupCallController.group.value!.id,
        eventName: eventNames.dislike,
        eventData: {
          InteractionKeys.initiatorId: myId,
          InteractionKeys.targetId: userId,
          InteractionKeys.action: eventNames.dislike,
        });
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
    final myUser = globalController.currentUserInfo.value!;
    analytics.logEvent(
      name: 'dislike',
      parameters: {
        'targetUser': userId,
        'groupId': groupCallController.group.value!.id,
        'fromUser': myUser.id,
      },
    );
  }

  cheerBoo(
      {required String userId, required bool cheer, bool? fromMeetPage}) async {
    String? targetAddress;
    final bool canContinue = checkWalletConnected(
      afterConnection: () {
        cheerBoo(userId: userId, cheer: cheer);
      },
    );

    if (!canContinue) {
      Toast.error(
        title: "external wallet connection required",
        message: " please connect your wallet first",
      );
      return;
    }

    final userLocalWalletAddress = await getUserLocalWalletAddress(userId);
    if (userLocalWalletAddress != '') {
      targetAddress = userLocalWalletAddress;
    } else {
      final particleUserWallets = await getParticleAuthWalletsForUser(userId);
      if (particleUserWallets.length > 0) {
        targetAddress = particleUserWallets[0].address;
      }
    }

    if (canContinue && targetAddress != null && targetAddress != '') {
      List<String> receiverAddresses = [];
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
        Toast.error(
          title: "Error",
          message: "receiver wallet not found",
        );
        return;
      }
      final String? amount = fromMeetPage == true
          ? Env.minimumCheerBooAmount
          : await Get.bottomSheet(CheerBooBottomSheet(isCheer: cheer));
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
        Toast.error(
          title: "Error",
          message: "Amount is not a number",
        );
        return;
      }

      ///////////////////////
      /// TODO: add for particle when it is ready (issue is resolved on their side, issue 2)
      bool success = false;
      final selectedWallet =
          WalletNames.external; //choseWallet(movementChainId);
      if (selectedWallet == WalletNames.external) {
        success = await ext_cheerOrBoo(
          target: targetAddress,
          receiverAddresses: receiverAddresses,
          amount: parsedAmount,
          cheer: cheer,
          chainId: externalWalletChianId,
        );
      }

      if (success) {
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

        log.i("${cheer ? "Cheer" : "Boo"} successful");
        Toast.success(
          title: "Success",
          message: "${cheer ? "Cheer" : "Boo"} successful",
        );
        final eventString = cheer ? eventNames.cheer : eventNames.boo;
        sendGroupPeresenceEvent(
            groupId: groupCallController.group.value!.id,
            eventName: eventString,
            eventData: {
              InteractionKeys.initiatorId: myId,
              InteractionKeys.targetId: userId,
              InteractionKeys.action: eventString,
            });
        analytics.logEvent(name: 'cheerBoo', parameters: {
          'cheer': cheer,
          'amount': amount,
          'target': userId,
          'groupId': groupCallController.group.value!.id,
          'fromUser': myUser.id,
        });
        final particleAddress = await Evm.getAddress();
        saveNewPayment(
            event: PaymentEvent(
          amount: amount,
          chainId: movementChainId,
          type: cheer ? PaymentTypes.cheer : PaymentTypes.boo,
          initiatorAddress: selectedWallet == WalletNames.external
              ? externalWalletAddress!
              : particleAddress,
          targetAddress: targetAddress,
          initiatorId: myId,
          targetId: userId,
          groupId: groupCallController.group.value!.id,
          selfCheer: myId == userId,
          memberIds: myId == userId
              ? firebaseSession.value!.members.values.map((e) => e.id).toList()
              : null,
        ));
      } else {
        log.e("${cheer ? "Cheer" : "Boo"} failed");
        Toast.error(
          title: "Error",
          message: "${cheer ? "Cheer" : "Boo"} failed",
        );
      }
      ///////////////////////
    } else if (targetAddress == '' || targetAddress == null) {
      log.e("User has not connected wallet for some reason");
      Toast.error(
        title: "Error",
        message: "User has not connected wallet for some reason",
      );
      return;
    }
  }

  audioMuteChanged({required bool muted}) {
    final groupId = groupCallController.group.value!.id;
    if (muted) {
      stopTheTimer();
      amIMuted.value = true;
      talkTimer.endTimer();
      final elapsed = talkTimer.timeElapsedInSeconds;
      sendGroupPeresenceEvent(
          groupId: groupId, eventName: eventNames.notTalking);
      if (elapsed > 0) {
        analytics.logEvent(
          name: 'talked',
          parameters: {
            'timeInSeconds': elapsed,
            'userId': myId,
            'groupId': groupCallController.group.value!.id,
          },
        );
      }
    } else {
      final groupCreator = groupCallController.group.value!.creator.id;
      final remainingTime = remainingTimeTimer;
      if (remainingTime <= 0 && myId != groupCreator) {
        Toast.error(
          title: "You have ran out of time",
          message: "",
        );
        amIMuted.value = true;
        jitsiMeet.setAudioMuted(true);
        return;
      }
      sendGroupPeresenceEvent(groupId: groupId, eventName: eventNames.talking);
      amIMuted.value = false;
      jitsiMeet.setAudioMuted(false);

      startTheTimer();
      if (remainingTimeTimer > 0) {
        talkTimer.startTimer();
        updateMyLastTalkingTime();
      }
    }
    // log.d("audioMutedChanged: $muted");
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
