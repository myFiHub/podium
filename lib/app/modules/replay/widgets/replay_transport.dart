import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/replay/controllers/replay_controller.dart';
import 'package:podium/app/services/replay/replay_text.dart';
import 'package:podium/app/services/replay/replay_timeline.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

/// Seek bar with event markers, and the playback controls.
class ReplayTransport extends StatelessWidget {
  const ReplayTransport({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SeekBar(),
          _Controls(),
        ],
      ),
    );
  }
}

class _SeekBar extends GetView<ReplayController> {
  const _SeekBar();

  static const _inset = 14.0;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final duration = controller.durationMs.value;
      final max = duration <= 0 ? 1.0 : duration.toDouble();
      final shown = controller.scrubMs.value ?? controller.positionMs.value;
      final markers = controller.markers.toList();
      final clips = controller.meta.value?.clips ?? const [];
      return Column(
        children: [
          SizedBox(
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  left: _inset,
                  right: _inset,
                  child: CustomPaint(
                    painter: _MarkerPainter(
                      durationMs: duration,
                      markers: markers,
                      shares: [
                        for (final c in clips)
                          (c.startMs, c.endMs ?? duration),
                      ],
                      colors: _MarkerColors(
                        chat: AppColors.primary,
                        reaction: AppColors.magenta,
                        poll: AppColors.accent,
                        share: AppColors.violet,
                        offline: AppColors.danger,
                      ),
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: _inset),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.border,
                    thumbColor: ColorName.white,
                  ),
                  child: Slider(
                    min: 0,
                    max: max,
                    value: shown.clamp(0, max).toDouble(),
                    onChanged: controller.scrubTo,
                    onChangeEnd: controller.endScrub,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _inset),
            child: Row(
              children: [
                Text(
                  ReplayText.clock(Duration(milliseconds: shown)),
                  style: AppText.caption,
                ),
                const Spacer(),
                Text(
                  ReplayText.clock(Duration(milliseconds: duration)),
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _Controls extends GetView<ReplayController> {
  const _Controls();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Obx(
          () => SizedBox(
            width: 64,
            child: TextButton(
              onPressed: controller.cycleSpeed,
              child: Text(
                '${_speedLabel(controller.speed.value)}×',
                style: TextStyle(
                  color: ColorName.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        AppIconButton(
          icon: Icons.replay_10_rounded,
          tooltip: 'Back 10 seconds',
          onTap: () => controller.skip(const Duration(seconds: -10)),
        ),
        const SizedBox(width: 16),
        Obx(
          () => AppIconButton(
            icon: controller.playing.value
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            tooltip: controller.playing.value ? 'Pause' : 'Play',
            size: 58,
            background: AppColors.primary,
            color: AppColors.onPrimary,
            onTap: controller.togglePlay,
          ),
        ),
        const SizedBox(width: 16),
        AppIconButton(
          icon: Icons.forward_10_rounded,
          tooltip: 'Forward 10 seconds',
          onTap: () => controller.skip(const Duration(seconds: 10)),
        ),
        const SizedBox(width: 72),
      ],
    );
  }

  static String _speedLabel(double speed) =>
      speed == speed.roundToDouble() ? speed.toStringAsFixed(0) : '$speed';
}

class _MarkerColors {
  final Color chat;
  final Color reaction;
  final Color poll;
  final Color share;
  final Color offline;

  const _MarkerColors({
    required this.chat,
    required this.reaction,
    required this.poll,
    required this.share,
    required this.offline,
  });
}

class _MarkerPainter extends CustomPainter {
  final int durationMs;
  final List<ReplayMarker> markers;
  final List<(int, int)> shares;
  final _MarkerColors colors;

  _MarkerPainter({
    required this.durationMs,
    required this.markers,
    required this.shares,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (durationMs <= 0) return;
    double x(int t) => (t / durationMs).clamp(0.0, 1.0) * size.width;
    final mid = size.height / 2;

    final sharePaint = Paint()..color = colors.share.withAlpha(110);
    for (final (start, end) in shares) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x(start), mid + 5, x(end), mid + 8),
          const Radius.circular(2),
        ),
        sharePaint,
      );
    }

    final tick = Paint()..strokeWidth = 2;
    for (final marker in markers) {
      final color = switch (marker.kind) {
        ReplayMarkerKind.chat => colors.chat,
        ReplayMarkerKind.reaction => colors.reaction,
        ReplayMarkerKind.poll => colors.poll,
        ReplayMarkerKind.screenShare => null,
        ReplayMarkerKind.offline => colors.offline,
      };
      if (color == null) continue;
      tick.color = color.withAlpha(170);
      canvas.drawLine(Offset(x(marker.t), mid - 9), Offset(x(marker.t), mid - 5), tick);
    }
  }

  @override
  bool shouldRepaint(_MarkerPainter old) =>
      old.durationMs != durationMs ||
      old.markers.length != markers.length ||
      old.shares.length != shares.length;
}
