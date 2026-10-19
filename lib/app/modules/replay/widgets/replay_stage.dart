import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/app/modules/replay/controllers/replay_controller.dart';
import 'package:podium/app/services/replay/replay_text.dart';
import 'package:podium/app/services/replay/replay_timeline.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:video_player/video_player.dart';

/// The room at the current moment: screen share, members and reactions.
class ReplayStage extends StatelessWidget {
  const ReplayStage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ScreenPanel(),
                _OfflineNotice(),
                _MemberGrid(),
              ],
            ),
          ),
        ),
        Positioned.fill(child: IgnorePointer(child: _Moments())),
      ],
    );
  }
}

class _ScreenPanel extends GetView<ReplayController> {
  const _ScreenPanel();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final clip = controller.room.value.clip;
      final video = controller.video.value;
      if (clip == null) return const SizedBox.shrink();
      final aspect = video != null && video.value.isInitialized
          ? video.value.aspectRatio
          : (clip.width > 0 && clip.height > 0
              ? clip.width / clip.height
              : 16 / 9);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: ColoredBox(
                color: Colors.black,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                  ),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: aspect,
                      child: video == null
                          ? const Center(child: CircularProgressIndicator())
                          : VideoPlayer(video),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.screen_share_rounded,
                  size: 14,
                  color: ColorName.greyText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    clip.sharerName.isEmpty
                        ? 'Screen share'
                        : "${clip.sharerName}'s screen",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _OfflineNotice extends GetView<ReplayController> {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.room.value.online) return const SizedBox.shrink();
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: AppCallout(
          text: 'The recorder lost its connection here, so who is speaking '
              'may be out of date.',
          icon: Icons.wifi_off_rounded,
        ),
      );
    });
  }
}

class _MemberGrid extends GetView<ReplayController> {
  const _MemberGrid();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.room.value;
      final hostUuid = controller.meta.value?.outpost.creator.uuid;
      if (state.members.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('Nobody in the room yet')),
        );
      }
      final members = [...state.members]..sort((a, b) {
          final bySpeaking = (b.speaking ? 1 : 0) - (a.speaking ? 1 : 0);
          if (bySpeaking != 0) return bySpeaking;
          return (b.member.canSpeak ? 1 : 0) - (a.member.canSpeak ? 1 : 0);
        });
      return Wrap(
        spacing: 8,
        runSpacing: 14,
        alignment: WrapAlignment.center,
        children: [
          for (final m in members)
            _MemberTile(
              key: ValueKey(m.member.uuid),
              state: m,
              isHost: m.member.uuid == hostUuid,
              isDominant: m.member.uuid == state.dominantSpeakerUuid,
              handRaised: state.raisedHands.contains(m.member.uuid),
            ),
        ],
      );
    });
  }
}

class _MemberTile extends StatelessWidget {
  final ReplayMemberState state;
  final bool isHost;
  final bool isDominant;
  final bool handRaised;

  const _MemberTile({
    super.key,
    required this.state,
    required this.isHost,
    required this.isDominant,
    required this.handRaised,
  });

  @override
  Widget build(BuildContext context) {
    final member = state.member;
    final talking = state.speaking || isDominant;
    final ringColor = talking ? AppColors.success : AppColors.border;
    return SizedBox(
      width: 78,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: talking ? 3 : 1),
                ),
                child: Img(
                  src: member.image ?? '',
                  alt: member.name,
                  size: 54,
                  borderRadius: BorderRadius.circular(54),
                ),
              ),
              if (handRaised)
                const Positioned(
                  right: -2,
                  top: -4,
                  child: Text('✋', style: TextStyle(fontSize: 18)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            member.name.isEmpty ? 'Member' : member.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: ColorName.white),
          ),
          Text(
            isHost
                ? 'Host'
                : member.canSpeak
                    ? ReplayText.clock(
                        Duration(seconds: state.remainingSeconds),
                      )
                    : 'Listener',
            maxLines: 1,
            style: AppText.caption.copyWith(
              fontSize: 11,
              color: state.speaking ? AppColors.success : ColorName.greyText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Moments extends GetView<ReplayController> {
  const _Moments();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Obx(() {
        final shown = controller.moments.toList();
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final moment in shown)
              _FloatingMoment(
                key: ValueKey(moment.id),
                moment: moment,
                height: constraints.maxHeight,
              ),
          ],
        );
      }),
    );
  }
}

class _FloatingMoment extends StatefulWidget {
  final ShownMoment moment;
  final double height;

  const _FloatingMoment({
    super.key,
    required this.moment,
    required this.height,
  });

  @override
  State<_FloatingMoment> createState() => _FloatingMomentState();
}

class _FloatingMomentState extends State<_FloatingMoment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();
  late final Animation<double> _t =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.moment;
    return Positioned(
      right: 16 + shown.lane * 90,
      bottom: 16,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, child) {
          final t = _t.value;
          final opacity = t < 0.1 ? t * 10 : (t > 0.7 ? (1 - t) / 0.3 : 1.0);
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset:
                  Offset(-sin(t * pi * 3) * 12, -t * widget.height * 0.55),
              child: Transform.scale(
                scale: 0.6 + min(t * 4, 1) * 0.5,
                child: child,
              ),
            ),
          );
        },
        child: RepaintBoundary(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                shown.moment.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 160),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  shown.moment.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: ColorName.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
