import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'
    as Staggered;
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/env.dart';
import 'package:share_plus/share_plus.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/utils/styles.dart';

class GroupList extends StatelessWidget {
  final List<FirebaseGroup> groupsList;
  const GroupList({super.key, required this.groupsList});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GroupsController>();
    return ListView.builder(
      itemCount: groupsList.length,
      itemBuilder: (context, index) {
        final group = groupsList[index];
        final name = group.name;
        final groupId = group.id;
        final amICreator = group.creator.id ==
            controller.globalController.currentUserInfo.value!.id;
        return Staggered.AnimationConfiguration.staggeredList(
          position: index,
          key: Key(groupId),
          duration: const Duration(milliseconds: 375),
          child: Staggered.SlideAnimation(
            key: Key(groupId),
            verticalOffset: 50.0,
            child: Staggered.FadeInAnimation(
              child: GestureDetector(
                onTap: () {
                  controller.joinGroupAndOpenGroupDetailPage(groupId);
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: ColorName.cardBackground,
                          border: Border.all(
                              color: amICreator
                                  ? Colors.green
                                  : ColorName.cardBorder),
                          borderRadius:
                              const BorderRadius.all(const Radius.circular(8))),
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(16),
                      key: Key(groupId),
                      child: Stack(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  space10,
                                  Row(
                                    children: [
                                      GFAvatar(
                                        size: 52,
                                        backgroundImage:
                                            NetworkImage(group.creator.avatar),
                                        shape: GFAvatarShape.standard,
                                        backgroundColor: ColorName.cardBorder,
                                      ),
                                      space10,
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              "Created By ${amICreator ? "You" : group.creator.fullName}",
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w400,
                                                  color: ColorName.greyText)),
                                          space5,
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.subject,
                                                color: ColorName.greyText,
                                                size: 14,
                                              ),
                                              Text(
                                                " ${group.subject}",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w400,
                                                  color: ColorName.greyText,
                                                ),
                                              )
                                            ],
                                          ),
                                          space5,
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.mic,
                                                color: ColorName.greyText,
                                                size: 14,
                                              ),
                                              space5,
                                              Text(
                                                "${group.speakerType}",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w400,
                                                  color: ColorName.greyText,
                                                ),
                                              ),
                                            ],
                                          ),
                                          space5,
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.lock,
                                                color: ColorName.greyText,
                                                size: 14,
                                              ),
                                              space5,
                                              Text(
                                                "${group.privacyType}",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w400,
                                                  color: ColorName.greyText,
                                                ),
                                              ),
                                            ],
                                          ),
                                          space5,
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.group,
                                                color: ColorName.greyText,
                                                size: 14,
                                              ),
                                              space5,
                                              Text(
                                                "${group.members.length} Members",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w400,
                                                  color: ColorName.greyText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    ],
                                  )
                                ],
                              ),
                              IconButton(
                                onPressed: () {
                                  Share.share(
                                      // 'podium://group-detail/$groupId',
                                      "${Env.baseDeepLinkUrl}/?link=${Env.baseDeepLinkUrl}${Routes.GROUP_DETAIL}?id=${groupId}&apn=com.web3podium");
                                },
                                icon: Icon(
                                  Icons.share,
                                  color: ColorName.greyText,
                                ),
                              )
                            ],
                          ),
                          JoiningIndicator(
                            groupId: groupId,
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

class JoiningIndicator extends GetWidget<GroupsController> {
  final groupId;
  const JoiningIndicator({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final joiningGroupId = controller.joiningGroupId.value;
      if (joiningGroupId != groupId) {
        return const SizedBox();
      }
      return Positioned(
        right: 0,
        bottom: 0,
        child: CircularProgressIndicator(),
      );
    });
  }
}
