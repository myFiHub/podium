import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:ably_flutter/ably_flutter.dart';
import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/aptosClient.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getWeb3AuthWalletAddress.dart';
import 'package:podium/app/modules/global/utils/permissions.dart';
import 'package:podium/app/modules/ongoingGroupCall/utils.dart';
import 'package:podium/app/modules/ongoingGroupCall/widgets/cheerBooBottomSheet.dart';
import 'package:podium/contracts/chainIds.dart';
import 'package:podium/env.dart';
import 'package:podium/models/cheerBooEvent.dart';
import 'package:podium/models/firebase_Session_model.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:record/record.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

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
  BuildContext? contextForIntro;
  final shouldShowIntro = false.obs;
  bool introStartCalled = false;
  late TutorialCoachMark tutorialCoachMark;
  final muteUnmuteKey = GlobalKey();
  final timerKey = GlobalKey();
  final likeDislikeKey = GlobalKey();
  final cheerBooKey = GlobalKey();

  final storage = GetStorage();
  final groupCallController = Get.find<GroupCallController>();
  final globalController = Get.find<GlobalController>();
  final firebaseSession = Rxn<FirebaseSession>();
  final mySession = Rxn<FirebaseSessionMember>();
  final allRemainingTimesMap = Rx<Map<String, int>>({});
  final talkTimer = MyTalkTimer();
  final amIAdmin = false.obs;
  final remainingTimeTimer = (-1).obs;
  final amIMuted = true.obs;
  final isRecording = false.obs;
  final timers = Rx<Map<String, int>>({});
  final talkingIds = Rx<List<String>>([]);
  int _numberOfRecording = 0;
  AudioRecorder _recorder = AudioRecorder();

  final loadingWalletAddressForUser = RxList<String>([]);

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
        _parseReceivedSessionMembers(sessionMembers);
      },
    );
  }

  @override
  void onReady() async {
    super.onReady();
    // try {
    //   await Future.delayed(const Duration(seconds: 30));
    //   final ongoingGroupCallGroup = groupCallController.group.value!;
    //   final sessionMembers = await getSessionMembers(
    //     sessionId: ongoingGroupCallGroup.id,
    //   );
    //   _parseReceivedSessionMembers(sessionMembers);
    // } on Exception catch (e) {
    //   debugPrint('init() error: $e\n');
    // }
  }

  @override
  void onClose() async {
    super.onClose();
    stopRecording();
    presenceUpdateStream?.cancel();
    stopTheTimer();
    stopSubscriptions();
    mySession.value = null;
    firebaseSession.value = null;
    timer?.cancel();
    await jitsiMeet.hangUp();
  }

  _parseReceivedSessionMembers(
    Map<String, FirebaseSessionMember> sessionMembers,
  ) {
    final Map<String, int> remainingTimeMap = {};
    final membersList = sessionMembers.values.toList();
    // sort based on last talking time to show the most recent talker first
    membersList.sort((a, b) => b.startedToTalkAt.compareTo(a.startedToTalkAt));
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
  }

  startIntro() {
    if (storage.read(IntroStorageKeys.viewedOngiongCall) == null) {
      shouldShowIntro.value = true;
    } else {
      return;
    }
    final alreadyViewed = storage.read(IntroStorageKeys.viewedOngiongCall);
    if (
        //
        // true
        alreadyViewed == null
        //
        ) {
      // wait for the context to be ready
      Future.delayed(const Duration(seconds: 1)).then((v) {
        tutorialCoachMark = TutorialCoachMark(
          targets: _createTargets(),
          paddingFocus: 5,
          skipWidget: Button(
            size: ButtonSize.SMALL,
            type: ButtonType.outline,
            color: Colors.red,
            onPressed: () {
              saveIntroAsDone(true);
            },
            child: const Text("Finish"),
          ),
          opacityShadow: 0.5,
          imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          onFinish: () {
            saveIntroAsDone(true);
          },
          onSkip: () {
            saveIntroAsDone(true);
            return true;
          },
        );
        try {
          tutorialCoachMark.show(context: contextForIntro!);
        } catch (e) {
          l.e(e);
        }
      });
    }
  }

  void saveIntroAsDone(bool? setAsFinished) {
    if (setAsFinished == true) {
      storage.write(IntroStorageKeys.viewedOngiongCall, true);
    }
    shouldShowIntro.value = false;
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];
    targets.add(
      _createStep(
        targetId: muteUnmuteKey,
        text:
            "you can mute/unmute your microphone here, it will start/stop your talk timer",
      ),
    );
    targets.add(
      _createStep(
        targetId: timerKey,
        text:
            "this is your remaining talk time, it will be updated when you talk",
      ),
    );

    targets.add(
      _createStep(
        targetId: likeDislikeKey,
        text:
            " you can like/dislike other participants for free, it will add/remove time to/from their talk time",
      ),
    );
    targets.add(
      _createStep(
        targetId: cheerBooKey,
        text:
            "you can cheer/boo other participants for a fee, it will add/remove time to/from their talk time, you can also cheer yourself, if so, fee will be distributed among other participants",
        hasNext: false,
      ),
    );

    return targets;
  }

  _createStep({
    required GlobalKey targetId,
    required String text,
    bool hasNext = true,
  }) {
    return TargetFocus(
      identify: targetId.toString(),
      keyTarget: targetId,
      alignSkip: Alignment.bottomRight,
      paddingFocus: 0,
      focusAnimationDuration: const Duration(milliseconds: 300),
      unFocusAnimationDuration: const Duration(milliseconds: 100),
      shape: ShapeLightFocus.RRect,
      color: Colors.black,
      enableOverlayTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
                if (hasNext)
                  Button(
                    size: ButtonSize.SMALL,
                    type: ButtonType.outline,
                    color: Colors.white,
                    onPressed: () {
                      tutorialCoachMark.next();
                    },
                    child: const Text(
                      "Next",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else
                  Button(
                    size: ButtonSize.SMALL,
                    type: ButtonType.outline,
                    color: Colors.white,
                    onPressed: () {
                      introFinished(true);
                    },
                    child: const Text(
                      "Finish",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void introFinished(bool? setAsFinished) {
    saveIntroAsDone(setAsFinished);
    try {
      tutorialCoachMark.finish();
      shouldShowIntro.value = false;
    } catch (e) {}
  }

  setMutedState(bool muted) {
    jitsiMeet.setAudioMuted(muted);
  }

  startRecording() {
    _setIsRecording(true);
  }

  stopRecording() {
    _setIsRecording(false);
  }

  Future<void> recordFile(
      AudioRecorder recorder, RecordConfig config, String path) async {
    await recorder.start(config, path: path);
  }

  _setIsRecording(bool recording) async {
    _recorder = AudioRecorder();

    final group = groupCallController.group.value!;
    final recordingName =
        'Podium Outpost record-${group.name}${_numberOfRecording == 0 ? '' : '-${_numberOfRecording}'}';
    final hasPermissionForAudio = await getPermission(Permission.microphone);
    if (!hasPermissionForAudio) {
      return;
    }
    Directory downloadDirectory = await getDownloadDirectory();
    String path =
        '${downloadDirectory.path}/${recordingName}-${DateTime.now().millisecondsSinceEpoch}.m4a'
            .replaceAll(':', '');

    if (recording) {
      _numberOfRecording++;
      if (await _recorder.hasPermission()) {
        try {
          const encoder = AudioEncoder.aacLc;

          const config = RecordConfig(encoder: encoder, numChannels: 1);
          await recordFile(_recorder, config, path);
          // await _recorder.start(const RecordConfig(), path: '${path}');
          Toast.success(
            title: "Recording started",
            message: "Recording started",
          );
        } catch (e) {
          _numberOfRecording--;
          Toast.error(
            title: "Error",
            message: "Error starting recording",
          );
          l.e("error starting recording: $e");
          isRecording.value = false;
          return;
        }
      } else {
        Toast.error(
          title: "Error",
          message: "Permission denied",
        );
      }
    } else {
      if (isRecording.value) {
        try {
          final path = await _recorder.stop();
          l.d("path is $path");
          _recorder.dispose();

          Toast.success(
            title: "Recording saved",
            message: "Recording saved into Downloads folder",
            duration: 5,
          );
          // await Share.shareXFiles(
          //   [XFile(path)],
          //   text: 'Podium: ${recordingName}',
          // );
        } catch (e) {
          l.e("error stopping recording: $e");
        }
      }
    }
    isRecording.value = recording;
  }

  stopSubscriptions() {
    sessionMembersSubscription?.cancel();
    mySessionSubscription?.cancel();
  }

  onRemainingTimeUpdate(int? remainingTime) {
    l.d("remaining time is $remainingTime");
    remainingTimeTimer.value = remainingTime ?? 0;
    timer?.cancel();
    startTheTimer();
  }

  startTheTimer() {
    final latestSession = mySession.value;
    if (latestSession == null) {
      l.f("latest session is null");
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
    lastReaction.value = Reaction(targetId: targetId, reaction: action);
    update(['confetti' + targetId]);
    Future.delayed(const Duration(milliseconds: 10), () {
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
    if (firebaseSession.value != null) {
      await setIsTalkingInSession(
        sessionId: firebaseSession.value!.id,
        userId: myId,
        isTalking: false,
      );
    }
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
    l.d("adding ${seconds} seconds to ${userId}");
    final milliseconds = seconds * 1000;
    final remainingTalkTimeForUser = await getUserRemainingTalkTime(
      groupId: groupCallController.group.value!.id,
      userId: userId,
    );
    if (remainingTalkTimeForUser == null) {
      l.f("remaining talk time for user is null");
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
      l.f("remaining talk time for user is null");
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
      l.f("latest session is null");
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

  _removeLoadingCheerBoo({
    required String userId,
    required bool cheer,
  }) {
    loadingWalletAddressForUser.remove("$userId-${cheer ? 'cheer' : 'boo'}");
    loadingWalletAddressForUser.refresh();
  }

  cheerBoo(
      {required String userId, required bool cheer, bool? fromMeetPage}) async {
    String? targetAddress;
    loadingWalletAddressForUser.add("$userId-${cheer ? 'cheer' : 'boo'}");
    loadingWalletAddressForUser.refresh();
    final user = await getUserById(userId);
    if (user == null) {
      l.e("user is null");
      return;
    }
    if (user.evm_externalWalletAddress != '') {
      targetAddress = user.evm_externalWalletAddress;
    } else {
      final internalWalletAddress = await getUserInternalWalletAddress(userId);
      targetAddress = internalWalletAddress;
    }

    l.d("target address is $targetAddress for user $userId");
    if (targetAddress != '') {
      List<String> receiverAddresses = [];
      List<String> aptosReceiverAddresses = [];
      final myUser = globalController.currentUserInfo.value!;
      if (myUser.evm_externalWalletAddress == targetAddress ||
          (myUser.evmInternalWalletAddress == targetAddress)) {
        final members = await getListOfUserWalletsPresentInSession(
          firebaseSession.value!.id,
        );
        final liveMemberIds =
            groupCallController.sortedMembers.value.map((e) => e.id).toList();
        members.forEach((element) {
          if (liveMemberIds.contains(element.id)) {
            if (element != targetAddress) {
              aptosReceiverAddresses.add(element.aptosInternalWalletAddress);
              if (element.evm_externalWalletAddress.isNotEmpty) {
                receiverAddresses.add(user.evm_externalWalletAddress);
              } else {
                receiverAddresses.add(user.evmInternalWalletAddress);
              }
            }
          }
        });
      } else {
        receiverAddresses = [targetAddress];
      }
      if (receiverAddresses.length == 0) {
        l.e("No Users found in session");
        Toast.error(
          title: "Error",
          message: "No Users found in session",
        );

        _removeLoadingCheerBoo(userId: userId, cheer: cheer);
        return;
      }
      final String? amount = fromMeetPage == true
          ? Env.minimumCheerBooAmount.toString()
          : await Get.bottomSheet(CheerBooBottomSheet(isCheer: cheer));
      if (amount == null) {
        l.e("Amount not selected");

        _removeLoadingCheerBoo(userId: userId, cheer: cheer);
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
        l.e("something went wrong parsing amount");
        Toast.error(
          title: "Error",
          message: "Amount is not a number",
        );

        _removeLoadingCheerBoo(userId: userId, cheer: cheer);
        return;
      }

      bool? success;
      final selectedWallet = WalletNames.internal_Aptos;
      // await choseAWallet(
      //   chainId: movementEVMChain.chainId,
      //   supportsAptos: true,
      // );
      if (selectedWallet == WalletNames.external) {
        success = await ext_cheerOrBoo(
          groupId: groupCallController.group.value!.id,
          target: targetAddress,
          receiverAddresses: receiverAddresses,
          amount: parsedAmount.abs(),
          cheer: cheer,
          chainId: movementEVMChain.chainId,
        );
      } else if (selectedWallet == WalletNames.internal_EVM) {
        success = await internal_cheerOrBoo(
          groupId: groupCallController.group.value!.id,
          user: user,
          target: targetAddress,
          receiverAddresses: receiverAddresses,
          amount: parsedAmount.abs(),
          cheer: cheer,
          chainId: movementEVMChain.chainId,
        );
      } else if (selectedWallet == WalletNames.internal_Aptos) {
        success = await AptosMovement.cheerBoo(
          groupId: groupCallController.group.value!.id,
          target: user.aptosInternalWalletAddress,
          receiverAddresses: aptosReceiverAddresses,
          amount: parsedAmount.abs(),
          cheer: cheer,
        );
      }
      // success null means error is handled inside called function
      if (success == null) {
        return;
      }
      if (success) {
        _removeLoadingCheerBoo(userId: userId, cheer: cheer);
        cheer
            ? addToTimer(
                seconds: finalAmountOfTimeToAdd.abs(),
                userId: userId,
              )
            : reduceFromTimer(
                seconds: finalAmountOfTimeToAdd.abs(),
                userId: userId,
              );

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
          'cheer': cheer.toString(),
          'amount': amount,
          'target': userId,
          'groupId': groupCallController.group.value!.id,
          'fromUser': myUser.id,
        });
        final internalWalletAddress =
            await web3AuthWalletAddress(); //await Evm.getAddress();
        if (internalWalletAddress == null) {
          l.e("podium address is null");
          return;
        }
        saveNewPayment(
            event: PaymentEvent(
          amount: amount,
          chainId: selectedWallet == WalletNames.internal_Aptos
              ? movementAptosChainId
              : movementEVMChain.chainId,
          type: cheer ? PaymentTypes.cheer : PaymentTypes.boo,
          initiatorAddress: selectedWallet == WalletNames.external
              ? externalWalletAddress!
              : internalWalletAddress,
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
        l.e("${cheer ? "Cheer" : "Boo"} failed");
        Toast.error(
          title: "Error",
          message: "${cheer ? "Cheer" : "Boo"} failed",
        );

        _removeLoadingCheerBoo(userId: userId, cheer: cheer);
      }
      ///////////////////////
    } else if (targetAddress == '') {
      l.e("User has not connected wallet for some reason");
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
