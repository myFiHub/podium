import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/app/modules/ongoingGroupCall/controllers/ongoing_group_call_controller.dart';
import 'package:podium/app/modules/ongoingGroupCall/utils.dart';
import 'package:podium/app/modules/ongoingGroupCall/widgets/widgetWithTimer/widgetWrapper.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/dateUtils.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:web3modal_flutter/utils/util.dart';

class UsersInRoomList extends StatelessWidget {
  final List<UserInfoModel> usersList;
  const UsersInRoomList({super.key, required this.usersList});
  @override
  Widget build(BuildContext context) {
    final globalController = Get.find<GlobalController>();
    final myUserId = globalController.currentUserInfo.value!.id;
    return ListView.builder(
      itemCount: usersList.length,
      itemBuilder: (context, index) {
        final user = usersList[index];
        final name = user.fullName;
        final userId = user.id;
        final isItME = user.id == myUserId;
        return AnimationConfiguration.staggeredList(
          position: index,
          key: Key(user.id),
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            key: Key(user.id),
            verticalOffset: 20.0,
            child: FadeInAnimation(
              child: GestureDetector(
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
                          border: Border.all(
                              color:
                                  isItME ? Colors.green : ColorName.cardBorder),
                          borderRadius:
                              const BorderRadius.all(const Radius.circular(8))),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      padding: const EdgeInsets.all(16),
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
                                    Text(name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        )),
                                    space10,
                                    Row(
                                      children: [
                                        GFAvatar(
                                          backgroundImage:
                                              NetworkImage(user.avatar),
                                          shape: GFAvatarShape.standard,
                                          backgroundColor: ColorName.cardBorder,
                                        ),
                                        space10,
                                        Container(
                                          width: Get.width - 335,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                Util.truncate(userId,
                                                    length: 6),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w400,
                                                  color: ColorName.greyText,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              space5,
                                              Text(
                                                user.fullName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: ColorName.greyText,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class RemainingTime extends GetWidget<OngoingGroupCallController> {
  final String userId;
  const RemainingTime({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final timersMap = controller.allRemainingTimesMap.value;
      final roomCreator = controller.groupCallController.group.value!.creator;
      final userRemainingTime = timersMap[userId];
      if (userId == roomCreator.id) {
        return const Text('Room creator', style: TextStyle(fontSize: 12));
      }
      if (userRemainingTime == null) {
        return const SizedBox();
      } else {
        final [hh, mm, ss] = formatDuration(userRemainingTime);
        return Text(
          '$hh:$mm:$ss left',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: ColorName.greyText,
          ),
        );
      }
    });
  }
}

class FollowButton extends GetWidget<UsersController> {
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
        cheer ? Icons.arrow_upward : Icons.arrow_downward,
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
              if (controller.timers.value[storageKey] == null) return;
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
