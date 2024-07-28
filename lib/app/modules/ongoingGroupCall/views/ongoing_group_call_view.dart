import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/ongoingGroupCall/utils.dart';
import 'package:podium/app/modules/ongoingGroupCall/widgets/usersInRoomList.dart';
import 'package:podium/app/modules/ongoingGroupCall/widgets/widgetWithTimer/widgetWrapper.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/utils/dateUtils.dart';
import 'package:podium/utils/navigation/navigation.dart';
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
            final remainingTimeInMillisecond =
                controller.remainingTimeTimer.value ?? 0;
            if (remainingTimeInMillisecond == double.maxFinite.toInt()) {
              return Container(
                child: const Center(
                  child: Text('presenting as admin'),
                ),
              );
            }
            return remainingTimeInMillisecond != 0
                ? Text(
                    formatDuration(remainingTimeInMillisecond),
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
              child: Column(
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    group.creator.fullName,
                    style: const TextStyle(color: Colors.white),
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
    if (myUser == null) {
      return Container(
        child: const Center(
          child: Text('something went horribly wrong'),
        ),
      );
    }
    return Container(
      height: Get.height - 200,
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
          Button(
            onPressed: () {
              controller.runHome();
            },
            text: "Leave the Room",
            type: ButtonType.solid,
            color: ButtonColors.DANGER,
          )
        ],
      ),
    );
  }
}
