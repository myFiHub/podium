import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/ongoingGroupCall/utils.dart';
import 'package:podium/app/modules/ongoingGroupCall/widgets/popListener.dart';
import 'package:podium/app/modules/ongoingGroupCall/widgets/widgetWithTimer/widgetWrapper.dart';
import 'package:podium/utils/dateUtils.dart';
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
    return Expanded(
      child: Container(
        child: Obx(() {
          final members = controller.members.value;
          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isMe = myUser.id == member.id;
              return GFCard(
                content: Container(
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        backgroundImage: NetworkImage(member.avatar),
                      ),
                      spaceBetween,
                      Container(
                        width: 80,
                        child: Text(
                          member.fullName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isMe ? Colors.green : Colors.white,
                          ),
                        ),
                      ),
                      spaceBetween,
                      if (controller.haveOngoingCall.value)
                        Actions(
                          userId: member.id,
                          key: Key(member.id),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class Actions extends GetView<OngoingGroupCallController> {
  final String userId;
  const Actions({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final globalController = Get.find<GlobalController>();
    final myUser = globalController.currentUserInfo.value;
    final myId = myUser!.id;
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (userId != myId) LikeDislike(userId: userId, isLike: true),
          if (userId != myId) LikeDislike(userId: userId, isLike: false),
          if (userId != myId) CheerBoo(cheer: false, userId: userId),
          CheerBoo(cheer: true, userId: userId),
        ],
      ),
    );
  }
}

class CheerBoo extends GetWidget<OngoingGroupCallController> {
  final bool cheer;
  final String userId;
  const CheerBoo({super.key, required this.cheer, required this.userId});

  @override
  Widget build(BuildContext context) {
    return GFIconButton(
      icon: Icon(
        cheer ? Icons.handshake_rounded : Icons.timelapse,
        color: cheer ? Colors.green : Colors.red,
      ),
      onPressed: () {
        controller.cheerBoo(
          userId: userId,
          cheer: cheer,
        );
      },
      type: GFButtonType.transparent,
    );
  }
}

class LikeDislike extends GetWidget<OngoingGroupCallController> {
  final bool isLike;
  final String userId;
  const LikeDislike({
    super.key,
    required this.userId,
    required this.isLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      child: Center(
        child: Obx(() {
          final timers = controller.timers.value;
          final storageKey = generateKeyForStorageAndObserver(
              userId: userId,
              groupId: controller.groupCallController.group.value!.id,
              like: isLike);
          final finishAt = timers[storageKey];
          return WidgetWithTimer(
            finishAt: finishAt,
            storageKey: storageKey,
            onComplete: () {
              controller.timers.update((val) {
                val!.remove(storageKey);
              });
            },
            child: GFIconButton(
              icon: Icon(
                isLike ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
                color: isLike ? Colors.green : Colors.red,
              ),
              onPressed: () {
                isLike
                    ? controller.onLikeClicked(userId)
                    : controller.onDislikeClicked(userId);
              },
              type: GFButtonType.transparent,
            ),
          );
        }),
      ),
    );
  }
}
