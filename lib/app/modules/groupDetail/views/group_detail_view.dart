import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/widgets/groupsList.dart';
import 'package:podium/app/modules/groupDetail/widgets/usersList.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';

import '../controllers/group_detail_controller.dart';

class GroupDetailView extends GetView<GroupDetailController> {
  const GroupDetailView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Obx(
            () {
              final isLoading = controller.isGettingMembers.value;
              final members = controller.membersList.value;
              final group = controller.group.value;
              final GlobalController globalController = Get.find();
              final myUser = globalController.currentUserInfo.value;
              final myId = myUser!.id;
              if (group == null) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              final iAmOwner = group.creator.id == myId;
              if (isLoading) {
                return Center(child: CircularProgressIndicator());
              } else {
                return Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        group.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (group.subject != null)
                        Text(
                          group.subject!,
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.grey[400],
                          ),
                        ),
                      if (iAmOwner)
                        Text(
                          "Access Type: ${parseAccessType(group.accessType)}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      Text(
                        "Speakers: ${parseSpeakerType(group.speakerType)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                      Expanded(
                        child: UserList(
                          usersList: members,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (canInvite(
                            group: group,
                            currentUserId: myId,
                          ))
                            Container(
                              width: (Get.width / 2) - 20,
                              child: Button(
                                type: ButtonType.outline,
                                onPressed: () {
                                  openInviteBottomSheet(
                                      canInviteToSpeak: canInviteToSpeak(
                                    group: group,
                                    currentUserId: myId,
                                  ));
                                },
                                child: Text('Invite users'),
                              ),
                            ),
                          Container(
                            width: (Get.width / 2) - 20,
                            child: Button(
                              type: ButtonType.gradient,
                              onPressed: () {
                                controller.startTheCall();
                              },
                              child: Text('join the room'),
                            ),
                          ),
                        ],
                      ),
                      space10,
                      space10,
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

openInviteBottomSheet({required bool canInviteToSpeak}) {
  Get.dialog(
    UserInvitationBottomSheetContent(
      canInviteToSpeak: canInviteToSpeak,
    ),
  );
}

bool canInvite({
  required FirebaseGroup group,
  required String currentUserId,
}) {
  final iAmCreator = currentUserId == group.creator.id;
  final isGroupPublic =
      group.accessType == null || group.accessType == RoomAccessTypes.public;
  if (iAmCreator || isGroupPublic) {
    return true;
  }
  return false;
}

bool canInviteToSpeak({
  required FirebaseGroup group,
  required String currentUserId,
}) {
  final iAmCreator = currentUserId == group.creator.id;
  final isGroupPublic = group.speakerType == null ||
      group.speakerType == RoomSpeakerTypes.everyone;
  if (iAmCreator || isGroupPublic) {
    return true;
  }
  return false;
}

class UserInvitationBottomSheetContent extends GetView<GroupDetailController> {
  final bool canInviteToSpeak;
  const UserInvitationBottomSheetContent(
      {super.key, required this.canInviteToSpeak});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        child: Container(
          color: ColorName.cardBackground,
          padding: EdgeInsets.all(20),
          height: Get.height * 0.5,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invite Users',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Get.close();
                      controller.listOfSearchedUsersToInvite.value = [];
                    },
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              space10,
              Input(
                hintText: 'Enter the Name',
                onChanged: (value) {
                  controller.searchUsers(value);
                },
                autofocus: true,
              ),
              Expanded(child: Container(
                child: Obx(() {
                  final users = controller.listOfSearchedUsersToInvite.value;
                  final liveInvitedMembers =
                      controller.liveInvitedMembers.value;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userInInvitedList = liveInvitedMembers[user.id];
                      if (userInInvitedList != null) {
                        final invitedToSpeal = userInInvitedList.invitedToSpeak;
                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                user.fullName,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Text(
                                'Invited ${userInInvitedList.invitedToSpeak ? 'to speak' : 'to listen'}',
                                style: TextStyle(
                                  color: invitedToSpeal
                                      ? Colors.green[200]
                                      : Colors.blue[200],
                                ),
                              ),
                            ),
                            Divider(
                              color: Colors.grey[900],
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                              user.fullName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (canInviteToSpeak)
                                  Button(
                                    type: ButtonType.outline,
                                    size: ButtonSize.SMALL,
                                    onPressed: () {
                                      controller.inviteUserToJoinThisGroup(
                                        userId: user.id,
                                        inviteToSpeak: true,
                                      );
                                    },
                                    text: 'Invite to speak',
                                  ),
                                space10,
                                Button(
                                  type: ButtonType.outline,
                                  size: ButtonSize.SMALL,
                                  text: 'Invite to listen',
                                  onPressed: () {
                                    controller.inviteUserToJoinThisGroup(
                                      userId: user.id,
                                      inviteToSpeak: false,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            color: Colors.grey[900],
                          ),
                        ],
                      );
                    },
                  );
                }),
              ))
            ],
          ),
        ),
      ),
    );
  }
}
