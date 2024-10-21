import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createGroup/controllers/create_group_controller.dart';
import 'package:podium/app/modules/global/popUpsAndModals/setReminder.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
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
          Obx(() {
            // final isLoading = controller.isGettingMembers.value;
            final members = controller.membersList.value;
            final group = controller.group.value;
            final accesses = controller.groupAccesses.value;
            if (group == null || accesses == null) {
              return Container(
                width: Get.width,
                height: Get.height - 110,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final iAmOwner = group.creator.id == myId;

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
                        child: JoinTheRoomButton(),
                      ),
                    ],
                  ),
                  space10,
                  space10,
                  if (group.scheduledFor != 0) SetReminderButton(),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class SetReminderButton extends GetView<GroupDetailController> {
  const SetReminderButton({super.key});

  @override
  Widget build(BuildContext context) {
    final group = controller.group.value;

    return Obx(() {
      if (group == null) {
        return Container();
      }
      controller.forceUpdateIndicator.value;
      final reminderTime = getReminderTime(group.alarmId);

      int? reminderIsSetForInMinotes = null;
      if (reminderTime != null) {
        final reminder = reminderTime
            .difference(DateTime.fromMillisecondsSinceEpoch(group.scheduledFor))
            .inMinutes;
        reminderIsSetForInMinotes = reminder;
      }

      String text = reminderIsSetForInMinotes != null
          ? "Reminder is set for ${reminderIsSetForInMinotes.abs()} min before event"
          : 'Set a reminder';
      if (reminderIsSetForInMinotes == 0) {
        text = 'Reminder is set for when event starts';
      }
      final isPassed =
          group.scheduledFor < DateTime.now().millisecondsSinceEpoch;
      if (isPassed) {
        return const SizedBox();
      }
      if (group.alarmId == 0) {
        return SizedBox();
      }
      return Button(
        type: ButtonType.outline,
        color: ColorName.primaryBlue,
        blockButton: true,
        onPressed: () async {
          await setReminder(
            alarmId: group.alarmId,
            scheduledFor: group.scheduledFor,
            eventName: group.name,
            timesList: defaultTimeList(endsAt: group.scheduledFor),
          );
          controller.forceUpdate();
        },
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      );
    });
  }
}

class JoinTheRoomButton extends GetView<GroupDetailController> {
  const JoinTheRoomButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final accesses = controller.groupAccesses.value;
      final group = controller.group.value;
      final joinButtonContent = controller.jointButtonContentProps.value;
      if (accesses == null || group == null) {
        return Container();
      }

      return Button(
        type: ButtonType.gradient,
        onPressed: joinButtonContent.enabled
            ? () {
                controller.startTheCall(accesses: accesses);
              }
            : null,
        child: Text(
          joinButtonContent.text,
          textAlign: TextAlign.center,
        ),
      );
    });
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
  final isGroupPublic = group.accessType == null ||
      group.accessType == FreeRoomAccessTypes.public;
  final amIAMember = group.members.contains(currentUserId);
  if (iAmCreator || isGroupPublic || amIAMember) {
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
      group.speakerType == FreeRoomSpeakerTypes.everyone;
  if (iAmCreator || isGroupPublic) {
    return true;
  }
  return false;
}

class UserInvitationBottomSheetContent extends GetView<GroupDetailController> {
  final bool canInviteToSpeak;
  const UserInvitationBottomSheetContent({
    super.key,
    required this.canInviteToSpeak,
  });

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
