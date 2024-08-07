import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/user_info_model.dart';
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
    return ListView.builder(
      itemCount: usersList.length,
      itemBuilder: (context, index) {
        final user = usersList[index];
        final name = user.fullName;
        final avatar = user.avatar;
        final userId = user.id;
        final isItME = user.id == myUserId;
        return AnimationConfiguration.staggeredList(
          position: index,
          key: Key(userId),
          duration: const Duration(milliseconds: 100),
          child: SlideAnimation(
            key: Key(userId),
            verticalOffset: 12.0,
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
                                      GFAvatar(
                                        backgroundImage: NetworkImage(avatar),
                                        shape: GFAvatarShape.standard,
                                        backgroundColor: ColorName.cardBorder,
                                      ),
                                      space10,
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            Util.truncate(userId, length: 6),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w400,
                                              color: ColorName.greyText,
                                            ),
                                          ),
                                          // space5,
                                          // Text(
                                          //   name,
                                          //   style: const TextStyle(
                                          //     fontSize: 16,
                                          //     fontWeight: FontWeight.w700,
                                          //     color: ColorName.greyText,
                                          //     overflow: TextOverflow.ellipsis,
                                          //   ),
                                          // ),
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
              ),
            ),
          ),
        );
      },
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
