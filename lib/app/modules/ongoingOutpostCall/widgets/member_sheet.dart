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
import 'package:podium/gen/colors.gen.dart';
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
        final member =
            controller.members.value.firstOrNullWhere((m) => m.uuid == userId);
        if (member == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
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
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Cheering yourself adds time to your talk time; the fee is shared with the other members.',
                  style: TextStyle(fontSize: 12, color: ColorName.greyText),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: ColorName.cardBorder),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Get.closeOverlay();
                Get.find<UsersController>().openUserProfile(member.uuid);
              },
              icon: const Icon(Icons.person_outline_rounded, size: 18),
              label: const Text('View profile'),
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
        color: Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorName.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'HOST CONTROLS',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: ColorName.greyText,
              ),
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
  final Color color;
  const _ModButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.white.withAlpha(enabled ? 12 : 4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, size: 20, color: enabled ? color : ColorName.greyText),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? color : ColorName.greyText,
                ),
              ),
            ],
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
                    const _RoleChip(label: '✋ Hand', color: callAccentColor),
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ColorName.greyText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
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
            : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorName.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 18, color: ColorName.greyText),
          const SizedBox(width: 8),
          const Text(
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
