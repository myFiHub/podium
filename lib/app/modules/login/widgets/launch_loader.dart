import 'dart:math';

import 'package:flutter/material.dart';
import 'package:podium/gen/colors.gen.dart';

const _logoCyan = Color(0xFF4ED6DC);

/// Full-screen loader shown while the saved session is restored. It starts
/// exactly like the native splash (logo centered on the page color) and
/// animates into the branded "please wait" layout.
class LaunchLoader extends StatefulWidget {
  const LaunchLoader({super.key});

  @override
  State<LaunchLoader> createState() => _LaunchLoaderState();
}

class _LaunchLoaderState extends State<LaunchLoader>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  late final Animation<double> _move = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.1, 0.65, curve: Curves.easeInOutCubic),
  );
  late final Animation<double> _title = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _footer = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.65, 1, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ColorName.pageBackground,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          return AnimatedBuilder(
            animation: Listenable.merge([_intro, _loop]),
            builder: (context, _) {
              final t = _move.value;
              final logoSize = 175 - 45 * t;
              final logoCenterY = height / 2 - height * 0.14 * t;
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: logoCenterY - 160,
                    height: 320,
                    child: Center(
                      child: _Glow(progress: t, loop: _loop.value),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: logoCenterY - 160,
                    height: 320,
                    child: CustomPaint(
                      painter: _WavesPainter(
                        loop: _loop.value,
                        intensity: t,
                        baseRadius: logoSize / 2,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: logoCenterY - logoSize / 2,
                    child: Center(
                      child: Transform.scale(
                        scale: 1 + 0.025 * sin(_loop.value * 2 * pi) * t,
                        child: Image.asset(
                          'assets/images/logo_disc.png',
                          width: logoSize,
                          height: logoSize,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    top: logoCenterY + logoSize / 2 + 36,
                    child: Opacity(
                      opacity: _title.value,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - _title.value)),
                        child: const _Title(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 56,
                    child: Opacity(
                      opacity: _footer.value,
                      child: _Footer(loop: _loop.value),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double progress;
  final double loop;
  const _Glow({required this.progress, required this.loop});

  @override
  Widget build(BuildContext context) {
    final pulse = 0.5 + 0.5 * sin(loop * 2 * pi);
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _logoCyan.withValues(alpha: (0.10 + 0.08 * pulse) * progress),
            _logoCyan.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  final double loop;
  final double intensity;
  final double baseRadius;
  _WavesPainter({
    required this.loop,
    required this.intensity,
    required this.baseRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    final center = size.center(Offset.zero);
    const waves = 3;
    for (var i = 0; i < waves; i++) {
      final phase = (loop + i / waves) % 1;
      final radius = baseRadius + 8 + phase * 70;
      final opacity = (1 - phase) * 0.45 * intensity;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _logoCyan.withValues(alpha: opacity),
      );
    }
    final arcRect = Rect.fromCircle(center: center, radius: baseRadius + 8);
    canvas.drawArc(
      arcRect,
      loop * 2 * pi,
      pi * 0.6,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: loop * 2 * pi,
          endAngle: loop * 2 * pi + pi * 0.6,
          colors: [
            _logoCyan.withValues(alpha: 0),
            _logoCyan.withValues(alpha: 0.9 * intensity),
          ],
          transform: GradientRotation(loop * 2 * pi),
        ).createShader(arcRect),
    );
  }

  @override
  bool shouldRepaint(_WavesPainter old) =>
      old.loop != loop ||
      old.intensity != intensity ||
      old.baseRadius != baseRadius;
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Welcome to',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w300,
            color: ColorName.greyText,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Podium',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Where attention pays.',
          style: TextStyle(fontSize: 13, color: ColorName.greyText),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final double loop;
  const _Footer({required this.loop});

  @override
  Widget build(BuildContext context) {
    final dots = (loop * 4).floor() % 4;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 140,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(_logoCyan),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please wait',
              style: TextStyle(fontSize: 13, color: ColorName.greyText),
            ),
            SizedBox(
              width: 18,
              child: Text(
                '.' * dots,
                style: const TextStyle(fontSize: 13, color: ColorName.greyText),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
