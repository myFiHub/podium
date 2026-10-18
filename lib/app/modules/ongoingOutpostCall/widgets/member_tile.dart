import 'package:flutter/material.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
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
            const Positioned.fill(
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.all(ring),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: speaking ? callSpeakingColor : ColorName.cardBorder,
                width: ring,
              ),
            ),
            child: Img(
              src: memberAvatar(member),
              alt: member.name,
              size: size,
              borderRadius: BorderRadius.circular(size),
            ),
          ),
          Positioned.fill(child: ConfettiDetector(userId: member.uuid)),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openMemberSheet(member.uuid),
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
              fontSize: onStage ? 12 : 11,
              fontWeight: onStage ? FontWeight.w600 : FontWeight.w400,
              color: isMe ? ColorName.primaryBlue : Colors.white,
            ),
          ),
          if (onStage) _TalkTimeLabel(member: member, isCreator: isCreator),
        ],
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
        style: TextStyle(fontSize: 10, color: callAccentColor),
      );
    }
    final time = member.remaining_time;
    final low = time < 120;
    return Text(
      time <= 0 ? 'time up' : formatTalkTime(time),
      style: TextStyle(
        fontSize: 10,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: low ? callDangerColor : ColorName.greyText,
      ),
    );
  }
}
