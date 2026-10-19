import 'dart:math' as math;
import 'package:podium/utils/palette.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/widgets/ui/app_ui.dart';

/// Rebuilds [builder] with [uuid]'s live microphone level (0..1), eased
/// between the room's coarse level updates. Always 0 outside a call room.
class VoiceLevelBuilder extends StatelessWidget {
  final String uuid;
  final Widget Function(BuildContext context, double level) builder;
  const VoiceLevelBuilder({
    super.key,
    required this.uuid,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final room = findCallRoom();
    if (room == null) return builder(context, 0);
    return Obx(() {
      final target = room.levelOf(uuid);
      return TweenAnimationBuilder<double>(
        tween: Tween(end: target),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        builder: (context, level, _) => builder(context, level),
      );
    });
  }
}

/// Tiny equalizer whose bars dance with [level]. Bars rest at a short height
/// while silent and only animate while there is sound.
class VoiceBars extends StatefulWidget {
  final double level;
  final Color? color;
  Color get _color => color ?? ColorName.white;

  final double height;
  final int bars;
  const VoiceBars({
    super.key,
    required this.level,
    this.color,
    this.height = 12,
    this.bars = 3,
  });

  @override
  State<VoiceBars> createState() => _VoiceBarsState();
}

class _VoiceBarsState extends State<VoiceBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool get _audible => widget.level > 0.04;

  void _sync() {
    if (_audible && !reduceMotion(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(VoiceBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barWidth = widget.height / 5;
    final gap = barWidth * 0.7;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(
          widget.bars * barWidth + (widget.bars - 1) * gap,
          widget.height,
        ),
        painter: _VoiceBarsPainter(
          animation: _controller,
          level: widget.level,
          color: widget._color,
          bars: widget.bars,
          barWidth: barWidth,
          gap: gap,
        ),
      ),
    );
  }
}

class _VoiceBarsPainter extends CustomPainter {
  final Animation<double> animation;
  final double level;
  final Color color;
  final int bars;
  final double barWidth;
  final double gap;
  _VoiceBarsPainter({
    required this.animation,
    required this.level,
    required this.color,
    required this.bars,
    required this.barWidth,
    required this.gap,
  }) : super(repaint: animation);

  static const _rest = 0.22;
  static const _weights = [0.7, 1.0, 0.8, 0.6];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final t = animation.value * 2 * math.pi;
    for (var i = 0; i < bars; i++) {
      final wobble = 0.65 + 0.35 * math.sin(t * (1 + i * 0.35) + i * 1.9);
      final energy = (level * 1.6).clamp(0.0, 1.0);
      final fraction =
          _rest + (1 - _rest) * energy * _weights[i % _weights.length] * wobble;
      final h = size.height * fraction.clamp(_rest, 1.0);
      final x = i * (barWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - h) / 2, barWidth, h),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_VoiceBarsPainter oldDelegate) =>
      oldDelegate.level != level ||
      oldDelegate.color != color ||
      oldDelegate.bars != bars;
}

/// Soft cyan/violet glow behind an avatar whose size and strength follow
/// [level]. Cheaper than animating a blurred box shadow.
class VoiceHaloPainter extends CustomPainter {
  final double level;
  final double inset;
  const VoiceHaloPainter({required this.level, required this.inset});

  @override
  void paint(Canvas canvas, Size size) {
    if (level <= 0.03) return;
    final center = size.center(Offset.zero);
    final base = size.shortestSide / 2 - inset;
    final radius = base + inset * (0.6 + 1.6 * level);
    final strength = (level * 1.4).clamp(0.0, 1.0);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.violet.withAlpha((170 * strength).round()),
          AppColors.primary.withAlpha((90 * strength).round()),
          AppColors.primary.withAlpha(0),
        ],
        stops: [base / radius * 0.92, (base / radius + 1) / 2, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(VoiceHaloPainter oldDelegate) =>
      oldDelegate.level != level || oldDelegate.inset != inset;
}
