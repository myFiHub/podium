import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/participants_sheet.dart';
import 'package:podium/app/modules/outpostDetail/views/outpost_detail_view.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/services/toast/toast.dart';

class ControlDock extends GetView<OngoingOutpostCallController> {
  const ControlDock({super.key});

  @override
  Widget build(BuildContext context) {
    final callController = Get.find<OutpostCallController>();
    return Container(
      decoration: BoxDecoration(
        color: ColorName.navbarBackground.withAlpha(235),
        border: const Border(top: BorderSide(color: ColorName.cardBorder)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Obx(() {
            final outpost = callController.outpost.value;
            if (outpost == null) return const SizedBox(height: 72);
            final amICreator = outpost.creator_user_uuid == myId;
            final memberCount = callController.members.value.length;
            final canRecord = amICreator && outpost.is_recordable;
            final invite = canInvite(outpost: outpost, currentUserId: myId)
                ? DockButton(
                    icon: Icons.person_add_alt_1_outlined,
                    label: 'Invite',
                    onPressed: () => openInviteBottomSheet(
                      canInviteToSpeak: canInviteToSpeak(
                        outpost: outpost,
                        currentUserId: myId,
                      ),
                    ),
                  )
                : null;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                DockButton(
                  icon: Icons.people_alt_outlined,
                  label: 'People',
                  badge: memberCount > 0 ? '$memberCount' : null,
                  onPressed: openParticipantsSheet,
                ),
                if (canRecord) const _RecordButton(),
                if (!canRecord && invite != null) invite,
                const MicButton(),
                if (canRecord && invite != null) invite,
                DockButton(
                  icon: Icons.call_end_rounded,
                  label: 'Leave',
                  color: callDangerColor,
                  filled: true,
                  onPressed: () => confirmLeave(callController),
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
  final leave = await Get.dialog<bool>(
    AlertDialog(
      backgroundColor: ColorName.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Leave this outpost?'),
      content: const Text(
        'You can rejoin later while the outpost is still live.',
        style: TextStyle(color: ColorName.greyText),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Stay'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: callDangerColor),
          onPressed: () => Get.back(result: true),
          child: const Text('Leave'),
        ),
      ],
    ),
  );
  if (leave == true) {
    callController.runHome();
  }
}

class DockButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool filled;
  final String? badge;
  final Widget? iconWidget;
  const DockButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.color = Colors.white,
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
                color: filled ? color : Colors.white.withAlpha(16),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPressed,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: iconWidget ??
                          Icon(
                            icon,
                            size: 22,
                            color: filled ? Colors.white : color,
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
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
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
            style: const TextStyle(fontSize: 11, color: ColorName.greyText),
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
      final session = controller.mySession.value;
      final outOfTime = !controller.amIAdmin.value &&
          session != null &&
          session.remaining_time <= 0;
      final disabled = !canTalk || outOfTime;
      final live = !disabled && !muted;

      final Color background = disabled
          ? Colors.white.withAlpha(16)
          : live
              ? callSpeakingColor
              : Colors.white;
      final Color foreground = disabled
          ? ColorName.greyText
          : live
              ? Colors.black
              : ColorName.pageBackground;
      final label = !canTalk
          ? 'Listening'
          : outOfTime
              ? "Time's up"
              : live
                  ? 'Live'
                  : 'Tap to talk';

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            key: controller.muteUnmuteKey,
            duration: const Duration(milliseconds: 200),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              boxShadow: live
                  ? [
                      BoxShadow(
                        color: callSpeakingColor.withAlpha(110),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : const [],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  if (!canTalk) {
                    Toast.info(
                      title: "You're a listener",
                      message: "You can't speak in this outpost",
                    );
                    return;
                  }
                  if (outOfTime && muted) {
                    Toast.error(
                      title: "You've run out of time",
                      message: 'Likes and cheers add more talk time',
                    );
                    return;
                  }
                  controller.setMutedState(!muted);
                },
                child: Icon(
                  disabled || muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  size: 30,
                  color: foreground,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: live ? callSpeakingColor : ColorName.greyText,
            ),
          ),
        ],
      );
    });
  }
}

class _RecordButton extends GetView<OngoingOutpostCallController> {
  const _RecordButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isRecording = controller.isRecording.value;
      final isStarting = controller.isStartingToRecord.value;
      return DockButton(
        icon: isRecording ? Icons.stop_rounded : Icons.fiber_manual_record,
        label: isRecording ? 'Stop rec' : 'Record',
        color: callDangerColor,
        iconWidget: isStarting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        onPressed: isStarting
            ? null
            : () => isRecording
                ? controller.stopRecording()
                : controller.startRecording(),
      );
    });
  }
}
