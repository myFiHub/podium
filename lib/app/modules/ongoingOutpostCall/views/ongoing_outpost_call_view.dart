import 'package:animated_icon/animated_icon.dart';
import 'package:floating_draggable_widget/floating_draggable_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/views/report_form.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/usersInOutpostList.dart';
import 'package:podium/app/modules/outpostDetail/views/outpost_detail_view.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/dateUtils.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';
import 'package:pulsator/pulsator.dart';

class RecordingIndicator extends GetView<OngoingOutpostCallController> {
  const RecordingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.recorderUserId.value.isEmpty) {
        return emptySpace;
      }

      return const Positioned(
        top: 16,
        right: 16,
        child: Tooltip(
          message: 'creator is recording',
          child: SizedBox(
            width: 22,
            height: 22,
            child: Pulsator(
              style: PulseStyle(color: Colors.red),
              duration: Duration(seconds: 2),
              count: 2,
              repeat: 0,
              startFromScratch: false,
              autoStart: true,
              fit: PulseFit.contain,
              child: Icon(
                Icons.circle,
                color: Colors.red,
                size: 6,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class OngoingGroupCallView extends GetView<OngoingOutpostCallController> {
  const OngoingGroupCallView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final groupCallController = Get.find<OutpostCallController>();
    final canITalk = groupCallController.canTalk.value;

    if (controller.introStartCalled == false) {
      controller.introStartCalled = true;
      controller.startIntro();
    }
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (res, r) {
        final exists = Get.isRegistered<OngoingOutpostCallController>();
        if (exists) {
          controller.introFinished(false);
        }
      },
      child: FloatingDraggableWidget(
        mainScreenWidget: Scaffold(
          body: Stack(
            children: [
              Obx(() {
                final shouldShowIntro = controller.shouldShowIntro.value;
                return GroupCall(
                  shouldShowIntro: shouldShowIntro,
                );
              }),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.flag,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Get.dialog(
                        Dialog(
                          backgroundColor: ColorName.cardBackground,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: ReportForm(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const RecordingIndicator(),
            ],
          ),
        ),
        floatingWidget: Obx(() {
          final isGroupCallControllerRegistered =
              Get.isRegistered<OutpostCallController>();
          final isControllerRegistered =
              Get.isRegistered<OngoingOutpostCallController>();

          if (!isGroupCallControllerRegistered) {
            return Container(
              width: 0,
              height: 0,
            );
          }
          final outpostCallController = Get.find<OutpostCallController>();
          final outpost = outpostCallController.outpost.value;

          if (outpost == null || !isControllerRegistered) {
            return Container(
              width: 0,
              height: 0,
            );
          }
          final isMuted = controller.amIMuted.value;
          final amICreator = outpost.creator_user_uuid == myId;
          final isRecording = controller.isRecording.value;
          final isStartingToRecord = controller.isStartingToRecord.value;
          final recordable = outpost.is_recordable;
          if (!canITalk) {
            return FloatingActionButton(
              key: controller.muteUnmuteKey,
              backgroundColor: ColorName.greyText,
              onPressed: () {},
              tooltip: 'can not talk',
              child: const SizedBox(
                height: 70,
                width: 70,
                child: Icon(
                  Icons.mic_off,
                ),
              ),
            );
          }
          return Column(
            children: [
              FloatingActionButton(
                heroTag: 'muteUnmute',
                key: controller.muteUnmuteKey,
                backgroundColor: isMuted ? Colors.red : Colors.green,
                onPressed: () {
                  controller.setMutedState(!isMuted);
                },
                tooltip: 'mute',
                child: Icon(
                  isMuted ? Icons.mic_off : Icons.mic,
                ),
              ),
              if (amICreator && recordable) space10,
              if (amICreator && recordable)
                FloatingActionButton(
                  heroTag: 'record',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    isStartingToRecord
                        ? null
                        : isRecording
                            ? controller.stopRecording()
                            : controller.startRecording();
                  },
                  tooltip: 'Record',
                  child: isStartingToRecord
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(),
                        )
                      : Icon(
                          isRecording ? Icons.stop : Icons.fiber_manual_record,
                          color: Colors.red,
                        ),
                ),
            ],
          );
        }),
        floatingWidgetHeight: canITalk ? 125 : 50,
        floatingWidgetWidth: 50,
        dx: Get.width - 80,
        dy: 50,
      ),
    );
  }
}

class ContextSaver extends GetView<OngoingOutpostCallController> {
  const ContextSaver({super.key});

  @override
  Widget build(BuildContext context) {
    controller.contextForIntro = context;
    return emptySpace;
  }
}

class GroupCall extends GetView<OutpostCallController> {
  final bool shouldShowIntro;
  const GroupCall({
    super.key,
    required this.shouldShowIntro,
  });

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: Column(
        children: [
          const ContextSaver(),
          const GroupInfo(),
          const SessionInfo(),
          MembersList(
            shouldShowIntro: shouldShowIntro,
          ),
        ],
      ),
    );
  }
}

class SessionInfo extends GetView<OngoingOutpostCallController> {
  const SessionInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final mySession = controller.mySession.value;
        final isAdmin = controller.amIAdmin.value;
        if (controller.mySession.value == null) {
          return const Text(
            "loading...",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 36,
            ),
          );
        }
        final remainingTimeInSeconds = mySession!.remaining_time;
        if (isAdmin) {
          return emptySpace;
        }
        final list = formatDuration(remainingTimeInSeconds);
        final remainingTime = list.join(":");
        final isSmall = int.parse(list[0]) == 0 && int.parse(list[1]) < 2;
        return remainingTimeInSeconds != 0
            ? Row(
                children: [
                  // Button(onPressed: () {
                  //   controller.handleIncomingReaction(
                  //     IncomingMessage(
                  //       name: IncomingMessageType.userBooed,
                  //       data: IncomingMessageData(
                  //         address: '0xf8b769e62e1752a43f9fe343bb37fc3d8cb168e2',
                  //         react_to_user_address:
                  //             '0xf8b769e62e1752a43f9fe343bb37fc3d8cb168e2',
                  //       ),
                  //     ),
                  //   );
                  // }),
                  SizedBox(
                    width: (Get.width / 3) - 12,
                  ),
                  Container(
                    key: controller.timerKey,
                    child: Text(
                      remainingTime,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: isSmall ? Colors.red : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 36,
                      ),
                    ),
                  )
                ],
              )
            : Container(
                child: const Center(
                  child: Text(
                    'time is up!',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                      fontSize: 36,
                    ),
                  ),
                ),
              );
      },
    );
  }
}

class GroupInfo extends GetView<OutpostCallController> {
  const GroupInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final outpost = controller.outpost.value;
      final iAmCreator = outpost?.creator_user_uuid == myId;
      return outpost != null
          ? Container(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  Text(
                    outpost.name,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  if (iAmCreator) const Text("created by you"),
                  if (!iAmCreator)
                    Text("created by ${outpost.creator_user_name}"),
                ],
              ),
            )
          : Container();
    });
  }
}

const spaceBetween = const SizedBox(width: 10);

class MembersList extends GetView<OutpostCallController> {
  final bool shouldShowIntro;
  const MembersList({super.key, required this.shouldShowIntro});

  @override
  Widget build(BuildContext context) {
    if (controller.outpost.value == null) {
      return Container();
    }

    return Expanded(
      // height: Get.height - 190,
      child: Column(
        children: [
          Container(
            child: Expanded(
              child: DefaultTabController(
                length: 3,
                child: Scaffold(
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    toolbarHeight: 0,
                    bottom: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorColor: ColorName.primaryBlue,
                      labelColor: ColorName.primaryBlue,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Live"),
                              space5,
                              AnimateIcon(
                                key: UniqueKey(),
                                onTap: () async {
                                  controller.fetchLiveData(withJoin: true);
                                },
                                color: Colors.blueAccent,
                                iconType: IconType.animatedOnTap,
                                height: 20,
                                width: 20,
                                animateIcon: AnimateIcons.refresh,
                              ),
                            ],
                          ),
                        ),
                        const Tab(
                          child: Text("Search"),
                        ),
                        Obx(() {
                          final talkingMembers = controller.talkingUsers.value;
                          return Tab(
                            child: Text("Talking (${talkingMembers.length})"),
                          );
                        }),
                      ],
                    ),
                  ),
                  body: TabBarView(
                    children: [
                      Obx(
                        () {
                          final members = controller.sortedMembers.value;
                          //  sort the users based on the sort type, biggest to smallest
                          return UsersInOutpostList(
                            shouldShowIntro: shouldShowIntro,
                            usersList: members,
                            outpostId: controller.outpost.value!.uuid,
                          );
                        },
                      ),
                      Container(
                        child: const SearchInRoom(),
                      ),
                      Obx(
                        () {
                          final members = controller.talkingUsers.value;
                          return UsersInOutpostList(
                            shouldShowIntro: false,
                            usersList: members,
                            outpostId: controller.outpost.value!.uuid,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          space5,
          // const _StartIntroButton(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (canInvite(
                outpost: controller.outpost.value!,
                currentUserId: myUser.uuid,
              ))
                Container(
                  width: (Get.width / 2) - 20,
                  child: Button(
                    type: ButtonType.outline,
                    onPressed: () {
                      openInviteBottomSheet(
                        canInviteToSpeak: canInviteToSpeak(
                          outpost: controller.outpost.value!,
                          currentUserId: myUser.uuid,
                        ),
                      );
                    },
                    child: const Text('Invite users'),
                  ),
                ),
              Container(
                width: (Get.width / 2) - 20,
                child: Button(
                  onPressed: () {
                    controller.runHome();
                  },
                  text: "Leave the Outpost",
                  type: ButtonType.solid,
                  color: ButtonColors.DANGER,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StartIntroButton extends GetView<OngoingOutpostCallController> {
  const _StartIntroButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
        text: 'Show Intro',
        onPressed: () {
          GetStorage().remove(IntroStorageKeys.viewedOngiongCall);
          controller.shouldShowIntro.value = true;
          controller.startIntro();
        });
  }
}

class SearchInRoom extends GetView<OutpostCallController> {
  const SearchInRoom({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 50,
          child: Input(
            hintText: "Search",
            onChanged: (value) {
              controller.searchedValueInMeet.value = value;
            },
          ),
        ),
        Obx(
          () {
            final members = controller.sortedMembers.value;
            final searchedValue = controller.searchedValueInMeet.value;
            final filteredMembers = members.where(
              (element) {
                return element.name.toLowerCase().contains(
                      searchedValue.toLowerCase(),
                    );
              },
            ).toList();
            return Expanded(
              child: UsersInOutpostList(
                shouldShowIntro: false,
                usersList: filteredMembers,
                outpostId: controller.outpost.value!.uuid,
              ),
            );
          },
        ),
      ],
    );
  }
}
