import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/global/popUpsAndModals/setReminder.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/modules/outpostDetail/widgets/lumaDetailsDialog.dart';
import 'package:podium/app/modules/outpostDetail/widgets/usersList.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';

import '../controllers/outpost_detail_controller.dart';

class GroupDetailView extends GetView<OutpostDetailController> {
  const GroupDetailView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Obx(() {
            // final isLoading = controller.isGettingMembers.value;
            l.d('members: ${controller.membersList.value}');
            final members = controller.membersList.value;
            final outpost = controller.outpost.value;
            final accesses = controller.outpostAccesses.value;
            if (outpost == null || accesses == null) {
              return Container(
                width: Get.width,
                height: Get.height - 110,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            final iAmOwner = outpost.creator_user_uuid == myId;

            return Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  space16,
                  SizedBox(
                    width: Get.width,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Joining:",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                              if (outpost.luma_event_id != null)
                                _LumaIconButton()
                            ],
                          ),
                          space5,
                          Text(
                            outpost.name,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                          if (outpost.subject.trim().isNotEmpty)
                            Text(
                              outpost.subject,
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            )
                          else
                            const SizedBox.shrink(), // Evita espacio residual
                          if (iAmOwner)
                            Text(
                              "Access Type: ${parseAccessType(outpost.enter_type)}",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[400],
                              ),
                            ),
                          Text(
                            "Speakers: ${parseSpeakerType(outpost.speak_type)}",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  space10,
                  Expanded(
                    child: UserList(
                      usersList: members,
                      onRequestUpdate: (userId) {
                        controller.updateSingleUser(userId);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (canInvite(
                        outpost: outpost,
                        currentUserId: myId,
                      ))
                        Container(
                          width: (Get.width / 2) - 20,
                          child: Button(
                            type: ButtonType.outline,
                            onPressed: () {
                              openInviteBottomSheet(
                                  canInviteToSpeak: canInviteToSpeak(
                                outpost: outpost,
                                currentUserId: myId,
                              ));
                            },
                            child: const Text('Invite users'),
                          ),
                        ),
                      Container(
                        width: (Get.width / 2) - 20,
                        child: const JoinTheRoomButton(),
                      ),
                    ],
                  ),
                  space10,
                  space10,
                  if (outpost.scheduled_for != 0) const SetReminderButton(),
                  // if (group.scheduledFor != 0 && iAmOwner) ...[
                  //   space10,
                  //   const ChangeScheduleButton()
                  // ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LumaIconButton extends GetView<OutpostDetailController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isGettingLumaEventDetails =
          controller.isGettingLumaEventDetails.value;
      final isGettingLumaEventGuests =
          controller.isGettingLumaEventGuests.value;
      return IconButton(
        onPressed: () {
          if (isGettingLumaEventDetails || isGettingLumaEventGuests) return;
          openLumaDetailsDialog();
        },
        icon: isGettingLumaEventDetails || isGettingLumaEventGuests
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(),
              )
            : Assets.images.lumaPng.image(width: 24, height: 24),
      );
    });
  }
}

class ChangeScheduleButton extends GetView<OutpostDetailController> {
  const ChangeScheduleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      type: ButtonType.outline,
      color: ColorName.primaryBlue,
      blockButton: true,
      onPressed: () async {
        controller.reselectScheduleTime();
      },
      child: const Text(
        'Change Schedule',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class SetReminderButton extends GetView<OutpostDetailController> {
  const SetReminderButton({super.key});

  @override
  Widget build(BuildContext context) {
    final outpost = controller.outpost.value;

    return Obx(() {
      final reminderTime = controller.reminderTime.value;
      if (outpost == null) {
        return Container();
      }
      controller.forceUpdateIndicator.value;
      int? reminderIsSetForInMinotes = null;
      if (reminderTime != null) {
        final reminder = reminderTime
            .difference(
                DateTime.fromMillisecondsSinceEpoch(outpost.scheduled_for))
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
          outpost.scheduled_for < DateTime.now().millisecondsSinceEpoch;
      if (isPassed) {
        return const SizedBox();
      }
      if (outpost.alarm_id == 0) {
        return const SizedBox();
      }
      return Button(
        type: ButtonType.outline,
        color: ColorName.primaryBlue,
        blockButton: true,
        onPressed: () async {
          final newDateInSeconds = await setReminder(
            alarmId: outpost.alarm_id,
            scheduledFor: outpost.scheduled_for,
            eventName: outpost.name,
            timesList: defaultTimeList(endsAt: outpost.scheduled_for),
          );
          l.d('newDateInSeconds: $newDateInSeconds');
        },
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      );
    });
  }
}

class JoinTheRoomButton extends GetView<OutpostDetailController> {
  const JoinTheRoomButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final accesses = controller.outpostAccesses.value;
      final outpost = controller.outpost.value;
      final joinButtonContent = controller.jointButtonContentProps.value;
      if (accesses == null || outpost == null) {
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
  required OutpostModel outpost,
  required String currentUserId,
}) {
  final iAmCreator = currentUserId == outpost.creator_user_uuid;
  final isGroupPublic = outpost.enter_type == FreeOutpostAccessTypes.public;
  final amIAMember = (outpost.i_am_member);
  if (iAmCreator || isGroupPublic || amIAMember) {
    return true;
  }
  return false;
}

bool canInviteToSpeak({
  required OutpostModel outpost,
  required String currentUserId,
}) {
  final iAmCreator = currentUserId == outpost.creator_user_uuid;
  final isGroupPublic = outpost.speak_type == FreeOutpostSpeakerTypes.everyone;
  if (iAmCreator || isGroupPublic) {
    return true;
  }
  return false;
}

class UserInvitationBottomSheetContent
    extends GetView<OutpostDetailController> {
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
          padding: const EdgeInsets.all(20),
          height: Get.height * 0.5,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
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
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              space10,
              Input(
                hintText: 'Enter User\'s Name',
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
                                style: const TextStyle(
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
                              style: const TextStyle(
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
