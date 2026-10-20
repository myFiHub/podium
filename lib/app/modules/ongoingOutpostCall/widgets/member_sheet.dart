import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/users_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_tile.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/truncate.dart';

void openMemberSheet(String userId) {
  if (!Get.isRegistered<OngoingOutpostCallController>()) return;
  Get.bottomSheet(
    MemberSheet(userId: userId),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class MemberSheet extends GetView<OngoingOutpostCallController> {
  final String userId;
  const MemberSheet({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CallSheet(
      child: Obx(() {
        controller.outpostCallController.speakingTick.value;
        final member =
            controller.members.value.firstOrNullWhere((m) => m.uuid == userId);
        if (member == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'This member has left the outpost',
                style: TextStyle(color: ColorName.greyText),
              ),
            ),
          );
        }
        final creatorId =
            controller.outpostCallController.outpost.value?.creator_user_uuid;
        final isCreator = member.uuid == creatorId;
        final isMe = member.uuid == myId;
        final room = findCallRoom();
        final handRaised = room?.isHandRaised(member.uuid) ?? false;
        final canModerate = !isMe &&
            room != null &&
            room.canModerate &&
            room.jitsiIdOf(member.uuid) != null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              member: member,
              isCreator: isCreator,
              isMe: isMe,
              handRaised: handRaised,
            ),
            if (canModerate) ...[
              const SizedBox(height: 16),
              _ModerationRow(
                member: member,
                room: room,
                handRaised: handRaised,
              ),
            ],
            const SizedBox(height: 16),
            _TalkTimeRow(member: member, isCreator: isCreator),
            const SizedBox(height: 12),
            ReactionCounts(address: member.address, showEmpty: true),
            const SizedBox(height: 20),
            Row(
              children: [
                if (!isMe) ...[
                  Expanded(
                    child: LikeDislikeButton(userId: member.uuid, isLike: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child:
                        LikeDislikeButton(userId: member.uuid, isLike: false),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: CheerBooButton(userId: member.uuid, cheer: true),
                ),
                if (!isMe) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: CheerBooButton(userId: member.uuid, cheer: false),
                  ),
                ],
              ],
            ),
            if (isMe)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Cheering yourself adds time to your talk time; the fee is shared with the other members.',
                  style: TextStyle(fontSize: 12, color: ColorName.greyText),
                ),
              ),
            const SizedBox(height: 16),
            AppSecondaryButton(
              label: 'View profile',
              icon: Icons.person_outline_rounded,
              onPressed: () {
                Get.closeOverlay();
                Get.find<UsersController>().openUserProfile(member.uuid);
              },
            ),
          ],
        );
      }),
    );
  }
}

class _ModerationRow extends StatelessWidget {
  final LiveMember member;
  final CallRoomController room;
  final bool handRaised;
  const _ModerationRow({
    required this.member,
    required this.room,
    required this.handRaised,
  });

  Future<void> _confirmRemove() async {
    final remove = await Get.dialog<bool>(
      AppDialog(
        title: 'Remove ${member.name ?? 'this member'}?',
        message: 'They will be disconnected from this outpost.',
        icon: Icons.person_remove_rounded,
        iconColor: AppColors.danger,
        urgent: true,
        actions: [
          AppSecondaryButton(
            label: 'Cancel',
            onPressed: () => Get.closeOverlay(result: false),
          ),
          AppPrimaryButton(
            label: 'Remove',
            color: AppColors.danger,
            onPressed: () => Get.closeOverlay(result: true),
          ),
        ],
      ),
    );
    if (remove == true) {
      room.removeParticipant(member.uuid);
      Get.closeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ColorName.white.withAlpha(6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: ColorName.greyText,
                ),
                const SizedBox(width: 6),
                Text('HOST CONTROLS', style: AppText.label),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ModButton(
                  icon: Icons.mic_off_rounded,
                  label: 'Mute',
                  onPressed: member.is_speaking
                      ? () {
                          room.muteParticipant(member.uuid);
                          Toast.info(
                            title: 'Muted',
                            message: '${member.name ?? 'Member'} was muted',
                          );
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModButton(
                  icon: Icons.back_hand_outlined,
                  label: 'Lower hand',
                  onPressed:
                      handRaised ? () => room.lowerHand(member.uuid) : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModButton(
                  icon: Icons.person_remove_outlined,
                  label: 'Remove',
                  color: callDangerColor,
                  onPressed: _confirmRemove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  Color get _color => color ?? ColorName.white;

  const _ModButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = enabled ? _color : ColorName.greyText;
    return AppPressScale(
      enabled: enabled,
      child: Material(
        color: fg.withAlpha(enabled ? 22 : 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: fg.withAlpha(enabled ? 60 : 20)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onPressed == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final LiveMember member;
  final bool isCreator;
  final bool isMe;
  final bool handRaised;
  const _Header({
    required this.member,
    required this.isCreator,
    required this.isMe,
    required this.handRaised,
  });

  @override
  Widget build(BuildContext context) {
    final address = member.aptos_address;
    return Row(
      children: [
        MemberAvatar(member: member, size: 56, isCreator: isCreator),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMe ? 'You' : (member.name ?? 'User'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _RoleChip(
                    label: isCreator
                        ? 'Host'
                        : member.is_speaking
                            ? 'Talking'
                            : 'Member',
                    color: isCreator
                        ? callAccentColor
                        : member.is_speaking
                            ? callSpeakingColor
                            : ColorName.greyText,
                  ),
                  if (handRaised) ...[
                    const SizedBox(width: 6),
                    _RoleChip(label: '✋ Hand', color: callAccentColor),
                  ],
                  const SizedBox(width: 8),
                  if (address.isNotEmpty)
                    Flexible(
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: address));
                          Toast.info(
                            title: 'Copied!',
                            message: 'Address copied to clipboard',
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                truncate(address, length: 10),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ColorName.greyText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.copy_rounded,
                              size: 12,
                              color: ColorName.greyText,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final Color color;
  const _RoleChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppPill(label: label, color: color);
  }
}

class _TalkTimeRow extends StatelessWidget {
  final LiveMember member;
  final bool isCreator;
  const _TalkTimeRow({required this.member, required this.isCreator});

  @override
  Widget build(BuildContext context) {
    return TalkTimeBuilder(builder: _build);
  }

  Widget _build(BuildContext context) {
    final time = member.remaining_time;
    final value = isCreator
        ? 'Unlimited'
        : time <= 0
            ? "Time's up"
            : formatTalkTime(time);
    final color = isCreator
        ? callAccentColor
        : time < 120
            ? callDangerColor
            : ColorName.white;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      decoration: BoxDecoration(
        color: ColorName.white.withAlpha(8),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          AppIconTile(
            icon: Icons.timer_outlined,
            color: isCreator ? callAccentColor : ColorName.greyText,
            size: 34,
          ),
          const SizedBox(width: 10),
          Text(
            'Talk time left',
            style: TextStyle(color: ColorName.greyText, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
