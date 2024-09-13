import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/groupDetail/views/group_detail_view.dart';
import 'package:podium/app/modules/ongoingGroupCall/widgets/usersInRoomList.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/utils/dateUtils.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/popListener.dart';
import '../controllers/ongoing_group_call_controller.dart';

class OngoingGroupCallView extends GetView<OngoingGroupCallController> {
  const OngoingGroupCallView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GroupCall(),
    );
  }
}

class GroupCall extends GetView<GroupCallController> {
  const GroupCall({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PopListener(
          warningMessage: "Tap again to leave the room",
          onPop: () {
            Navigate.to(
              type: NavigationTypes.offAllNamed,
              route: Routes.HOME,
            );
          },
        ),
        GroupInfo(),
        SessionInfo(),
        MembersList(),
      ],
    );
  }
}

class SessionInfo extends GetWidget<OngoingGroupCallController> {
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

class GroupInfo extends GetWidget<GroupCallController> {
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

class MembersList extends GetWidget<GroupCallController> {
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
    return Container(
      height: Get.height - 190,
      child: Column(
        children: [
          Container(
            child: Expanded(
              child: Container(
                child: Obx(() {
                  final members = controller.members.value;
                  return UsersInRoomList(usersList: members);
                }),
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
                      ));
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
