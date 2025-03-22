import 'package:floating_draggable_widget/floating_draggable_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/outpostDetail/views/outpost_detail_view.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/usersInOutpostList.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/dateUtils.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';

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
        controller.introFinished(false);
      },
      child: FloatingDraggableWidget(
        mainScreenWidget: Scaffold(
          body: Obx(() {
            final shouldShowIntro = controller.shouldShowIntro.value;
            return GroupCall(
              shouldShowIntro: shouldShowIntro,
            );
          }),
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
                    isRecording
                        ? controller.stopRecording()
                        : controller.startRecording();
                  },
                  tooltip: 'Record',
                  child: Icon(
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
    return const SizedBox.shrink();
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
    return Column(
      children: [
        const ContextSaver(),
        const GroupInfo(),
        const SessionInfo(),
        MembersList(
          shouldShowIntro: shouldShowIntro,
        ),
      ],
    );
  }
}

class SessionInfo extends GetView<OngoingOutpostCallController> {
  const SessionInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Obx(
          () {
            final isAdmin = controller.amIAdmin.value;
            final remainingTimeInSeconds = controller.remainingTimeTimer.value;

            if (remainingTimeInSeconds == -1) {
              return const Text(
                "loading...",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 36,
                ),
              );
            }
            if (isAdmin) {
              return Container(
                key: controller.timerKey,
                child: const Center(
                  child: Text('presenting as admin'),
                ),
              );
            }
            final list = formatDuration(remainingTimeInSeconds);
            final remainingTime = list.join(":");
            final isSmall = int.parse(list[0]) == 0 && int.parse(list[1]) < 2;
            return remainingTimeInSeconds != 0
                ? Container(
                    key: controller.timerKey,
                    child: Text(
                      remainingTime,
                      style: TextStyle(
                        color: isSmall ? Colors.red : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 36,
                      ),
                    ),
                  )
                : Container(
                    child: const Center(
                      child: Text(
                        'time is up!',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
          },
        )
      ],
    );
  }
}

class GroupInfo extends GetView<OutpostCallController> {
  const GroupInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final outpost = controller.outpost.value;
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
                  Text(" by ${outpost.creator_user_name}"),
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
                        const Tab(
                          child: Text(
                            "Live",
                            textAlign: TextAlign.center,
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
                          return UsersInGroupList(
                            shouldShowIntro: shouldShowIntro,
                            usersList: members,
                            groupId: controller.outpost.value!.uuid,
                          );
                        },
                      ),
                      Container(
                        child: const SearchInRoom(),
                      ),
                      Obx(
                        () {
                          final members = controller.talkingUsers.value;
                          return UsersInGroupList(
                            shouldShowIntro: false,
                            usersList: members,
                            groupId: controller.outpost.value!.uuid,
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
            final filteredMembers = members.where((element) {
              return element.name
                  .toLowerCase()
                  .contains(searchedValue.toLowerCase());
            }).toList();
            return Expanded(
              child: UsersInGroupList(
                shouldShowIntro: false,
                usersList: filteredMembers,
                groupId: controller.outpost.value!.uuid,
              ),
            );
          },
        ),
      ],
    );
  }
}
