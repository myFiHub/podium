import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:ably_flutter/ably_flutter.dart';
import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/aptosClient.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getWeb3AuthWalletAddress.dart';
import 'package:podium/app/modules/global/utils/permissions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/utils.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/cheerBooBottomSheet.dart';
import 'package:podium/env.dart';
import 'package:podium/models/cheerBooEvent.dart';
import 'package:podium/models/firebase_Session_model.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/services/websocket/incomingMessage.dart';
import 'package:podium/services/websocket/outgoingMessage.dart';
import 'package:podium/utils/analytics.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:record/record.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

const likeDislikeTimeoutInMilliSeconds = 10 * 1000; // 10 seconds
const amountToAddForLikeInSeconds = 10; // 10 seconds
const amountToReduceForDislikeInSeconds = 10; // 10 seconds

class Reaction {
  String targetId;
  IncomingMessageType reaction;
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

class OngoingOutpostCallController extends GetxController {
  BuildContext? contextForIntro;
  final shouldShowIntro = false.obs;
  bool introStartCalled = false;
  late TutorialCoachMark tutorialCoachMark;
  final muteUnmuteKey = GlobalKey();
  final timerKey = GlobalKey();
  final likeDislikeKey = GlobalKey();
  final cheerBooKey = GlobalKey();
  final storage = GetStorage();
  final outpostCallController = Get.find<OutpostCallController>();
  final globalController = Get.find<GlobalController>();
  final sessionData = Rxn<OutpostLiveData>();
  final allRemainingTimesMap = Rx<Map<String, int>>({});
  final members = Rx<List<LiveMember>>([]);
  final mySession = Rxn<LiveMember>();
  final amIAdmin = false.obs;
  final amIMuted = true.obs;
  final isRecording = false.obs;
  final timers = Rx<Map<String, int>>({});
  final talkingIds = Rx<List<String>>([]);
  int _numberOfRecording = 0;
  AudioRecorder _recorder = AudioRecorder();

  final loadingWalletAddressForUser = RxList<String>([]);

  final lastReaction = Rx<Reaction>(
    Reaction(targetId: '', reaction: IncomingMessageType.userStoppedSpeaking),
  );

  StreamSubscription<List<LiveMember>>? membersListener;

  @override
  void onInit() async {
    super.onInit();
    final ongoingOutpost = outpostCallController.outpost.value!;
    final myUser = globalController.myUserInfo.value!;
    if (myUser.uuid == ongoingOutpost.creator_user_uuid) {
      amIAdmin.value = true;
    }
  }

  @override
  void onReady() async {
    super.onReady();

    membersListener = outpostCallController.members.listen((listOfMembers) {
      members.value = [...listOfMembers];
      final my_user =
          listOfMembers.where((m) => m.uuid == myUser.uuid).toList();
      if (my_user.length == 0) return;
      mySession.value = (my_user[0]);
      mySession.refresh();
      if (mySession.value!.remaining_time <= 0) {
        jitsiMeet.setAudioMuted(true);
      }
    });
  }

  @override
  void onClose() async {
    super.onClose();
    stopRecording();
    membersListener?.cancel();
    sessionData.value = null;
    await jitsiMeet.hangUp();
  }

  updateUserRemainingTime(
      {required String address, required int newTimeInSeconds}) {
    outpostCallController.updateUserTime(
      address: address,
      newTime: newTimeInSeconds,
    );
  }

  updateUserIsTalking({required String address, required bool isTalking}) {
    outpostCallController.updateUserIsTalking(
      address: address,
      isTalking: isTalking,
    );
  }

  handleTimeIsUp(IncomingMessage incomingMessage) {
    final address = incomingMessage.data.address!;
    if (address == myUser.address) {
      jitsiMeet.setAudioMuted(true);
    }
  }

  handleIncomingReaction(IncomingMessage incomingMessage) {
    final members = outpostCallController.members.value;
    final targetUserIndex = members.indexWhere(
        (item) => item.address == incomingMessage.data.react_to_user_address);
    final initiatorUserIndex = members
        .indexWhere((item) => item.address == incomingMessage.data.address);
    if (targetUserIndex == -1 || initiatorUserIndex == -1) return;
    final targetUser = members[targetUserIndex];
    final initiatorUser = members[initiatorUserIndex];
    handleInteractionEvent(
      action: incomingMessage.name,
      initiatorId: initiatorUser.uuid,
      targetId: targetUser.uuid,
    );
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

  LiveMember _getUserById({required String id}) {
    final membersList = members.value;
    return membersList.firstWhere((m) => m.uuid == id);
  }

  Future<void> recordFile(
      AudioRecorder recorder, RecordConfig config, String path) async {
    await recorder.start(config, path: path);
  }

  _setIsRecording(bool recording) async {
    _recorder = AudioRecorder();

    final outpost = outpostCallController.outpost.value!;
    final recordingName =
        'Podium Outpost record-${outpost.name}${_numberOfRecording == 0 ? '' : '-${_numberOfRecording}'}';
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

  handleInteractionEvent({
    required IncomingMessageType action,
    required String initiatorId,
    required String targetId,
  }) {
    lastReaction.value = Reaction(targetId: targetId, reaction: action);
    update(['confetti' + targetId]);
    Future.delayed(const Duration(milliseconds: 10), () {
      lastReaction.value = Reaction(
          targetId: '', reaction: IncomingMessageType.userStoppedSpeaking);
    });
    // lastReaction.value = Reaction(targetId: '', reaction: '');
    // final initiatorUser=groupCallController.
  }

  onLikeClicked({required String userId}) async {
    final user = _getUserById(id: userId);
    sendOutpostEvent(
      outpostId: outpostCallController.outpost.value!.uuid,
      eventType: OutgoingMessageTypeEnums.like,
      eventData: WsOutgoingMessageData(
        amount: null,
        react_to_user_address: user.address,
      ),
    );
    final key = generateKeyForStorageAndObserver(
      userId: userId,
      groupId: outpostCallController.outpost.value!.uuid,
      like: true,
    );
    timers.value[key] = DateTime.now().millisecondsSinceEpoch +
        likeDislikeTimeoutInMilliSeconds;
    timers.refresh();
  }

  onDislikeClicked({required String userId}) async {
    final user = _getUserById(id: userId);

    sendOutpostEvent(
      outpostId: outpostCallController.outpost.value!.uuid,
      eventType: OutgoingMessageTypeEnums.dislike,
      eventData: WsOutgoingMessageData(
        amount: null,
        react_to_user_address: user.address,
      ),
    );

    final key = generateKeyForStorageAndObserver(
        userId: userId,
        groupId: outpostCallController.outpost.value!.uuid,
        like: false);
    timers.value[key] = DateTime.now().millisecondsSinceEpoch +
        likeDislikeTimeoutInMilliSeconds;
    timers.refresh();
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
    final user = await HttpApis.podium.getUserData(userId);
    if (user == null) {
      l.e("user is null");
      return;
    }
    if (user.external_wallet_address != '') {
      targetAddress = user.external_wallet_address;
    } else {
      targetAddress = user.address;
    }

    l.d("target address is $targetAddress for user $userId");
    if (targetAddress != '') {
      List<String> receiverAddresses = [];
      List<String> aptosReceiverAddresses = [];
      final myUser = globalController.myUserInfo.value!;
      if (myUser.external_wallet_address == targetAddress ||
          (myUser.address == targetAddress)) {
        final liveData = await HttpApis.podium.getLatestLiveData(
          outpostId: outpostCallController.outpost.value!.uuid,
        );
        if (liveData == null) {
          l.e("live data is null");
          return;
        }
        final liveMembers = liveData.members.where((m) => m.is_present == true);
        final liveMemberIds = liveMembers.map((e) => e.uuid).toList();
        liveMembers.forEach((element) {
          if (liveMemberIds.contains(element.uuid)) {
            if (element != targetAddress) {
              aptosReceiverAddresses.add(element.aptos_address);
              if (element.external_wallet_address != null) {
                receiverAddresses.add(user.external_wallet_address!);
              } else {
                receiverAddresses.add(user.address);
              }
            }
          }
        });
      } else {
        receiverAddresses = [targetAddress ?? myUser.address];
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
      try {
        // check if amount is integer
        parsedAmount = double.parse(amount);
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
          groupId: outpostCallController.outpost.value!.uuid,
          target: targetAddress!,
          receiverAddresses: receiverAddresses,
          amount: parsedAmount.abs(),
          cheer: cheer,
          chainId: movementEVMChain.chainId,
        );
      } else if (selectedWallet == WalletNames.internal_EVM) {
        success = await internal_cheerOrBoo(
          groupId: outpostCallController.outpost.value!.uuid,
          user: user,
          target: targetAddress!,
          receiverAddresses: receiverAddresses,
          amount: parsedAmount.abs(),
          cheer: cheer,
          chainId: movementEVMChain.chainId,
        );
      } else if (selectedWallet == WalletNames.internal_Aptos) {
        success = await AptosMovement.cheerBoo(
          groupId: outpostCallController.outpost.value!.uuid,
          target: user.aptos_address!,
          receiverAddresses: aptosReceiverAddresses,
          amount: parsedAmount.abs(),
          cheer: cheer,
        );
      }
      // success null means error is handled inside called function
      if (success == null) {
        _removeLoadingCheerBoo(userId: userId, cheer: cheer);
        return;
      }
      if (success) {
        _removeLoadingCheerBoo(userId: userId, cheer: cheer);

        Toast.success(
          title: "Success",
          message: "${cheer ? "Cheer" : "Boo"} successful",
        );
        final ev = cheer
            ? OutgoingMessageTypeEnums.cheer
            : OutgoingMessageTypeEnums.boo;
        sendOutpostEvent(
          outpostId: outpostCallController.outpost.value!.uuid,
          eventType: ev,
          eventData: WsOutgoingMessageData(
            amount: parsedAmount,
            react_to_user_address: userId,
          ),
        );
        analytics.logEvent(name: 'cheerBoo', parameters: {
          'cheer': cheer.toString(),
          'amount': amount,
          'target': userId,
          'groupId': outpostCallController.outpost.value!.uuid,
          'fromUser': myUser.uuid,
        });
        final internalWalletAddress =
            await web3AuthWalletAddress(); //await Evm.getAddress();
        if (internalWalletAddress == null) {
          l.e("podium address is null");
          return;
        }
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
      _removeLoadingCheerBoo(userId: userId, cheer: cheer);
      Toast.error(
        title: "Error",
        message: "User has not connected wallet for some reason",
      );
      return;
    }
  }

  audioMuteChanged({required bool muted}) {
    if (!wsClient.connected) {
      Toast.warning(
        title: 'Connection Error',
        message: 'please check your internet connection',
      );
    }
    final outpostId = outpostCallController.outpost.value!.uuid;
    l.d(
      "audoi mute:$muted",
    );
    if (muted) {
      amIMuted.value = true;
      sendOutpostEvent(
        outpostId: outpostId,
        eventType: OutgoingMessageTypeEnums.stop_speaking,
      );
    } else {
      final outpostCreator =
          outpostCallController.outpost.value!.creator_user_uuid;
      if (mySession.value == null) return;
      final remainingTime = mySession.value!.remaining_time;
      if (remainingTime <= 0 && myId != outpostCreator) {
        Toast.error(
          title: "You've ran out of time",
          message: "",
        );
        amIMuted.value = true;
        jitsiMeet.setAudioMuted(true);
        return;
      }
      sendOutpostEvent(
        outpostId: outpostId,
        eventType: OutgoingMessageTypeEnums.start_speaking,
      );
      amIMuted.value = false;
      jitsiMeet.setAudioMuted(false);
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
