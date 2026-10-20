import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:podium/utils/palette.dart';

/// Aurora look: brand gradients, the drifting glow background and the small
/// motion helpers used across screens. Every animation here is skipped when
/// the system "reduce motion" setting is on.

class AppGradients {
  AppGradients._();

  static LinearGradient get primary => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [ColorName.primaryBlue, ColorName.auroraViolet],
      );

  static LinearGradient get aurora => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ColorName.primaryBlue,
          ColorName.auroraViolet,
          ColorName.auroraMagenta,
        ],
      );

  static SweepGradient get ring => SweepGradient(
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

class _AuroraBackgroundState extends State<AuroraBackground> {
  static const _period = Duration(seconds: 28);

  /// The glows drift over [_period], so ~20 fps looks the same as the
  /// display rate at a fraction of the paint cost.
  static const _frameInterval = Duration(milliseconds: 50);

  /// Shared by every page's background so a route transition shows the same
  /// glows on both pages. Runs while at least one background is animating.
  static final _clock = Stopwatch();
  static int _running = 0;

  /// Drift cycles elapsed. Not wrapped to 0..1 because the painter's
  /// non-integer harmonics would jump at the wrap.
  static double get _cycles =>
      _clock.elapsedMilliseconds / _period.inMilliseconds;

  final _phase = ValueNotifier<double>(_cycles);
  Timer? _timer;
  late final AppLifecycleListener _lifecycle;
  bool _tickerEnabled = true;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: (_) => _sync());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // False while the route is covered by another page.
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    _reduceMotion = reduceMotion(context);
    _sync();
  }

  void _sync() {
    final state = WidgetsBinding.instance.lifecycleState;
    final foreground = state == null ||
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    final run = _tickerEnabled && !_reduceMotion && foreground;
    if (run && _timer == null) {
      if (_running++ == 0) _clock.start();
      _phase.value = _cycles;
      _timer = Timer.periodic(_frameInterval, (_) => _phase.value = _cycles);
    } else if (!run && _timer != null) {
      _stop();
    }
  }

  void _stop() {
    _timer!.cancel();
    _timer = null;
    if (--_running == 0) _clock.stop();
  }

  @override
  void dispose() {
    if (_timer != null) _stop();
    _lifecycle.dispose();
    _phase.dispose();
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
              painter: _AuroraPainter(_phase, widget.intensity),
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
  final ValueListenable<double> phase;
  final double intensity;
  final AppPalette palette = AppPalette.current;
  _AuroraPainter(this.phase, this.intensity) : super(repaint: phase);

  static List<_Blob> get _blobs => [
        _Blob(ColorName.primaryBlue, const Offset(0.1, 0.05),
            const Offset(0.18, 0.08), 0.75, 0.0, 70),
        _Blob(ColorName.auroraViolet, const Offset(0.95, 0.3),
            const Offset(0.15, 0.12), 0.8, 0.33, 80),
        _Blob(ColorName.auroraMagenta, const Offset(0.15, 0.85),
            const Offset(0.2, 0.1), 0.7, 0.66, 55),
        _Blob(ColorName.primaryBlue, const Offset(0.85, 0.95),
            const Offset(0.12, 0.08), 0.55, 0.5, 35),
      ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = ColorName.pageBackground,
    );
    final glow = intensity * AppPalette.current.glow;
    if (glow <= 0) return;
    final t = phase.value * 2 * math.pi;
    final extent = size.longestSide;
    for (final blob in _blobs) {
      final angle = t + blob.phase * 2 * math.pi;
      final center = Offset(
        (blob.anchor.dx + math.sin(angle) * blob.drift.dx) * size.width,
        (blob.anchor.dy + math.cos(angle * 0.8) * blob.drift.dy) * size.height,
      );
      final radius =
          extent * blob.radius * (0.92 + 0.08 * math.sin(angle * 1.3));
      final alpha = (blob.alpha * glow).round().clamp(0, 255);
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
      oldDelegate.intensity != intensity || oldDelegate.palette != palette;
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
    if (alreadyPlayed || reduceMotion(context) || _revealedByScroll()) {
      _controller.value = 1;
      return;
    }
    final delay = Duration(milliseconds: 60 * widget.index.clamp(0, 6));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  /// Items scrolled into view appear in place; animating them would make the
  /// list look like it stutters under the finger.
  bool _revealedByScroll() {
    final position = Scrollable.maybeOf(context)?.position;
    if (position == null ||
        !position.hasPixels ||
        !position.hasContentDimensions) {
      return false;
    }
    return position.pixels > position.minScrollExtent ||
        position.isScrollingNotifier.value;
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

/// Pops a dialog in with a slight overshoot and sinks it back out on close,
/// following the enclosing dialog route's animation.
class AppDialogMotion extends StatelessWidget {
  final Widget child;
  const AppDialogMotion({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || reduceMotion(context)) return child;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final closing = animation.status == AnimationStatus.reverse;
        final t = animation.value;
        final scale =
            (closing ? Curves.easeInCubic : Curves.easeOutBack).transform(t);
        final lift =
            (closing ? Curves.easeInCubic : Curves.easeOutCubic).transform(t);
        return Transform.translate(
          offset: Offset(0, 28 * (1 - lift)),
          child: Transform.scale(scale: 0.88 + 0.12 * scale, child: child),
        );
      },
    );
  }
}

/// Fades and lifts one part of a dialog in after the dialog itself appears,
/// staggered by [index], so the content settles top to bottom.
class AppDialogStagger extends StatelessWidget {
  final Widget child;
  final int index;
  const AppDialogStagger({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || reduceMotion(context)) return child;
    final interval = Interval(
      (0.2 + 0.12 * index).clamp(0.0, 0.7),
      1,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        if (animation.status == AnimationStatus.reverse) return child!;
        final t = interval.transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Pops [child] in with an elastic overshoot after [delay]. With [shake] it
/// then wiggles a few times to draw attention, e.g. for warnings and errors.
class AppPopIn extends StatefulWidget {
  final Widget child;
  final bool shake;
  final Duration delay;
  const AppPopIn({
    super.key,
    required this.child,
    this.shake = false,
    this.delay = const Duration(milliseconds: 120),
  });

  @override
  State<AppPopIn> createState() => _AppPopInState();
}

class _AppPopInState extends State<AppPopIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.shake ? 1200 : 700),
  );
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (reduceMotion(context)) {
      _controller.value = 1;
      return;
    }
    _timer?.cancel();
    _timer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
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
    final popEnd = widget.shake ? 0.5 : 1.0;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final pop = Curves.elasticOut.transform((t / popEnd).clamp(0.0, 1.0));
        var angle = 0.0;
        if (widget.shake && t > 0.4) {
          final s = (t - 0.4) / 0.6;
          angle = math.sin(s * math.pi * 6) * 0.22 * (1 - s);
        }
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(scale: pop, child: child),
        );
      },
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
  Offset? _downAt;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _onDown(PointerDownEvent event) {
    _downAt = event.position;
    _set(true);
  }

  /// A drag that starts on this widget is a scroll, not a press.
  void _onMove(PointerMoveEvent event) {
    final downAt = _downAt;
    if (!_pressed || downAt == null) return;
    final slop =
        computeHitSlop(event.kind, MediaQuery.maybeGestureSettingsOf(context));
    if ((event.position - downAt).distance > slop) _set(false);
  }

  @override
  Widget build(BuildContext context) {
    // Keep the same widget tree when disabled so the child isn't remounted.
    final active = widget.enabled && !reduceMotion(context);
    return Listener(
      onPointerDown: active ? _onDown : null,
      onPointerMove: active ? _onMove : null,
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: active && _pressed ? widget.scale : 1,
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
          ColorName.white.withAlpha(0),
          ColorName.white.withAlpha(90),
          ColorName.white.withAlpha(0),
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
  final Color? color;
  Color get _color => color ?? ColorName.cardBorder;

  const RingPainter({
    required this.strokeWidth,
    this.gradient,
    this.color,
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
      paint.color = _color;
    }
    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  bool shouldRepaint(RingPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gradient != gradient ||
      oldDelegate._color != _color;
}

/// Thin luminous gradient outline for glass cards.
class GradientBorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final Gradient? gradient;
  const GradientBorderPainter({
    required this.radius,
    this.strokeWidth = 1,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = (gradient ?? defaultGradient).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      paint,
    );
  }

  static LinearGradient get defaultGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ColorName.primaryBlue.withAlpha(0x70),
          ColorName.auroraViolet.withAlpha(0x30),
          ColorName.white.withAlpha(0x14),
          ColorName.auroraMagenta.withAlpha(0x40),
        ],
        stops: const [0, 0.35, 0.7, 1],
      );

  @override
  bool shouldRepaint(GradientBorderPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gradient != gradient;
}
