import 'package:animated_reorderable_list/animated_reorderable_list.dart';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'
    as Staggered;
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:web3modal_flutter/utils/util.dart';

class UserList extends StatelessWidget {
  final List<UserInfoModel> usersList;
  const UserList({super.key, required this.usersList});
  @override
  Widget build(BuildContext context) {
    final globalController = Get.find<GlobalController>();
    final myUserId = globalController.currentUserInfo.value!.id;

    return Scrollbar(
      child: ListView.builder(
        itemCount: usersList.length,
        itemBuilder: (BuildContext context, int index) {
          final user = usersList[index];
          final name = user.fullName;
          String avatar = user.avatar;
          if (avatar.contains("https://ui-avatars.com/api/?name=Oo")) {
            avatar = '';
          }
          if (avatar.isEmpty) {
            avatar = avatarPlaceHolder(name);
          }
          final userId = user.id;
          final isItME = user.id == myUserId;
          return SingleUser(
            key: Key(userId),
            isItME: isItME,
            userId: userId,
            name: name,
            avatar: avatar,
          );
        },
      ),
    );
  }
}

class SingleUser extends StatelessWidget {
  const SingleUser({
    super.key,
    required this.isItME,
    required this.userId,
    required this.name,
    required this.avatar,
  });

  final bool isItME;
  final String userId;
  final String name;
  final String avatar;

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
                border: Border.all(
                    color: isItME ? Colors.green : ColorName.cardBorder),
                borderRadius: const BorderRadius.all(const Radius.circular(8))),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.all(16),
            key: Key(userId),
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: Get.width * 0.5,
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        space10,
                        Row(
                          children: [
                            Hero(
                              tag: userId,
                              child: Img(
                                src: avatar,
                                alt: name,
                              ),
                            ),
                            space10,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Util.truncate(userId, length: 6),
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
                        userId: userId,
                        key: Key(userId),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          size: ButtonSize.MEDIUM,
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
                        size: 14,
                      ),
                  ],
                ));
    });
  }
}
