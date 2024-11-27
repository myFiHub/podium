import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/ongoingGroupCall/controllers/ongoing_group_call_controller.dart';
import 'package:podium/app/modules/ongoingGroupCall/utils.dart';
import 'package:podium/app/modules/ongoingGroupCall/widgets/likePath.dart';
import 'package:podium/app/modules/ongoingGroupCall/widgets/widgetWithTimer/widgetWrapper.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_session_model.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/dateUtils.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:pulsator/pulsator.dart';

class UsersInRoomList extends StatelessWidget {
  final List<FirebaseSessionMember> usersList;
  final String groupId;
  const UsersInRoomList(
      {super.key, required this.usersList, required this.groupId});
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: usersList.length,
      itemBuilder: (context, index) {
        final user = usersList[index];
        final name = user.name;
        String avatar = user.avatar;
        if (avatar.isEmpty || avatar == defaultAvatar) {
          avatar = avatarPlaceHolder(name);
        }
        final userId = user.id;
        final isItME = user.id == myId;
        return _SingleUserInRoom(
            key: Key(user.id + 'singleUserCard'),
            isItME: isItME,
            userId: userId,
            user: user,
            name: name,
            avatar: avatar,
            groupId: groupId);
      },
    );
  }
}

class _SingleUserInRoom extends StatelessWidget {
  const _SingleUserInRoom(
      {super.key,
      required this.isItME,
      required this.userId,
      required this.user,
      required this.name,
      required this.avatar,
      required this.groupId});

  final bool isItME;
  final String userId;
  final FirebaseSessionMember user;
  final String name;
  final String avatar;
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final usersController = Get.find<UsersController>();
        if (isItME) {
          Navigate.to(
            type: NavigationTypes.toNamed,
            route: Routes.MY_PROFILE,
          );
          return;
        }
        usersController.openUserProfile(userId);
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                color: ColorName.cardBackground,
                border: Border.all(color: ColorName.cardBorder),
                borderRadius: const BorderRadius.all(const Radius.circular(8))),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            padding: const EdgeInsets.all(8),
            key: Key(user.id),
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: Get.width * 0.3,
                            child: Text(
                              isItME ? "You" : name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                overflow: TextOverflow.ellipsis,
                                color: isItME
                                    ? Colors.green[200]
                                    : ColorName.white,
                              ),
                            ),
                          ),
                          space5,
                          Row(
                            children: [
                              Hero(
                                tag: user.id,
                                child: Img(
                                  src: avatar,
                                  alt: name,
                                ),
                              ),
                              space5,
                              Container(
                                width: 80,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      truncate(userId, length: 10),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                        color: ColorName.greyText,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    space5,
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: ColorName.greyText,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    RemainingTime(
                                      userId: userId,
                                      key: Key(user.id),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    Actions(userId: userId),
                  ],
                ),
                Positioned(
                    top: -5,
                    right: 0,
                    child: _TalkingIndicator(
                      groupId: groupId,
                      userId: userId,
                      key: Key(user.id + 'talking'),
                    )),
              ],
            ),
          ),
          _ConfettiDetector(
            userId: userId,
          ),
        ],
      ),
    );
  }
}

class _ConfettiDetector extends StatelessWidget {
  final String userId;
  const _ConfettiDetector({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey();
    return GetBuilder<OngoingGroupCallController>(
        id: 'confetti' + userId,
        builder: (controller) {
          final lastReaction = controller.lastReaction.value;
          if (lastReaction.targetId == userId) {
            _shootReaction(
              context: context,
              reaction: lastReaction,
            );
          }
          return IgnorePointer(
            child: SizedBox(
              key: key,
              height: 0,
              width: 0,
            ),
          );
        });
  }
}

_shootLike(BuildContext context) {
  final RenderBox renderBox = context.findRenderObject() as RenderBox;
  final position = renderBox.localToGlobal(Offset.zero);
  List<Color> colors = [
    Color.fromARGB(255, 255, 0, 0),
    Color.fromARGB(255, 255, 0, 123),
    Color.fromARGB(255, 232, 0, 0),
    Color.fromARGB(255, 255, 108, 172),
    Color.fromARGB(255, 255, 184, 233)
  ];

  final options = ConfettiOptions(
      spread: 30,
      ticks: 70,
      gravity: 0.5,
      decay: 0.97,
      y: (position.dy / Get.height) + (30 / Get.height),
      x: (position.dx / Get.width) + 0.1,
      startVelocity: 5,
      colors: colors);
  Confetti.launch(context,
      options: options.copyWith(
        particleCount: 1,
      ),
      particleBuilder: (index) => LikePath());
}

_shootDisLike(BuildContext context) {
  final RenderBox renderBox = context.findRenderObject() as RenderBox;
  final position = renderBox.localToGlobal(Offset.zero);
  List<Color> colors = [
    Color.fromARGB(255, 255, 0, 0),
    Color.fromARGB(255, 255, 0, 123),
    Color.fromARGB(255, 232, 0, 0),
    Color.fromARGB(255, 255, 108, 172),
    Color.fromARGB(255, 255, 184, 233)
  ];

  final options = ConfettiOptions(
      spread: 30,
      ticks: 40,
      gravity: 0.5,
      decay: 0.97,
      y: (position.dy / Get.height) + (30 / Get.height),
      x: (position.dx / Get.width) + 0.1,
      startVelocity: 0,
      colors: colors);
  Confetti.launch(context,
      options: options.copyWith(
        particleCount: 1,
      ),
      particleBuilder: (index) => DislikePath());
}

_shootCheer(BuildContext context) {
  final RenderBox renderBox = context.findRenderObject() as RenderBox;
  final position = renderBox.localToGlobal(Offset.zero);
  List<Color> colors = [
    Colors.green,
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
  ];

  final options = ConfettiOptions(
      spread: 30,
      ticks: 120,
      gravity: 0.5,
      decay: 0.97,
      y: (position.dy / Get.height) + (30 / Get.height),
      x: (position.dx / Get.width) + 0.1,
      startVelocity: 10,
      colors: colors);
  Confetti.launch(context,
      options: options.copyWith(
        particleCount: 1,
      ),
      particleBuilder: (index) => CheerPath());
  Confetti.launch(context,
      options: options.copyWith(
        particleCount: 50,
        scalar: 1,
      ));
}

_shootBoo(BuildContext context) {
  final RenderBox renderBox = context.findRenderObject() as RenderBox;
  final position = renderBox.localToGlobal(Offset.zero);
  List<Color> colors = [
    Colors.red,
  ];

  final options = ConfettiOptions(
      spread: 30,
      ticks: 120,
      gravity: 0.5,
      decay: 0.97,
      y: (position.dy / Get.height) + (30 / Get.height),
      x: (position.dx / Get.width) + 0.1,
      startVelocity: 0,
      colors: colors);
  Confetti.launch(context,
      options: options.copyWith(
        particleCount: 1,
      ),
      particleBuilder: (index) => BooPath());
  Confetti.launch(context,
      options: options.copyWith(
        particleCount: 50,
        gravity: 2,
        startVelocity: 5,
      ));
}

_shootReaction({required BuildContext context, required Reaction reaction}) {
  if (reaction.reaction == eventNames.like) {
    Timer(Duration.zero, () {
      _shootLike(context);
    });
  }
  if (reaction.reaction == eventNames.dislike) {
    Timer(Duration.zero, () {
      _shootDisLike(context);
    });
  }
  if (reaction.reaction == eventNames.cheer) {
    Timer(Duration.zero, () {
      _shootCheer(context);
    });
  }
  if (reaction.reaction == eventNames.boo) {
    Timer(Duration.zero, () {
      _shootBoo(context);
    });
  }
}

class _TalkingIndicator extends GetView<GroupsController> {
  final String groupId;
  final String userId;
  const _TalkingIndicator(
      {super.key, required this.groupId, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final talkingMembers = controller.takingUsersInGroupsMap.value;
      final talkingUsers = talkingMembers[groupId];
      if (talkingUsers == null) {
        return const SizedBox();
      }
      final isTalking = talkingUsers.contains(userId);
      return !isTalking
          ? const SizedBox()
          : Container(
              width: 40,
              height: 40,
              child: Pulsator(
                style: PulseStyle(color: Colors.green),
                duration: Duration(seconds: 2),
                count: 2,
                repeat: 0,
                startFromScratch: false,
                autoStart: true,
                fit: PulseFit.contain,
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            );
    });
  }
}

class RemainingTime extends GetView<OngoingGroupCallController> {
  final String userId;
  const RemainingTime({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller == null) {
        return SizedBox();
      }
      final timersMap = controller.allRemainingTimesMap.value;
      final roomCreator = controller.groupCallController.group.value!.creator;
      final userRemainingTime = timersMap[userId];
      if (userId == roomCreator.id) {
        return Text('Room creator',
            style: TextStyle(fontSize: 10, color: Colors.green[200]));
      }
      if (userRemainingTime == null) {
        return const SizedBox();
      } else {
        final [hh, mm, ss] = formatDuration(userRemainingTime);
        return Text(
          '$hh:$mm:$ss left',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: ColorName.greyText,
          ),
        );
      }
    });
  }
}

class FollowButton extends GetView<UsersController> {
  final String userId;
  final bool fullWidth;
  const FollowButton({super.key, required this.userId, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loadingIds = controller.followingsInProgress;
      final isLoading = loadingIds[userId] != null;
      final idsImFollowing = controller.currentUserInfo.value!.following;
      final isFollowing = idsImFollowing.contains(userId);
      return Button(
          onPressed: () {
            final idsImFollowing = controller.currentUserInfo.value!.following;
            final isFollowing = idsImFollowing.contains(userId);
            controller.followUnfollow(userId, !isFollowing);
          },
          type: ButtonType.outline,
          blockButton: fullWidth,
          textColor: isFollowing ? Colors.red : Colors.green,
          borderSide: BorderSide(
            color: isFollowing ? Colors.red : Colors.green,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          child: isLoading
              ? Center(
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${isFollowing ? "un" : ""}follow'),
                    if (!isFollowing)
                      const Icon(
                        Icons.add,
                        color: Colors.green,
                        size: 24,
                      ),
                  ],
                ));
    });
  }
}

class Actions extends GetView<OngoingGroupCallController> {
  final String userId;
  const Actions({
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final globalController = Get.find<GlobalController>();
    final myUser = globalController.currentUserInfo.value;
    final myId = myUser!.id;

    return Center(
      // width: Get.width * 0.5,
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                if (userId != myId) LikeDislike(userId: userId, isLike: true),
                if (userId != myId) LikeDislike(userId: userId, isLike: false),
              ],
            ),
          ),
          Row(
            children: [
              if (userId != myId) CheerBoo(cheer: false, userId: userId),
              CheerBoo(cheer: true, userId: userId)
            ],
          ),
        ],
      ),
    );
  }
}

class CheerBoo extends GetView<OngoingGroupCallController> {
  final bool cheer;
  final String userId;
  const CheerBoo({super.key, required this.cheer, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loadingUsers = controller.loadingWalletAddressForUser.value;
      final isCheerLoading = loadingUsers.contains("$userId-cheer");
      final isBooLoading = loadingUsers.contains("$userId-boo");
      return GFIconButton(
        icon: cheer
            ? isCheerLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(),
                  )
                : Assets.images.cheer.image(
                    width: 30,
                    height: 30,
                    color: Colors.green,
                  )
            : isBooLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(),
                  )
                : Assets.images.boo.image(
                    width: 30,
                    height: 30,
                    color: Colors.red,
                  ),
        onPressed: () {
          controller.cheerBoo(
            userId: userId,
            cheer: cheer,
          );
        },
        type: GFButtonType.transparent,
      );
    });
  }
}

class LikeDislike extends GetView<OngoingGroupCallController> {
  final bool isLike;
  final String userId;
  const LikeDislike({
    super.key,
    required this.userId,
    required this.isLike,
  });

  @override
  Widget build(BuildContext context) {
    final child = GFIconButton(
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
    );

    return Container(
      width: 50,
      child: Center(
        child: Obx(() {
          final timers = controller.timers.value;
          final storageKey = generateKeyForStorageAndObserver(
            userId: userId,
            groupId: controller.groupCallController.group.value!.id,
            like: isLike,
          );
          final finishAt = timers[storageKey];
          return WidgetWithTimer(
            finishAt: finishAt,
            storageKey: storageKey,
            onComplete: () {
              if (controller.timers.value[storageKey] == null) return;
              controller.timers.update((val) {
                val!.remove(storageKey);
                return val;
              });
              // ignore: invalid_use_of_protected_member
              controller.timers.refresh();
            },
            child: child,
          );
        }),
      ),
    );
  }
}
