import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/utils.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/likePath.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/widgetWithTimer/widgetWrapper.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/services/websocket/incomingMessage.dart';
import 'package:podium/services/websocket/outgoingMessage.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/dateUtils.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';
import 'package:pulsator/pulsator.dart';

class UsersInOutpostList extends StatelessWidget {
  final List<LiveMember> usersList;
  final String outpostId;
  final bool shouldShowIntro;
  const UsersInOutpostList({
    super.key,
    required this.usersList,
    required this.outpostId,
    required this.shouldShowIntro,
  });
  @override
  Widget build(BuildContext context) {
    return shouldShowIntro
        ? const IntroUser()
        : ListView.builder(
            itemCount: usersList.length,
            itemBuilder: (context, index) {
              final user = usersList[index];
              final name = user.name;
              String avatar = user.image;
              if (avatar.isEmpty || avatar == defaultAvatar) {
                avatar = avatarPlaceHolder(name);
              }
              final userId = user.uuid;
              final isItME = userId == myId;
              return _SingleUserInOutpost(
                key: Key(user.uuid + 'singleUserCard'),
                isItME: isItME,
                userId: userId,
                user: user,
                name: name,
                avatar: avatar,
                groupId: outpostId,
              );
            },
          );
  }
}

class IntroUser extends StatelessWidget {
  const IntroUser({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: 1,
        itemBuilder: (context, index) {
          return const _SingleUserCard(
            isItME: false,
            name: 'Intro User',
            address: 'intro',
            avatar: Constants.defaultProfilePic,
            outpostId: 'intro',
            id: 'intro',
            isIntroUser: true,
          );
        });
  }
}

class _SingleUserInOutpost extends StatelessWidget {
  const _SingleUserInOutpost({
    super.key,
    required this.isItME,
    required this.userId,
    required this.user,
    required this.name,
    required this.avatar,
    required this.groupId,
  });

  final bool isItME;
  final String userId;
  final LiveMember user;
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
      child: _SingleUserCard(
        id: user.uuid,
        address: user.address,
        isItME: isItME,
        name: name,
        avatar: avatar,
        outpostId: groupId,
        isIntroUser: false,
      ),
    );
  }
}

class _SingleUserCard extends StatelessWidget {
  const _SingleUserCard({
    super.key,
    required this.isItME,
    required this.name,
    required this.avatar,
    required this.outpostId,
    required this.id,
    required this.address,
    required this.isIntroUser,
  });
  final String id;
  final String address;
  final bool isItME;
  final bool isIntroUser;
  final String name;
  final String avatar;
  final String outpostId;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
              color: ColorName.cardBackground,
              border: Border.all(color: ColorName.cardBorder),
              borderRadius: const BorderRadius.all(const Radius.circular(8))),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          padding: const EdgeInsets.all(8),
          key: Key(id),
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
                          constraints: const BoxConstraints(
                            maxWidth: 180,
                          ),
                          child: Text(
                            isItME ? "You" : name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              overflow: TextOverflow.ellipsis,
                              color:
                                  isItME ? Colors.green[200] : ColorName.white,
                            ),
                          ),
                        ),
                        space5,
                        Row(
                          children: [
                            Img(
                              src: avatar,
                              alt: name,
                            ),
                            space5,
                            Container(
                              width: 80,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    truncate(id, length: 10),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: ColorName.greyText,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  space5,
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: ColorName.greyText,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  RemainingTime(
                                    userId: id,
                                    key: Key(id),
                                  ),
                                ],
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  Actions(userId: id, isIntroUser: isIntroUser),
                ],
              ),
              Positioned(
                top: -5,
                right: 0,
                child: _TalkingIndicator(
                  userId: id,
                  key: Key(id + 'talking'),
                ),
              ),
              Positioned(
                bottom: -5,
                right: 0,
                child: _Reactions(address: address),
              ),
            ],
          ),
        ),
        _ConfettiDetector(
          userId: id,
        ),
      ],
    );
  }
}

class _Reactions extends GetView<OutpostCallController> {
  final String address;
  const _Reactions({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final reactions = controller.reactionsMap.value[address];
      if (reactions == null) return const SizedBox();

      return Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildReactionItem(
              icon: Icons.thumb_up,
              count: reactions[OutgoingMessageTypeEnums.like] ?? 0,
              color: Colors.green,
            ),
            const SizedBox(width: 2),
            _buildReactionItem(
              icon: Icons.thumb_down,
              count: reactions[OutgoingMessageTypeEnums.dislike] ?? 0,
              color: Colors.red,
            ),
            const SizedBox(width: 2),
            _buildReactionItem(
              icon: Icons.sentiment_very_dissatisfied,
              count: reactions[OutgoingMessageTypeEnums.boo] ?? 0,
              color: Colors.red,
            ),
            const SizedBox(width: 2),
            _buildReactionItem(
              icon: Icons.celebration,
              count: reactions[OutgoingMessageTypeEnums.cheer] ?? 0,
              color: Colors.green,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildReactionItem({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    if (count == 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
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
    return GetBuilder<OngoingOutpostCallController>(
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
    const Color.fromARGB(255, 255, 0, 0),
    const Color.fromARGB(255, 255, 0, 123),
    const Color.fromARGB(255, 232, 0, 0),
    const Color.fromARGB(255, 255, 108, 172),
    const Color.fromARGB(255, 255, 184, 233)
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
    const Color.fromARGB(255, 255, 0, 0),
    const Color.fromARGB(255, 255, 0, 123),
    const Color.fromARGB(255, 232, 0, 0),
    const Color.fromARGB(255, 255, 108, 172),
    const Color.fromARGB(255, 255, 184, 233)
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
      gravity: 0.4,
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
  if (reaction.reaction == IncomingMessageType.userLiked) {
    Timer(Duration.zero, () {
      _shootLike(context);
    });
  }
  if (reaction.reaction == IncomingMessageType.userDisliked) {
    Timer(Duration.zero, () {
      _shootDisLike(context);
    });
  }
  if (reaction.reaction == IncomingMessageType.userCheered) {
    Timer(Duration.zero, () {
      _shootCheer(context);
    });
  }
  if (reaction.reaction == IncomingMessageType.userBooed) {
    Timer(Duration.zero, () {
      _shootBoo(context);
    });
  }
}

class _TalkingIndicator extends GetView<OutpostCallController> {
  final String userId;
  const _TalkingIndicator({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final talkingMembers = controller.talkingUsers.value;
      final isTalking =
          talkingMembers.map((element) => element.uuid).contains(userId);
      return !isTalking
          ? const SizedBox()
          : Container(
              width: 40,
              height: 40,
              child: const Pulsator(
                style: const PulseStyle(color: Colors.green),
                duration: const Duration(seconds: 2),
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

class RemainingTime extends GetView<OngoingOutpostCallController> {
  final String userId;
  const RemainingTime({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final roomCreator =
          controller.outpostCallController.outpost.value!.creator_user_uuid;
      final users =
          controller.members.value.where((m) => m.uuid == userId).toList();
      if (users.length == 0) {
        return const SizedBox();
      }
      final remainingTime = users[0].remaining_time;
      if (userId == roomCreator) {
        return Text('Creator',
            style: TextStyle(fontSize: 10, color: Colors.green[200]));
      }
      final [hh, mm, ss] = formatDuration(remainingTime);
      return Text(
        '$hh:$mm:$ss left',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: ColorName.greyText,
        ),
      );
    });
  }
}

class Actions extends GetView<OngoingOutpostCallController> {
  final String userId;
  final bool isIntroUser;
  const Actions({
    required this.userId,
    required this.isIntroUser,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final globalController = Get.find<GlobalController>();
    final myUser = globalController.myUserInfo.value;
    final myId = myUser!.uuid;

    return Center(
      // width: Get.width * 0.5,
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          SizedBox(
            key: isIntroUser ? controller.likeDislikeKey : null,
            height: 40,
            child: Row(
              children: [
                if (userId != myId) LikeDislike(userId: userId, isLike: true),
                if (userId != myId) LikeDislike(userId: userId, isLike: false),
              ],
            ),
          ),
          Row(
            key: isIntroUser ? controller.cheerBooKey : null,
            children: [
              if (userId != myId) CheerBoo(cheer: false, userId: userId),
              CheerBoo(cheer: true, userId: userId)
            ],
          )
        ],
      ),
    );
  }
}

class CheerBoo extends GetView<OngoingOutpostCallController> {
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
        splashColor: Colors.transparent,
        padding: const EdgeInsets.only(top: 8, left: 8),
        icon: cheer
            ? isCheerLoading
                ? const SizedBox(
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
                ? const SizedBox(
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

class LikeDislike extends GetView<OngoingOutpostCallController> {
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
            ? controller.onLikeClicked(userId: userId)
            : controller.onDislikeClicked(userId: userId);
      },
      type: GFButtonType.transparent,
    );

    return Container(
      width: 40,
      child: Center(
        child: Obx(() {
          final timers = controller.timers.value;
          final storageKey = generateKeyForStorageAndObserver(
            userId: userId,
            groupId: controller.outpostCallController.outpost.value!.uuid,
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
