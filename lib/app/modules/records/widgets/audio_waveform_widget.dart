import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';

class AudioWaveformWidget extends StatefulWidget {
  final Color waveColor;
  final double scale;
  final double strokeWidth;
  final double pixelsPerStep;
  final Waveform waveform;
  final Duration start;
  final Duration duration;
  final Duration? currentPosition;
  final Function(Duration)? onSeek;

  const AudioWaveformWidget({
    super.key,
    required this.waveform,
    required this.start,
    required this.duration,
    this.currentPosition,
    this.onSeek,
    this.waveColor = Colors.blue,
    this.scale = 1.0,
    this.strokeWidth = 2.0,
    this.pixelsPerStep = 3.0,
  });

  @override
  State<AudioWaveformWidget> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveformWidget> {
  Duration? seekPosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _handleSeek(details.localPosition.dx),
      onPanUpdate: (details) => _handleSeek(details.localPosition.dx),
      onPanEnd: (_) {
        setState(() {
          seekPosition = null;
        });
      },
      onTapUp: (_) {
        setState(() {
          seekPosition = null;
        });
      },
      child: RepaintBoundary(
        child: ClipRect(
          child: CustomPaint(
            painter: AudioWaveformPainter(
              waveColor: widget.waveColor,
              waveform: widget.waveform,
              start: widget.start,
              duration: widget.duration,
              currentPosition: seekPosition ?? widget.currentPosition,
              scale: widget.scale,
              strokeWidth: widget.strokeWidth,
              pixelsPerStep: widget.pixelsPerStep,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  void _handleSeek(double x) {
    final width = context.size?.width ?? 0;
    if (width == 0) return;

    final position = (x / width) * widget.duration.inMilliseconds;
    seekPosition = Duration(milliseconds: position.toInt());
    widget.onSeek?.call(seekPosition!);
    setState(() {});
  }
}

class AudioWaveformPainter extends CustomPainter {
  final double scale;
  final double strokeWidth;
  final double pixelsPerStep;
  final Paint wavePaint;
  final Paint positionPaint;
  final Waveform waveform;
  final Duration start;
  final Duration duration;
  final Duration? currentPosition;

  AudioWaveformPainter({
    required this.waveform,
    required this.start,
    required this.duration,
    this.currentPosition,
    Color waveColor = Colors.blue,
    this.scale = 1.0,
    this.strokeWidth = 2.0,
    this.pixelsPerStep = 3.0,
  })  : wavePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = waveColor,
        positionPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.red;

  @override
  void paint(Canvas canvas, Size size) {
    if (duration == Duration.zero) return;

    double width = size.width;
    double height = size.height;

    // Draw the waveform
    final waveformPixelsPerWindow = waveform.positionToPixel(duration).toInt();
    final waveformPixelsPerDevicePixel = waveformPixelsPerWindow / width;
    final waveformPixelsPerStep = waveformPixelsPerDevicePixel * pixelsPerStep;
    final sampleOffset = waveform.positionToPixel(start);
    final sampleStart = -sampleOffset % waveformPixelsPerStep;

    // Find the maximum amplitude in the visible range
    double maxAmplitude = 0;
    for (var i = sampleStart.toDouble();
        i <= waveformPixelsPerWindow + 1.0;
        i += waveformPixelsPerStep) {
      final sampleIdx = (sampleOffset + i).toInt();
      final amplitude =
          (waveform.getPixelMax(sampleIdx) - waveform.getPixelMin(sampleIdx))
              .abs();
      if (amplitude > maxAmplitude) {
        maxAmplitude = amplitude.toDouble();
      }
    }

    // Draw the waveform with normalized amplitude
    for (var i = sampleStart.toDouble();
        i <= waveformPixelsPerWindow + 1.0;
        i += waveformPixelsPerStep) {
      final sampleIdx = (sampleOffset + i).toInt();
      final x = i / waveformPixelsPerDevicePixel;
      final minY =
          normalise(waveform.getPixelMin(sampleIdx), height, maxAmplitude);
      final maxY =
          normalise(waveform.getPixelMax(sampleIdx), height, maxAmplitude);
      canvas.drawLine(
        Offset(x + strokeWidth / 2, minY),
        Offset(x + strokeWidth / 2, maxY),
        wavePaint,
      );
    }

    // Draw the play position indicator
    if (currentPosition != null) {
      // Calculate position more accurately
      final positionX =
          (currentPosition!.inMilliseconds / duration.inMilliseconds) * width;

      // Draw a slightly thicker line for better visibility
      final indicatorPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.red.withAlpha(100);

      canvas.drawLine(
        Offset(positionX, 0),
        Offset(positionX, height),
        indicatorPaint,
      );

      // Add a small circle at the top and bottom for better visual indication
      canvas.drawCircle(
        Offset(positionX, 0),
        2.0,
        indicatorPaint,
      );
      canvas.drawCircle(
        Offset(positionX, height),
        2.0,
        indicatorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AudioWaveformPainter oldDelegate) {
    return oldDelegate.currentPosition != currentPosition ||
        oldDelegate.waveform != waveform ||
        oldDelegate.duration != duration ||
        oldDelegate.start != start;
  }

  double normalise(int s, double height, double maxAmplitude) {
    if (maxAmplitude == 0) return height / 2;

    if (waveform.flags == 0) {
      // For 16-bit audio
      final y = (scale * s).clamp(-32768.0, 32767.0).toDouble();
      return height / 2 - (y * height / (maxAmplitude * 4));
    } else {
      // For 8-bit audio
      final y = (scale * s).clamp(-128.0, 127.0).toDouble();
      return height / 2 - (y * height / (maxAmplitude * 4));
    }
  }
}
