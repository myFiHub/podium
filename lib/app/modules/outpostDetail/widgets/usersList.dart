import 'package:auto_animated/auto_animated.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:glow_container/glow_container.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';

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
  final List<UserModel> usersList;
  final Function(String userId)? onRequestUpdate;
  const UserList({
    super.key,
    required this.usersList,
    this.onRequestUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
        child: LiveList.options(
      options: _options,
      itemCount: usersList.length,
      itemBuilder: (context, index, animation) {
        final user = usersList[index];
        final name = user.name ?? '';
        String avatar = user.image ?? '';
        if (avatar.contains("https://ui-avatars.com/api/?name=Oo")) {
          avatar = '';
        }
        if (avatar.isEmpty) {
          avatar = avatarPlaceHolder(name);
        }
        final userId = user.uuid;
        final isItME = user.uuid == myUser.uuid;
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
              child: _SingleUser(
                key: Key(userId),
                isItME: isItME,
                user: user,
                name: name,
                avatar: avatar,
                onRequestUpdate: () {
                  onRequestUpdate?.call(userId);
                },
              )),
        );
      },
    ));
  }
}

class _SingleUser extends GetView<UsersController> {
  final bool isItME;
  final UserModel user;
  final String name;
  final String avatar;
  final VoidCallback? onRequestUpdate;

  const _SingleUser({
    super.key,
    required this.isItME,
    required this.user,
    required this.name,
    required this.avatar,
    // ignore: unused_element
    this.onRequestUpdate,
  });

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
        usersController.openUserProfile(user.uuid);
      },
      child: Stack(
        children: [
          Obx(() {
            final gettingUserInfo_uuid = controller.gettingUserInfo_uuid.value;
            return GlowContainer(
              glowRadius: 4,
              gradientColors: const [
                ColorName.primaryBlue,
                ColorName.secondaryBlue
              ],
              rotationDuration: const Duration(seconds: 1),
              glowLocation: GlowLocation.outerOnly,
              containerOptions: ContainerOptions(
                width: Get.width - 4,
                borderRadius: 8,
                margin: const EdgeInsets.only(left: 2, bottom: 8),
                backgroundColor: ColorName.cardBackground,
                borderSide: const BorderSide(
                  width: 1.0,
                  color: ColorName.cardBackground,
                ),
              ),
              transitionDuration: const Duration(milliseconds: 200),
              showAnimatedBorder: gettingUserInfo_uuid == user.uuid,
              child: Container(
                decoration: const BoxDecoration(
                  color: ColorName.cardBackground,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                // margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                padding: const EdgeInsets.all(10),
                key: Key(user.uuid),
                child: Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Img(
                                    src: avatar,
                                    alt: name,
                                  ),
                                ),
                                space10,
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 176,
                                      ),
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      truncate(user.uuid, length: 10),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                        color: ColorName.greyText,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                        if (isItME)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          )
                        else
                          FollowButton(
                            user: user,
                            fullWidth: false,
                            small: true,
                            key: Key(user.uuid),
                            onFollowStatusChanged: onRequestUpdate,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          })
        ],
      ),
    );
  }
}

class FollowButton extends GetView<UsersController> {
  final UserModel user;
  final bool fullWidth;
  final bool small;
  final VoidCallback? onFollowStatusChanged;

  const FollowButton({
    super.key,
    required this.user,
    this.fullWidth = false,
    this.small = false,
    this.onFollowStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loadingIds = controller.followingsInProgress;
      final isLoading = loadingIds[user.uuid] != null;
      final isFollowing = user.followed_by_me ?? false;
      return Button(
          size: small ? ButtonSize.SMALL : ButtonSize.LARGE,
          onPressed: () async {
            final isFollowing = user.followed_by_me ?? false;
            await controller.followUnfollow(user.uuid, !isFollowing);
            onFollowStatusChanged?.call();
          },
          type: isFollowing ? ButtonType.outline : ButtonType.solid,
          shape: ButtonShape.pills,
          blockButton: fullWidth,
          textColor: isFollowing ? Colors.white : ColorName.cardBackground,
          color: Colors.white,
          /* borderSide: BorderSide(
            color: isFollowing ? Colors.red : Colors.green,
          ),  */
          child: isLoading
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${isFollowing ? "Unfollow" : "Follow"}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                    if (!isFollowing)
                      const Icon(
                        Icons.add,
                        color: ColorName.cardBackground,
                        size: 12,
                      ),
                  ],
                ));
    });
  }
}
