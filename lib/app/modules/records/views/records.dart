import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:podium/app/modules/records/controllers/records_controller.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:siri_wave/siri_wave.dart';

class BottomSheetBody extends GetView<RecordsController> {
  const BottomSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPlaying = controller.isPlaying.value;
      final file = controller.selectedFile.value;
      if (file == null) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: ColorName.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recording Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900]?.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file.date.toString().split('.')[0],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: StreamBuilder<WaveformProgress>(
                stream: controller.getWaveformProgress(file),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final progress = snapshot.data?.progress ?? 0.0;
                  final waveform = snapshot.data?.waveform;
                  if (waveform == null) {
                    return Center(
                      child: Text(
                        '${(100 * progress).toInt()}%',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      Container(
                        height: 100,
                        width: Get.width - 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Obx(() => AudioWaveformWidget(
                              waveform: waveform,
                              start: Duration.zero,
                              duration: waveform.duration,
                              currentPosition: controller.currentPosition.value,
                              waveColor: Colors.blue[700]!,
                              onSeek: controller.seekToPosition,
                            )),
                      ),
                      Positioned.fill(
                        child: Obx(() {
                          final siriController = IOS9SiriWaveformController()
                            ..amplitude = controller.isPlaying.value ? 1.0 : 0.0
                            ..speed = 0.5
                            ..color1 = Colors.purple[400]!.withAlpha(150)
                            ..color2 = Colors.blue[400]!.withAlpha(150)
                            ..color3 = Colors.teal[400]!.withAlpha(150);
                          return SiriWaveform.ios9(
                            controller: siriController,
                            options: IOS9SiriWaveformOptions(
                              height: 100,
                              width: Get.width - 32,
                              showSupportBar: false,
                            ),
                          );
                        }),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            iconSize: 16,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.content_cut,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              // Initialize trim times
                              Toast.info(
                                message: 'we are working on this feature',
                              );
                              // controller.trimStartTime.value =
                              //     controller.currentPosition.value;
                              // controller.trimEndTime.value = waveform.duration;
                              // Get.dialog(
                              //   TrimDialog(
                              //     controller: controller,
                              //     waveform: waveform,
                              //     file: file,
                              //   ),
                              //   barrierDismissible: true,
                              // );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Obx(() {
                            final position = controller.currentPosition.value;
                            final duration = waveform.duration;
                            return Text(
                              '${_formatDuration(position)} / ${_formatDuration(duration)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () {
                    controller.stopPlayback();
                    Get.close();
                  },
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => {
                    if (controller.selectedFile.value != null)
                      {
                        controller
                            .shareRecording(controller.selectedFile.value!)
                      }
                  },
                  child: const Text('Share'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => {
                    if (controller.isPlaying.value)
                      {controller.stopPlayback()}
                    else if (controller.selectedFile.value != null)
                      {controller.playRecording(controller.selectedFile.value!)}
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 36),
                  ),
                  child: Text(controller.isPlaying.value ? 'Stop' : 'Play'),
                )
              ],
            ),
          ],
        ),
      );
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class Records extends GetView<RecordsController> {
  const Records({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.recordings.isEmpty) {
        return const Center(
          child: Text('No recordings found'),
        );
      }

      return Stack(
        children: [
          ListView.builder(
            itemCount: controller.recordings.length,
            itemBuilder: (context, index) {
              final recording = controller.recordings[index];
              return Card(
                color: ColorName.cardBackground,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () async {
                    controller.selectRecording(recording);
                    final res = await Get.bottomSheet(const BottomSheetBody());
                    if (res == null) {
                      controller.stopPlayback();
                      controller.selectedFile.value = null;
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recording.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recording.date.toString().split('.')[0],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    });
  }
}

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

class TimePickerWidget extends StatelessWidget {
  final Duration duration;
  final Duration selectedTime;
  final Function(Duration) onTimeChanged;
  final String label;

  const TimePickerWidget({
    super.key,
    required this.duration,
    required this.selectedTime,
    required this.onTimeChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListWheelScrollView(
            itemExtent: 40,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              onTimeChanged(Duration(seconds: index));
            },
            children: List.generate(
              duration.inSeconds + 1,
              (index) {
                final time = Duration(seconds: index);
                return Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: time == selectedTime
                          ? Colors.blue.withAlpha(25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDuration(time),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: time == selectedTime
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: time == selectedTime
                            ? Colors.blue
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              },
            ),
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

class TrimDialog extends StatelessWidget {
  final RecordsController controller;
  final Waveform waveform;
  final RecordingFile file;

  const TrimDialog({
    super.key,
    required this.controller,
    required this.waveform,
    required this.file,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorName.cardBackground,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Trim Recording',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 140,
              width: double.infinity,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // controller.shareSelectedPortion(file);
                    Toast.info(
                      message: 'we are working on this feature',
                    );
                  },
                  child: const Text('Share Trimmed'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReportForm extends StatelessWidget {
  final String userId;

  const ReportForm({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Report Form',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        Text(
          'User ID: $userId',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Text(
          'Additional details:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        const TextField(
          maxLines: 4,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                // Handle form submission
                Toast.info(
                  message: 'Report submitted successfully',
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ],
    );
  }
}
