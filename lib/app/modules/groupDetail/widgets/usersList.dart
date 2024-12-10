import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/button/button.dart';
// import 'package:web3modal_flutter/utils/util.dart';

class UserList extends StatelessWidget {
  final List<UserInfoModel> usersList;
  const UserList({super.key, required this.usersList});
  @override
  Widget build(BuildContext context) {
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
          final isItME = user.id == myId;
          return _SingleUser(
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

class _SingleUser extends StatelessWidget {
  const _SingleUser({
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
                color: isItME ? Colors.green : ColorName.cardBorder,
              ),
              borderRadius: const BorderRadius.all(const Radius.circular(8)),
            ),
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            padding: const EdgeInsets.all(10),
            key: Key(userId),
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
                                  truncate(userId, length: 10),
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
                        fullWidth: false,
                        small: true,
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

class FollowButton extends GetView<UsersController> {
  final String userId;
  final bool fullWidth;
  final bool small;
  const FollowButton(
      {super.key,
      required this.userId,
      this.fullWidth = false,
      this.small = false});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loadingIds = controller.followingsInProgress;
      final isLoading = loadingIds[userId] != null;
      final idsImFollowing = controller.currentUserInfo.value!.following;
      final isFollowing = idsImFollowing.contains(userId);
      return Button(
          size: small ? ButtonSize.SMALL : ButtonSize.LARGE,
          onPressed: () {
            final idsImFollowing = controller.currentUserInfo.value!.following;
            final isFollowing = idsImFollowing.contains(userId);
            controller.followUnfollow(userId, !isFollowing);
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
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
