import 'package:floating_draggable_widget/floating_draggable_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/global/lib/jitsiMeet.dart';
import 'package:podium/app/modules/groupDetail/views/group_detail_view.dart';
import 'package:podium/app/modules/ongoingGroupCall/widgets/usersInRoomList.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/dateUtils.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';
import '../controllers/ongoing_group_call_controller.dart';

class OngoingGroupCallView extends GetView<OngoingGroupCallController> {
  const OngoingGroupCallView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FloatingDraggableWidget(
      mainScreenWidget: Scaffold(
        body: GroupCall(),
      ),
      floatingWidget: Obx(() {
        final isGroupCallControllerRegistered =
            Get.isRegistered<GroupCallController>();
        final isControllerRegistered =
            Get.isRegistered<OngoingGroupCallController>();

        if (!isGroupCallControllerRegistered) {
          return Container(
            width: 0,
            height: 0,
          );
        }
        final groupCallController = Get.find<GroupCallController>();
        final group = groupCallController.group.value;

        if (group == null || !isControllerRegistered) {
          return Container(
            width: 0,
            height: 0,
          );
        }
        final isMuted = controller.amIMuted.value;
        final canITalk = groupCallController.canTalk.value;
        if (!canITalk) {
          return Container(
            width: 0,
            height: 0,
          );
        }
        return FloatingActionButton(
          backgroundColor: isMuted ? Colors.red : Colors.green,
          onPressed: () {
            jitsiMeet.setAudioMuted(!isMuted);
          },
          tooltip: 'mute',
          child: Icon(
            isMuted ? Icons.mic_off : Icons.mic,
          ),
        );
      }),
      floatingWidgetHeight: 50,
      floatingWidgetWidth: 50,
      dx: Get.width - 80,
      dy: 50,
    );
  }
}

class GroupCall extends GetView<GroupCallController> {
  const GroupCall({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GroupInfo(),
        SessionInfo(),
        MembersList(),
      ],
    );
  }
}

class SessionInfo extends GetView<OngoingGroupCallController> {
  const SessionInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(
          () {
            final isAdmin = controller.amIAdmin.value;
            final remainingTimeInMillisecond =
                controller.remainingTimeTimer.value;
            if (remainingTimeInMillisecond == -1) {
              return Text(
                "loading...",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 36,
                ),
              );
            }
            if (isAdmin) {
              return Container(
                child: const Center(
                  child: Text('presenting as admin'),
                ),
              );
            }
            final list = formatDuration(remainingTimeInMillisecond);
            final joined = list.join(":");
            final isSmall = int.parse(list[0]) == 0 && int.parse(list[1]) < 2;
            return remainingTimeInMillisecond != 0
                ? Container(
                    child: Text(
                      joined,
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

class GroupInfo extends GetView<GroupCallController> {
  const GroupInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final group = controller.group.value;
      return group != null
          ? Container(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  space5,
                  Text("by"),
                  space5,
                  Text(
                    group.creator.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : Container();
    });
  }
}

const spaceBetween = const SizedBox(width: 10);

class MembersList extends GetView<GroupCallController> {
  const MembersList({super.key});

  @override
  Widget build(BuildContext context) {
    final globalController = Get.find<GlobalController>();
    final myUser = globalController.currentUserInfo.value;
    if (controller.group.value == null) {
      return Container();
    }
    if (myUser == null) {
      return Container(
        child: const Center(
          child: Text('something went horribly wrong'),
        ),
      );
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
                          child: Text("All Members"),
                        ),
                        Tab(
                          child: Text("Search"),
                        ),
                        Obx(() {
                          final talkingMembers =
                              controller.talkingMembers.value;
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
                          return UsersInRoomList(
                            usersList: members,
                          );
                        },
                      ),
                      Container(
                        child: SearchInRoom(),
                      ),
                      Obx(
                        () {
                          final members = controller.talkingMembers.value;
                          return UsersInRoomList(
                            usersList: members,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (canInvite(
                group: controller.group.value!,
                currentUserId: myUser.id,
              ))
                Container(
                  width: (Get.width / 2) - 20,
                  child: Button(
                    type: ButtonType.outline,
                    onPressed: () {
                      openInviteBottomSheet(
                        canInviteToSpeak: canInviteToSpeak(
                          group: controller.group.value!,
                          currentUserId: myUser.id,
                        ),
                      );
                    },
                    child: Text('Invite users'),
                  ),
                ),
              Container(
                width: (Get.width / 2) - 20,
                child: Button(
                  onPressed: () {
                    controller.runHome();
                  },
                  text: "Leave the Room",
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

class SearchInRoom extends GetView<GroupCallController> {
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
              child: UsersInRoomList(
                usersList: filteredMembers,
              ),
            );
          },
        ),
      ],
    );
  }
}
