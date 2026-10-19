import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/ongoing_outpost_call_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/control_dock.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/participants_sheet.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:pulsator/pulsator.dart';

class CallTopBar extends GetView<OngoingOutpostCallController> {
  const CallTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final callController = controller.outpostCallController;
    return Obx(() {
      final outpost = callController.outpost.value;
      if (outpost == null) return const SizedBox(height: 56);
      final iAmCreator = outpost.creator_user_uuid == myId;
      final count = callController.members.value.length;
      final isRecording = controller.recorderUserId.value.isNotEmpty;
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Minimize',
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outpost.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    iAmCreator
                        ? 'Hosted by you'
                        : 'Hosted by ${outpost.creator_user_name ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ColorName.greyText,
                    ),
                  ),
                ],
              ),
            ),
            if (isRecording) const _RecordingPill(),
            _LivePill(count: count),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: callDangerColor,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => confirmLeave(callController),
                child: const Text(
                  'Leave',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _LivePill extends StatelessWidget {
  final int count;
  const _LivePill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Live, $count people. Show participants',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: openParticipantsSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.circle, size: 8, color: callDangerColor),
              const SizedBox(width: 5),
              const Text(
                'LIVE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.people_alt_rounded,
                  size: 14, color: ColorName.greyText),
              const SizedBox(width: 3),
              Text(
                '$count',
                style: const TextStyle(fontSize: 12, color: ColorName.greyText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordingPill extends StatelessWidget {
  const _RecordingPill();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'The host is recording',
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.fromLTRB(2, 2, 8, 2),
        decoration: BoxDecoration(
          color: callDangerColor.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Pulsator(
                style: PulseStyle(color: ColorName.danger),
                duration: Duration(seconds: 2),
                count: 2,
                repeat: 0,
                startFromScratch: false,
                autoStart: true,
                fit: PulseFit.contain,
                child: Icon(Icons.circle, color: ColorName.danger, size: 6),
              ),
            ),
            Text(
              'REC',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: callDangerColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Personal status: role and remaining talk time. Carries the intro's timer key.
class MyStatusCard extends GetView<OngoingOutpostCallController> {
  const MyStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final callController = Get.find<OutpostCallController>();
    return Obx(() {
      final session = controller.mySession.value;
      final isAdmin = controller.amIAdmin.value;
      final canTalk = callController.canTalk.value;
      final muted = controller.amIMuted.value;
      final sharing = controller.isSharingScreen.value;

      final IconData icon;
      final String title;
      final String subtitle;
      final Color color;
      String? trailing;

      if (!controller.isConferenceJoined.value) {
        icon = Icons.wifi_tethering_rounded;
        title = 'Connecting…';
        subtitle = 'Joining the audio room';
        color = ColorName.greyText;
      } else if (session == null) {
        icon = Icons.hourglass_top_rounded;
        title = 'Joining…';
        subtitle = 'Syncing with the outpost';
        color = ColorName.greyText;
      } else if (isAdmin) {
        icon = Icons.star_rounded;
        title = "You're the host";
        subtitle = 'Your talk time is unlimited';
        color = callAccentColor;
      } else if (!canTalk) {
        icon = Icons.headphones_rounded;
        title = "You're listening";
        subtitle = 'You can still react and chat';
        color = ColorName.primaryBlue;
      } else if (session.remaining_time <= 0) {
        icon = Icons.timer_off_outlined;
        title = "Time's up";
        subtitle = 'Earn more time through likes and cheers';
        color = callDangerColor;
        trailing = '00:00';
      } else {
        final low = session.remaining_time < 120;
        final idle = muted && !sharing;
        icon = sharing
            ? Icons.screen_share_rounded
            : muted
                ? Icons.mic_off_rounded
                : Icons.graphic_eq_rounded;
        title = idle ? 'Your talk time' : "You're live";
        subtitle = sharing
            ? 'Sharing your screen uses your talk time'
            : muted
                ? 'Timer runs only while unmuted'
                : 'Your talk time is counting down';
        color = low
            ? callDangerColor
            : idle
                ? Colors.white
                : callSpeakingColor;
        trailing = formatTalkTime(session.remaining_time);
      }

      return Container(
        key: controller.timerKey,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ColorName.cardBackground.withAlpha(200),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ColorName.greyText,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      );
    });
  }
}
