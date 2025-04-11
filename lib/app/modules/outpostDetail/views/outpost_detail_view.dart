import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marquee/marquee.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/global/popUpsAndModals/setReminder.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/modules/outpostDetail/widgets/lumaDetailsDialog.dart';
import 'package:podium/app/modules/outpostDetail/widgets/usersList.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';

import '../controllers/outpost_detail_controller.dart';

class OutpostImage extends GetView<OutpostDetailController> {
  const OutpostImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final outpost = controller.outpost.value;
      if (outpost == null) return const SizedBox();

      final imageUrl =
          outpost.image.isEmpty ? Constants.logoUrl : outpost.image;

      return GestureDetector(
        onTap: () {
          Get.dialog(
            const Dialog(
              backgroundColor: Colors.transparent,
              child: _OpenImageDialogContent(),
            ),
          );
        },
        child: Img(
          src: imageUrl,
          size: 40,
          alt: outpost.name,
        ),
      );
    });
  }
}

class _OpenImageDialogContent extends GetView<OutpostDetailController> {
  const _OpenImageDialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final outpost = controller.outpost.value;
        if (outpost == null) return const SizedBox();
        final imageUrl =
            outpost.image.isEmpty ? Constants.logoUrl : outpost.image;
        final iAmOwner = outpost.creator_user_uuid == myId;
        final isUploadingImage = controller.isUploadingImage.value;
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: ColorName.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.only(top: 65, left: 24, right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Img(
                    src: imageUrl,
                    size: 300,
                    alt: outpost.name,
                  ),
                  if (iAmOwner) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                        width: 140,
                        child: Button(
                          blockButton: true,
                          loading: isUploadingImage,
                          type: ButtonType.outline,
                          size: ButtonSize.MEDIUM,
                          onPressed: () {
                            // Get.close();
                            controller.pickImage();
                          },
                          child: const Text('Change Image'),
                        )),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Get.close(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OutpostName extends StatelessWidget {
  final String name;
  const _OutpostName({required this.name});

  bool _isTextOverflowing(String text, double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width > maxWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isOverflowing = _isTextOverflowing(name, constraints.maxWidth);

          return SizedBox(
            width: constraints.maxWidth,
            height: 24,
            child: isOverflowing
                ? Marquee(
                    text: name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    scrollAxis: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    blankSpace: 20.0,
                    velocity: 50.0,
                    pauseAfterRound: const Duration(seconds: 1),
                    startPadding: 10.0,
                    accelerationDuration: const Duration(seconds: 1),
                    accelerationCurve: Curves.linear,
                    decelerationDuration: const Duration(milliseconds: 500),
                    decelerationCurve: Curves.easeOut,
                  )
                : Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _NameAndImageWrapper extends StatelessWidget {
  final String name;
  final bool hasLumaEvent;
  const _NameAndImageWrapper({
    required this.name,
    required this.hasLumaEvent,
  });

  @override
  Widget build(BuildContext context) {
    final label = TextPainter(
      text: TextSpan(
        text: name + '  ',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final labelWidth = label.width + 60;
    final isLarge = labelWidth > (Get.width - (hasLumaEvent ? 110 : 0));

    return SizedBox(
      width: isLarge ? Get.width - (hasLumaEvent ? 110 : 0) : labelWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _OutpostName(name: name),
          space8,
          const OutpostImage(),
        ],
      ),
    );
  }
}

class GroupDetailView extends GetView<OutpostDetailController> {
  const GroupDetailView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageWrapper(
        child: Column(
          children: [
            Obx(() {
              final exists = Get.isRegistered<OutpostDetailController>();
              if (!exists) return const SizedBox();
              final outpost = controller.outpost.value;
              final accesses = controller.outpostAccesses.value;
              if (outpost == null || accesses == null) {
                return Container(
                  width: Get.width,
                  height: Get.height - 110,
                  child: const Center(child: LoadingWidget()),
                );
              }
              final iAmOwner = outpost.creator_user_uuid == myId;
              final lumaEventId = outpost.luma_event_id;
              final hasLumaEvent =
                  lumaEventId != null && lumaEventId.isNotEmpty;
              return Expanded(
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        space16,
                        SizedBox(
                          width: Get.width,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Joining:",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ],
                                ),
                                space5,
                                _NameAndImageWrapper(
                                  name: outpost.name,
                                  hasLumaEvent: hasLumaEvent,
                                ),
                                if (outpost.subject.trim().isNotEmpty)
                                  Text(
                                    outpost.subject,
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  )
                                else
                                  emptySpace,
                                if (iAmOwner)
                                  Text(
                                    "Access Type: ${parseAccessType(outpost.enter_type)}",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Text(
                                      "Speakers: ${parseSpeakerType(outpost.speak_type)}",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const Spacer(),
                                    // AnimateIcon(
                                    //   key: UniqueKey(),
                                    //   onTap: () async {
                                    //     await controller.getMembers(outpost);
                                    //   },
                                    //   color: Colors.blueAccent,
                                    //   iconType: IconType.animatedOnTap,
                                    //   height: 20,
                                    //   width: 20,
                                    //   animateIcon: AnimateIcons.refresh,
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        space10,
                        const MembersList(),

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
                        if (outpost.scheduled_for != 0)
                          const SetReminderButton(),
                        // if (group.scheduledFor != 0 && iAmOwner) ...[
                        //   space10,
                        //   const ChangeScheduleButton()
                        // ],
                      ],
                    ),
                    if (outpost.luma_event_id != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _LumaIconButton(),
                      )
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class MembersList extends GetView<OutpostDetailController> {
  const MembersList({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final members = controller.membersList.value;
      // add my user to the top if it doesn't exist in the list

      if (members.length == 0) {
        return const Expanded(
          child: const Center(
            child: const LoadingWidget(),
          ),
        );
      }

      return Expanded(
        child: UserList(
          liveUsersList: members,
          onRequestUpdate: (userId) {
            controller.updatedFollowDataForMember(userId);
          },
        ),
      );
    });
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
      final lumaEventDetails = controller.lumaEventDetails.value;
      final image = lumaEventDetails?.event.cover_url;
      return IconButton(
        onPressed: () {
          if (isGettingLumaEventDetails || isGettingLumaEventGuests) return;
          openLumaDetailsDialog();
        },
        icon: isGettingLumaEventDetails || isGettingLumaEventGuests
            ? const SizedBox(
                width: 80,
                height: 80,
                child: LoadingWidget(
                  size: 14,
                ),
              )
            : image != null
                ? Img(
                    src: image,
                    size: 80,
                    alt: 'luma event',
                  )
                : Assets.images.lumaPng.image(width: 80, height: 80),
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
                  final loadingInviteId = controller.loadingInviteId.value;
                  final liveInvitedMembers =
                      controller.liveInvitedMembers.value;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userInInvitedList = liveInvitedMembers[user.uuid];
                      if (userInInvitedList != null) {
                        final invitedToSpeak = userInInvitedList.can_speak;
                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                user.name ?? '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Text(
                                'Invited ${invitedToSpeak ? 'to speak' : 'to listen'}',
                                style: TextStyle(
                                  color: invitedToSpeak
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
                            contentPadding: EdgeInsets.zero,
                            leading: Img(
                              src: user.image ?? '',
                              size: 32,
                              alt: user.name,
                            ),
                            title: Text(
                              user.name ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (canInviteToSpeak)
                                  SizedBox(
                                      width: 100,
                                      child: Button(
                                        loading: loadingInviteId ==
                                            user.uuid + 'true',
                                        type: ButtonType.outline,
                                        size: ButtonSize.SMALL,
                                        onPressed: () {
                                          controller
                                              .inviteUserToJoinThisOutpost(
                                            userId: user.uuid,
                                            inviteToSpeak: true,
                                          );
                                        },
                                        text: 'Invite to speak',
                                      )),
                                space5,
                                SizedBox(
                                  width: 100,
                                  child: Button(
                                    loading:
                                        loadingInviteId == user.uuid + 'false',
                                    type: ButtonType.outline,
                                    size: ButtonSize.SMALL,
                                    text: 'Invite to listen',
                                    onPressed: () {
                                      controller.inviteUserToJoinThisOutpost(
                                        userId: user.uuid,
                                        inviteToSpeak: false,
                                      );
                                    },
                                  ),
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
