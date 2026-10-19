import 'package:auto_animated/auto_animated.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:glow_container/glow_container.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/ui/app_ui.dart';

final _options = const LiveOptions(
  // Start animation after (default zero)
  // delay: Duration(seconds: 0),

  // Show each item through (default 250)
  showItemInterval: Duration(milliseconds: 50),

  // Animation duration (default 250)
  // showItemDuration: Duration(seconds: 1),

  // Animations starts at 0.05 visible
  // item fraction in sight (default 0.025)
  visibleFraction: 0.05,

  // Repeat the animation of the appearance
  // when scrolling in the opposite direction (default false)
  // To get the effect as in a showcase for ListView, set true
  reAnimateOnVisibility: false,
);

class UserList extends StatelessWidget {
  final List<LiveMember>? liveUsersList;
  final List<UserModel>? userModelsList;
  final Function(String userId)? onRequestUpdate;
  const UserList({
    super.key,
    this.liveUsersList,
    this.userModelsList,
    this.onRequestUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final usersList = liveUsersList ?? userModelsList ?? [];

    return Scrollbar(
        child: LiveList.options(
      options: _options,
      itemCount: usersList.length,
      itemBuilder: (context, index, animation) {
        final name = liveUsersList != null
            ? liveUsersList![index].name
            : userModelsList![index].name;
        final uuid = liveUsersList != null
            ? liveUsersList![index].uuid
            : userModelsList![index].uuid;
        final followed_by_me = liveUsersList != null
            ? liveUsersList![index].followed_by_me
            : userModelsList![index].followed_by_me;
        final image = liveUsersList != null
            ? liveUsersList![index].image
            : userModelsList![index].image;
        final userId = uuid;
        return FadeTransition(
          opacity: Tween<double>(
            begin: 0,
            end: 1,
          ).animate(animation),
          // And slide transition
          child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.1),
                end: Offset.zero,
              ).animate(animation),
              // Paste you Widget
              child: UserListTile(
                key: Key(userId),
                uuid: uuid,
                name: name,
                image: image,
                followed_by_me: followed_by_me,
                onRequestUpdate: () {
                  onRequestUpdate?.call(userId);
                },
              )),
        );
      },
    ));
  }
}

class UserListTile extends StatelessWidget {
  final String uuid;
  final String? name;
  final String? image;
  final bool? followed_by_me;
  final VoidCallback? onRequestUpdate;
  const UserListTile({
    super.key,
    required this.uuid,
    this.name,
    this.image,
    this.followed_by_me,
    this.onRequestUpdate,
  });

  @override
  Widget build(BuildContext context) {
    String avatar = image ?? '';
    if (avatar.contains("https://ui-avatars.com/api/?name=Oo")) {
      avatar = '';
    }
    if (avatar.isEmpty) {
      avatar = avatarPlaceHolder(name);
    }
    return _SingleUser(
      key: Key(uuid),
      isItME: uuid == myUser.uuid,
      uuid: uuid,
      name: name ?? '',
      avatar: avatar,
      followed_by_me: followed_by_me ?? false,
      onRequestUpdate: onRequestUpdate,
    );
  }
}

class _SingleUser extends GetView<UsersController> {
  final bool isItME;
  final String uuid;
  final String name;
  final String avatar;
  final bool followed_by_me;
  final VoidCallback? onRequestUpdate;

  const _SingleUser({
    super.key,
    required this.isItME,
    required this.name,
    required this.uuid,
    required this.followed_by_me,
    required this.avatar,
    this.onRequestUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Obx(() {
        final gettingUserInfo_uuid = controller.gettingUserInfo_uuid.value;
        return GlowContainer(
          glowRadius: 4,
          gradientColors: const [
            ColorName.primaryBlue,
            ColorName.secondaryBlue
          ],
          rotationDuration: const Duration(seconds: 1),
          glowLocation: GlowLocation.outerOnly,
          containerOptions: const ContainerOptions(
            borderRadius: AppRadius.md,
            backgroundColor: Colors.transparent,
            borderSide: BorderSide(
              width: 1.0,
              color: Colors.transparent,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 200),
          showAnimatedBorder: gettingUserInfo_uuid == uuid,
          child: AppCard(
            key: Key(uuid),
            radius: AppRadius.md,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onTap: () {
              final usersController = Get.find<UsersController>();
              usersController.openUserProfile(uuid);
            },
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: Hero(
                    tag: 'profile_avatar_$uuid',
                    child: Img(
                      src: avatar,
                      alt: name,
                      size: 42,
                      borderRadius: const BorderRadius.all(Radius.circular(21)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (isItME) ...[
                            const SizedBox(width: 6),
                            const AppPill(
                              label: 'You',
                              color: AppColors.success,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        truncate(uuid, length: 10),
                        maxLines: 1,
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isItME)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 22,
                  )
                else
                  SizedBox(
                    height: 32,
                    child: FollowButton(
                      uuid: uuid,
                      followed_by_me: followed_by_me,
                      fullWidth: false,
                      small: true,
                      key: Key(uuid),
                      onFollowStatusChanged: onRequestUpdate,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class FollowButton extends GetView<UsersController> {
  final String uuid;
  final bool followed_by_me;
  final bool fullWidth;
  final bool small;
  final VoidCallback? onFollowStatusChanged;

  const FollowButton({
    super.key,
    required this.uuid,
    required this.followed_by_me,
    this.fullWidth = false,
    this.small = false,
    this.onFollowStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loadingIds = controller.followingsInProgress;
      final isLoading = loadingIds[uuid] != null;
      final isFollowing = followed_by_me;
      final foreground = isFollowing ? Colors.white : ColorName.cardBackground;
      final style = FilledButton.styleFrom(
        minimumSize: Size(fullWidth ? double.infinity : 0, small ? 32 : 44),
        padding: EdgeInsets.symmetric(horizontal: small ? 14 : 18),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: isFollowing ? AppColors.fill : Colors.white,
        foregroundColor: foreground,
        side: isFollowing ? const BorderSide(color: AppColors.border) : null,
        shape: const StadiumBorder(),
        textStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: small ? 12 : 14,
        ),
      );
      return FilledButton(
        style: style,
        onPressed: () async {
          final isFollowing = followed_by_me;
          final success = await controller.followUnfollow(uuid, !isFollowing);
          if (success) {
            onFollowStatusChanged?.call();
          }
        },
        child: isLoading
            ? const LoadingWidget(
                size: 12,
                color: ColorName.secondaryBlue,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isFollowing) ...[
                    Icon(Icons.add_rounded,
                        color: foreground, size: small ? 14 : 18),
                    const SizedBox(width: 4),
                  ],
                  Text(isFollowing ? "Unfollow" : "Follow"),
                ],
              ),
      );
    });
  }
}
