import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:podium/gen/colors.gen.dart';

/// Aurora look: brand gradients, the drifting glow background and the small
/// motion helpers used across screens. Every animation here is skipped when
/// the system "reduce motion" setting is on.

class AppGradients {
  AppGradients._();

  static const primary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [ColorName.primaryBlue, ColorName.auroraViolet],
  );

  static const aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ColorName.primaryBlue,
      ColorName.auroraViolet,
      ColorName.auroraMagenta,
    ],
  );

  static const ring = SweepGradient(
    colors: [
      ColorName.primaryBlue,
      ColorName.auroraViolet,
      ColorName.auroraMagenta,
      ColorName.primaryBlue,
    ],
  );
}

bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Deep navy page background with slowly drifting cyan, violet and magenta
/// glows.
class AuroraBackground extends StatefulWidget {
  final Widget child;

  /// Strength of the glows, 0..1.
  final double intensity;
  const AuroraBackground({
    super.key,
    required this.child,
    this.intensity = 1,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _AuroraPainter(_controller, widget.intensity),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Blob {
  final Color color;
  final Offset anchor;
  final Offset drift;
  final double radius;
  final double phase;
  final int alpha;
  const _Blob(
    this.color,
    this.anchor,
    this.drift,
    this.radius,
    this.phase,
    this.alpha,
  );
}

class _AuroraPainter extends CustomPainter {
  final Animation<double> animation;
  final double intensity;
  _AuroraPainter(this.animation, this.intensity) : super(repaint: animation);

  static const _base = ColorName.pageBackground;
  static const _blobs = [
    _Blob(ColorName.primaryBlue, Offset(0.1, 0.05), Offset(0.18, 0.08), 0.75,
        0.0, 70),
    _Blob(ColorName.auroraViolet, Offset(0.95, 0.3), Offset(0.15, 0.12), 0.8,
        0.33, 80),
    _Blob(ColorName.auroraMagenta, Offset(0.15, 0.85), Offset(0.2, 0.1), 0.7,
        0.66, 55),
    _Blob(ColorName.primaryBlue, Offset(0.85, 0.95), Offset(0.12, 0.08), 0.55,
        0.5, 35),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _base);
    final t = animation.value * 2 * math.pi;
    final extent = size.longestSide;
    for (final blob in _blobs) {
      final angle = t + blob.phase * 2 * math.pi;
      final center = Offset(
        (blob.anchor.dx + math.sin(angle) * blob.drift.dx) * size.width,
        (blob.anchor.dy + math.cos(angle * 0.8) * blob.drift.dy) * size.height,
      );
      final radius =
          extent * blob.radius * (0.92 + 0.08 * math.sin(angle * 1.3));
      final alpha = (blob.alpha * intensity).round().clamp(0, 255);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blob.color.withAlpha(alpha),
            blob.color.withAlpha(alpha ~/ 3),
            blob.color.withAlpha(0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}

/// Fades and slides [child] in once, staggered by [index]. Items that already
/// played (tracked by [id]) appear instantly when rebuilt, e.g. on scroll back.
class AppEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Object? id;
  const AppEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.id,
  });

  static final Set<Object> _played = {};

  @override
  State<AppEntrance> createState() => _AppEntranceState();
}

class _AppEntranceState extends State<AppEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    final id = widget.id;
    final alreadyPlayed = id != null && !AppEntrance._played.add(id);
    if (alreadyPlayed || reduceMotion(context)) {
      _controller.value = 1;
      return;
    }
    final delay = Duration(milliseconds: 60 * widget.index.clamp(0, 6));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Shrinks [child] slightly while pressed.
class AppPressScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double scale;
  const AppPressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
  });

  @override
  State<AppPressScale> createState() => _AppPressScaleState();
}

class _AppPressScaleState extends State<AppPressScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || reduceMotion(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Repeating 0..1..0 value for breathing glows and pulses.
class AppBreathing extends StatefulWidget {
  final bool active;
  final Duration period;
  final Widget Function(BuildContext context, double value) builder;
  const AppBreathing({
    super.key,
    required this.builder,
    this.active = true,
    this.period = const Duration(milliseconds: 1600),
  });

  @override
  State<AppBreathing> createState() => _AppBreathingState();
}

class _AppBreathingState extends State<AppBreathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.period);

  void _sync() {
    if (widget.active && !reduceMotion(context)) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = widget.active ? 0.5 : 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(AppBreathing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(
        context,
        Curves.easeInOut.transform(_controller.value),
      ),
    );
  }
}

/// Sweeps a soft light band across [child] after [delay], then every
/// [interval].
class AppSheen extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final Duration delay;
  final Duration interval;
  const AppSheen({
    super.key,
    required this.child,
    required this.borderRadius,
    this.delay = const Duration(milliseconds: 1200),
    this.interval = const Duration(seconds: 7),
  });

  @override
  State<AppSheen> createState() => _AppSheenState();
}

class _AppSheenState extends State<AppSheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (reduceMotion(context)) {
      _controller.value = 0;
      return;
    }
    _schedule(widget.delay);
  }

  void _schedule(Duration wait) {
    _timer = Timer(wait, () {
      if (!mounted) return;
      _controller.forward(from: 0).whenComplete(() {
        if (mounted) _schedule(widget.interval);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: RepaintBoundary(
                child: CustomPaint(painter: _SheenPainter(_controller)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheenPainter extends CustomPainter {
  final Animation<double> animation;
  _SheenPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t == 0 || t == 1) return;
    final band = size.width * 0.35;
    final x = -band + (size.width + band * 2) * Curves.easeInOut.transform(t);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withAlpha(0),
          Colors.white.withAlpha(90),
          Colors.white.withAlpha(0),
        ],
      ).createShader(
        Rect.fromPoints(
          Offset(x - band, 0),
          Offset(x + band, size.height),
        ),
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_SheenPainter oldDelegate) => false;
}

/// Text that rolls vertically (old value up and out, new value in from below)
/// whenever [text] changes.
class AppRollingText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final AlignmentGeometry alignment;
  const AppRollingText(
    this.text, {
    super.key,
    this.style,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    final key = ValueKey(text);
    return AnimatedSwitcher(
      duration: reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => ClipRect(
        child: Stack(
          alignment: alignment,
          children: [...previous, if (current != null) current],
        ),
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == key;
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, incoming ? 0.6 : -0.6),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        text,
        key: key,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Circular outline; uses [gradient] when set, otherwise a solid [color].
class RingPainter extends CustomPainter {
  final double strokeWidth;
  final Gradient? gradient;
  final Color color;
  const RingPainter({
    required this.strokeWidth,
    this.gradient,
    this.color = ColorName.cardBorder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    } else {
      paint.color = color;
    }
    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  bool shouldRepaint(RingPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gradient != gradient ||
      oldDelegate.color != color;
}

/// Thin luminous gradient outline for glass cards.
class GradientBorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final Gradient gradient;
  const GradientBorderPainter({
    required this.radius,
    this.strokeWidth = 1,
    this.gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x7054E4EF),
        Color(0x308B5CF6),
        Color(0x14FFFFFF),
        Color(0x40FF4FD8),
      ],
      stops: [0, 0.35, 0.7, 1],
    ),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = gradient.createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(GradientBorderPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gradient != gradient;
}
