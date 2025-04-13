import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:podium/app/modules/records/controllers/records_controller.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:siri_wave/siri_wave.dart';

import '../widgets/audio_waveform_widget.dart';

class BottomSheetBody extends GetView<RecordsController> {
  const BottomSheetBody({super.key});

  static const Widget emptySpace = SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final file = controller.selectedFile.value;
      if (file == null) {
        return emptySpace;
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
                            color: Colors.black.withAlpha(120),
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
                              Toast.info(
                                message: 'we are working on this feature',
                              );
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
                            color: Colors.black.withAlpha(153),
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
