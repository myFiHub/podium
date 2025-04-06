import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AudioTrimmerView extends StatefulWidget {
  final File audioFile;
  final Function(double start, double end) onTrim;
  final VoidCallback onCancel;
  final Function(double start, double end) onSave;

  const AudioTrimmerView({
    super.key,
    required this.audioFile,
    required this.onTrim,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<AudioTrimmerView> createState() => _AudioTrimmerViewState();
}

class _AudioTrimmerViewState extends State<AudioTrimmerView> {
  late Waveform _waveform;
  bool _isLoading = true;
  double _startPosition = 0.0;
  double _endPosition = 1.0;
  double _duration = 0.0;

  @override
  void initState() {
    super.initState();
    _loadWaveform();
  }

  Future<void> _loadWaveform() async {
    try {
      final waveFile = File(p.join((await getTemporaryDirectory()).path,
          '${widget.audioFile.path.split('/').last}.wave'));

      final stream = JustWaveform.extract(
        audioInFile: widget.audioFile,
        waveOutFile: waveFile,
      );

      await for (final progress in stream) {
        if (progress.waveform != null) {
          setState(() {
            _waveform = progress.waveform!;
            _duration = _waveform.duration.inMilliseconds.toDouble();
            _isLoading = false;
          });
          break;
        }
      }
    } catch (e) {
      print('Error loading waveform: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 100,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              // Waveform
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(
                  painter: WaveformPainter(
                    waveform: _waveform,
                    start: Duration.zero,
                    duration: _waveform.duration,
                    waveColor: Colors.blue[700]!,
                  ),
                ),
              ),
              // Selection overlay
              Positioned.fill(
                child: Row(
                  children: [
                    // Start handle
                    GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _startPosition = (_startPosition +
                                  details.delta.dx /
                                      MediaQuery.of(context).size.width)
                              .clamp(0.0, _endPosition - 0.1);
                          widget.onTrim(_startPosition * _duration,
                              _endPosition * _duration);
                        });
                      },
                      child: Container(
                        width: 20,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          border: const Border(
                            right: BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Middle (selected area)
                    Expanded(
                      child: Container(
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    // End handle
                    GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _endPosition = (_endPosition +
                                  details.delta.dx /
                                      MediaQuery.of(context).size.width)
                              .clamp(_startPosition + 0.1, 1.0);
                          widget.onTrim(_startPosition * _duration,
                              _endPosition * _duration);
                        });
                      },
                      child: Container(
                        width: 20,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          border: const Border(
                            left: BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start: ${_formatDuration(Duration(milliseconds: (_startPosition * _duration).toInt()))}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'End: ${_formatDuration(Duration(milliseconds: (_endPosition * _duration).toInt()))}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => widget.onSave(
                    _startPosition * _duration, _endPosition * _duration),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class WaveformPainter extends CustomPainter {
  final Waveform waveform;
  final Duration start;
  final Duration duration;
  final Color waveColor;

  WaveformPainter({
    required this.waveform,
    required this.start,
    required this.duration,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (duration == Duration.zero) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = waveColor;

    double width = size.width;
    double height = size.height;

    // Draw the waveform
    final waveformPixelsPerWindow = waveform.positionToPixel(duration).toInt();
    final waveformPixelsPerDevicePixel = waveformPixelsPerWindow / width;
    final waveformPixelsPerStep = waveformPixelsPerDevicePixel * 3.0;
    final sampleOffset = waveform.positionToPixel(start);
    final sampleStart = -sampleOffset % waveformPixelsPerStep;

    // Find the maximum amplitude in the visible range
    double maxAmplitude = 0;
    for (var i = sampleStart.toDouble();
        i <= waveformPixelsPerWindow + 1.0;
        i += waveformPixelsPerStep) {
      final sampleIdx = (sampleOffset + i).toInt();
      if (sampleIdx >= 0 && sampleIdx < waveform.length) {
        final amplitude =
            (waveform.getPixelMax(sampleIdx) - waveform.getPixelMin(sampleIdx))
                .abs();
        if (amplitude > maxAmplitude) {
          maxAmplitude = amplitude.toDouble();
        }
      }
    }

    // Draw the waveform with normalized amplitude
    for (var i = sampleStart.toDouble();
        i <= waveformPixelsPerWindow + 1.0;
        i += waveformPixelsPerStep) {
      final sampleIdx = (sampleOffset + i).toInt();
      if (sampleIdx >= 0 && sampleIdx < waveform.length) {
        final x = i / waveformPixelsPerDevicePixel;
        final minY =
            normalise(waveform.getPixelMin(sampleIdx), height, maxAmplitude);
        final maxY =
            normalise(waveform.getPixelMax(sampleIdx), height, maxAmplitude);
        canvas.drawLine(
          Offset(x + 2.0 / 2, minY),
          Offset(x + 2.0 / 2, maxY),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.waveform != waveform ||
        oldDelegate.duration != duration ||
        oldDelegate.start != start;
  }

  double normalise(int s, double height, double maxAmplitude) {
    if (maxAmplitude == 0) return height / 2;

    if (waveform.flags == 0) {
      // For 16-bit audio
      final y = (1.0 * s).clamp(-32768.0, 32767.0).toDouble();
      return height / 2 - (y * height / (maxAmplitude * 4));
    } else {
      // For 8-bit audio
      final y = (1.0 * s).clamp(-128.0, 127.0).toDouble();
      return height / 2 - (y * height / (maxAmplitude * 4));
    }
  }
}
