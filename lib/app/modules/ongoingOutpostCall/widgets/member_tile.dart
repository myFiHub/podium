import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outpost_call_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_interactions.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/member_sheet.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:pulsator/pulsator.dart';

class MemberAvatar extends StatelessWidget {
  final LiveMember member;
  final double size;
  final bool isCreator;
  final bool showMicBadge;
  const MemberAvatar({
    super.key,
    required this.member,
    required this.size,
    required this.isCreator,
    this.showMicBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final speaking = member.is_speaking;
    final ring = size * 0.06 + 1.5;
    final box = size + ring * 4;
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (speaking)
            // Animates every frame; keep it from repainting the avatar.
            const Positioned.fill(
              child: RepaintBoundary(
                child: Pulsator(
                  style: PulseStyle(color: callSpeakingColor),
                  duration: Duration(seconds: 2),
                  count: 2,
                  repeat: 0,
                  startFromScratch: false,
                  autoStart: true,
                  fit: PulseFit.contain,
                ),
              ),
            ),
          _VoiceRing(
            uuid: member.uuid,
            ring: ring,
            size: size,
            speaking: speaking,
            child: Img(
              src: memberAvatar(member),
              alt: member.name,
              size: size,
              borderRadius: BorderRadius.circular(size),
            ),
          ),
          Positioned.fill(child: ConfettiDetector(userId: member.uuid)),
          Positioned(top: 0, right: 0, child: _HandBadge(uuid: member.uuid)),
          if (isCreator)
            const Positioned(
              top: 0,
              left: 0,
              child: _Badge(
                color: callAccentColor,
                icon: Icons.star_rounded,
                iconColor: Colors.black,
              ),
            ),
          if (showMicBadge)
            Positioned(
              bottom: 0,
              right: 0,
              child: _Badge(
                color: speaking ? callSpeakingColor : ColorName.cardBackground,
                icon: speaking ? Icons.mic_rounded : Icons.mic_off_rounded,
                iconColor: speaking ? Colors.black : ColorName.greyText,
              ),
            ),
        ],
      ),
    );
  }
}

class _VoiceRing extends StatelessWidget {
  final String uuid;
  final double ring;
  final double size;
  final bool speaking;
  final Widget child;
  const _VoiceRing({
    required this.uuid,
    required this.ring,
    required this.size,
    required this.speaking,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final room = findCallRoom();
    Widget ringFor(double level) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(ring),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: speaking || level > 0.05
                  ? callSpeakingColor
                  : ColorName.cardBorder,
              width: ring,
            ),
            boxShadow: level > 0.05
                ? [
                    BoxShadow(
                      color: callSpeakingColor.withAlpha(140),
                      blurRadius: 6 + level * size * 0.3,
                      spreadRadius: level * size * 0.12,
                    ),
                  ]
                : const [],
          ),
          child: child,
        );
    if (room == null) return ringFor(0);
    return Obx(() => ringFor(room.levelOf(uuid)));
  }
}

class _HandBadge extends StatelessWidget {
  final String uuid;
  const _HandBadge({required this.uuid});

  @override
  Widget build(BuildContext context) {
    final room = findCallRoom();
    if (room == null) return const SizedBox.shrink();
    return Obx(() {
      if (!room.isHandRaised(uuid)) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: callAccentColor,
          shape: BoxShape.circle,
          border: Border.all(color: ColorName.pageBackground, width: 2),
        ),
        child: const Text('✋', style: TextStyle(fontSize: 11)),
      );
    });
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  const _Badge({
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: ColorName.pageBackground, width: 2),
      ),
      child: Icon(icon, size: 12, color: iconColor),
    );
  }
}

class MemberTile extends StatelessWidget {
  final LiveMember member;
  final bool isCreator;
  final bool onStage;
  const MemberTile({
    super.key,
    required this.member,
    required this.isCreator,
    required this.onStage,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = member.uuid == myId;
    final name = isMe ? 'You' : (member.name ?? 'User');
    return Semantics(
      button: true,
      label: isCreator ? '$name, host' : name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openMemberSheet(member.uuid),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MemberAvatar(
                member: member,
                size: onStage ? 60 : 44,
                isCreator: isCreator,
                showMicBadge: onStage,
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: onStage ? FontWeight.w600 : FontWeight.w400,
                  color: isMe ? ColorName.primaryBlue : Colors.white,
                ),
              ),
              if (onStage)
                _TalkTimeLabel(member: member, isCreator: isCreator),
            ],
          ),
        ),
      ),
    );
  }
}

class _TalkTimeLabel extends StatelessWidget {
  final LiveMember member;
  final bool isCreator;
  const _TalkTimeLabel({required this.member, required this.isCreator});

  @override
  Widget build(BuildContext context) {
    if (isCreator) {
      return const Text(
        'Host',
        style: TextStyle(fontSize: 12, color: callAccentColor),
      );
    }
    return TalkTimeBuilder(builder: (context) {
      final time = member.remaining_time;
      final low = time < 120;
      return Text(
        time <= 0 ? 'time up' : formatTalkTime(time),
        style: TextStyle(
          fontSize: 12,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: low ? callDangerColor : ColorName.greyText,
        ),
      );
    });
  }
}

/// Rebuilds [builder] on every local talk-time countdown tick, since
/// [LiveMember.remaining_time] is decremented in place.
class TalkTimeBuilder extends StatelessWidget {
  final WidgetBuilder builder;
  const TalkTimeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<OutpostCallController>()) return builder(context);
    final tick = Get.find<OutpostCallController>().talkTimeTick;
    return Obx(() {
      tick.value;
      return builder(context);
    });
  }
}
