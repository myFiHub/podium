import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
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
        final joiningGroupId = controller.joiningGroupId.value;
        return AnimationConfiguration.staggeredList(
          position: index,
          key: Key(groupId),
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            key: Key(groupId),
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: GestureDetector(
                onTap: () {
                  controller.joinGroup(groupId);
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: ColorName.cardBackground,
                          border: Border.all(color: ColorName.cardBorder),
                          borderRadius:
                              const BorderRadius.all(const Radius.circular(8))),
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(16),
                      key: Key(groupId),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  )),
                              space10,
                              Row(
                                children: [
                                  GFAvatar(
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
                                      Text("Created By",
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w400,
                                              color: ColorName.greyText)),
                                      space5,
                                      Text(group.creator.fullName,
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: ColorName.greyText)),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                          if (joiningGroupId == groupId)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircularProgressIndicator(),
                            ),
                          if (amICreator)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: Icon(
                                  Icons.verified,
                                  color: Colors.green,
                                ),
                                onPressed: () {
                                  //  show group options
                                },
                              ),
                            )
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
