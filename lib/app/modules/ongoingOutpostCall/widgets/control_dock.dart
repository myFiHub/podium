import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/chat_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/more_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/participants_sheet.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/voice_level.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class ControlDock extends GetView<OngoingOutpostCallController> {
  const ControlDock({super.key});

  @override
  Widget build(BuildContext context) {
    final callController = Get.find<OutpostCallController>();
    return Container(
      decoration: BoxDecoration(
        color: ColorName.navbarBackground.withAlpha(235),
        border: Border(top: BorderSide(color: ColorName.cardBorder)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Obx(() {
            final outpost = callController.outpost.value;
            if (outpost == null) return const SizedBox(height: 72);
            final room = findCallRoom();
            final memberCount = callController.members.value.length;
            final hasRoom = room?.channelAvailable.value ?? false;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (room != null) const _ReactButton(),
                if (hasRoom)
                  const _HandButton()
                else
                  DockButton(
                    icon: Icons.people_alt_outlined,
                    label: 'People',
                    badge: memberCount > 0 ? '$memberCount' : null,
                    onPressed: openParticipantsSheet,
                  ),
                const MicButton(),
                if (room != null) const _ChatButton(),
                DockButton(
                  icon: Icons.more_horiz_rounded,
                  label: 'More',
                  onPressed: () {
                    room?.reactionTrayOpen.value = false;
                    openMoreSheet();
                  },
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

Future<void> confirmLeave(OutpostCallController callController) async {
  final leave = await showAppConfirm(
    title: 'Leave this outpost?',
    message: 'You can rejoin later while the outpost is still live.',
    confirmLabel: 'Leave',
    cancelLabel: 'Stay',
    destructive: true,
  );
  if (leave) {
    callController.leaveCall();
  }
}

class DockButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  Color get _color => color ?? ColorName.white;

  final bool filled;
  final String? badge;
  final Widget? iconWidget;
  const DockButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
    this.filled = false,
    this.badge,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: filled ? _color : ColorName.white.withAlpha(16),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPressed == null
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          onPressed!();
                        },
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: iconWidget ??
                          Icon(
                            icon,
                            size: 22,
                            color: filled ? ColorName.white : _color,
                          ),
                    ),
                  ),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: ColorName.primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: ColorName.greyText),
          ),
        ],
      ),
    );
  }
}

class MicButton extends GetView<OngoingOutpostCallController> {
  const MicButton({super.key});

  @override
  Widget build(BuildContext context) {
    final callController = Get.find<OutpostCallController>();
    return Obx(() {
      final canTalk = callController.canTalk.value;
      final muted = controller.amIMuted.value;
      final outOfTime = controller.isOutOfTime;
      final connecting = !controller.isConferenceJoined.value;
      final disabled = !canTalk || outOfTime || connecting;
      final live = !disabled && !muted;

      final Color background = disabled
          ? ColorName.white.withAlpha(16)
          : live
              ? callSpeakingColor
              : ColorName.white;
      final Color foreground = disabled
          ? ColorName.greyText
          : live
              ? ColorName.white
              : ColorName.pageBackground;
      final label = connecting
          ? 'Connecting'
          : !canTalk
              ? 'Listening'
              : outOfTime
                  ? "Time's up"
                  : live
                      ? 'Live'
                      : 'Tap to talk';

      final button = AnimatedContainer(
        key: controller.muteUnmuteKey,
        duration: const Duration(milliseconds: 200),
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: live ? null : background,
          gradient: live ? AppGradients.aurora : null,
          shape: BoxShape.circle,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.mediumImpact();
              controller.toggleMyMic();
            },
            child: connecting
                ? Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: ColorName.greyText,
                      ),
                    ),
                  )
                : Icon(
                    disabled || muted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    size: 30,
                    color: foreground,
                  ),
          ),
        ),
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VoiceLevelBuilder(
            uuid: myId,
            builder: (context, level) => AppBreathing(
              active: live,
              builder: (context, breath) {
                final v = live ? math.max(breath * 0.5, level * 1.4) : 0.0;
                final glow = v.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: 1 + (live ? 0.06 * level : 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: live
                          ? [
                              BoxShadow(
                                color: AppColors.violet
                                    .withAlpha(70 + (90 * glow).round()),
                                blurRadius: 16 + 18 * glow,
                                spreadRadius: 1 + 6 * glow,
                              ),
                              BoxShadow(
                                color: AppColors.primary
                                    .withAlpha(40 + (60 * glow).round()),
                                blurRadius: 12,
                                offset: const Offset(-4, -2),
                              ),
                            ]
                          : const [],
                    ),
                    child: button,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: live ? AppColors.violet : ColorName.greyText,
            ),
          ),
        ],
      );
    });
  }
}

class _ReactButton extends GetView<CallRoomController> {
  const _ReactButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final open = controller.reactionTrayOpen.value;
      return DockButton(
        icon: open ? Icons.close_rounded : Icons.add_reaction_outlined,
        label: 'React',
        color: open ? ColorName.primaryBlue : ColorName.white,
        onPressed: () => controller.reactionTrayOpen.value = !open,
      );
    });
  }
}

class _HandButton extends GetView<CallRoomController> {
  const _HandButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final raised = controller.myHandRaised;
      return DockButton(
        icon: raised ? Icons.back_hand_rounded : Icons.back_hand_outlined,
        label: raised ? 'Lower' : 'Raise',
        color: raised ? callAccentColor : ColorName.white,
        filled: raised,
        onPressed: controller.toggleHand,
      );
    });
  }
}

class _ChatButton extends GetView<CallRoomController> {
  const _ChatButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final unread = controller.unreadTotal;
      return DockButton(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Chat',
        badge: unread == 0
            ? null
            : unread > 99
                ? '99+'
                : '$unread',
        onPressed: () {
          controller.reactionTrayOpen.value = false;
          openChatSheet();
        },
      );
    });
  }
}
