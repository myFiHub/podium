import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:podium/app/modules/records/controllers/records_controller.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:siri_wave/siri_wave.dart';

import '../widgets/audio_waveform_widget.dart';

class BottomSheetBody extends GetView<RecordsController> {
  const BottomSheetBody({super.key});

  static const Widget emptySpace = SizedBox.shrink();
  static const double _waveHeight = 110;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final file = controller.selectedFile.value;
      if (file == null) {
        return emptySpace;
      }
      return AppSheet(
        title: 'Recording Details',
        trailing: AppIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Close',
          size: 36,
          onTap: () {
            controller.stopPlayback();
            Get.closeOverlay();
          },
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.cardTitle.copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            file.date.toString().split('.')[0],
                            style: AppText.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: _waveHeight,
                child: StreamBuilder<WaveformProgress>(
                  stream: controller.getWaveformProgress(file),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _WaveFrame(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Error: ${snapshot.error}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }
                    final progress = snapshot.data?.progress ?? 0.0;
                    final waveform = snapshot.data?.waveform;
                    if (waveform == null) {
                      return _WaveFrame(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${(100 * progress).toInt()}%',
                                style: AppText.muted,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        return _WaveFrame(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 14,
                                  ),
                                  child: Obx(() => AudioWaveformWidget(
                                        waveform: waveform,
                                        start: Duration.zero,
                                        duration: waveform.duration,
                                        currentPosition:
                                            controller.currentPosition.value,
                                        waveColor: AppColors.primary,
                                        onSeek: controller.seekToPosition,
                                      )),
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Obx(() {
                                    final siriController =
                                        IOS9SiriWaveformController()
                                          ..amplitude = controller
                                                  .isPlaying.value
                                              ? 1.0
                                              : 0.0
                                          ..speed = 0.5
                                          ..color1 =
                                              Colors.purple[400]!.withAlpha(110)
                                          ..color2 =
                                              Colors.blue[400]!.withAlpha(110)
                                          ..color3 =
                                              Colors.teal[400]!.withAlpha(110);
                                    return SiriWaveform.ios9(
                                      controller: siriController,
                                      options: IOS9SiriWaveformOptions(
                                        height: _waveHeight,
                                        width: width,
                                        showSupportBar: false,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Material(
                                  color: Colors.black.withAlpha(110),
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () {
                                      Toast.info(
                                        message:
                                            'we are working on this feature',
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.content_cut_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
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
                                    color: Colors.black.withAlpha(120),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Obx(() {
                                    final position =
                                        controller.currentPosition.value;
                                    final duration = waveform.duration;
                                    return Text(
                                      '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Share',
                      icon: Icons.ios_share_rounded,
                      onPressed: () => {
                        if (controller.selectedFile.value != null)
                          {
                            controller
                                .shareRecording(controller.selectedFile.value!)
                          }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() {
                      final isPlaying = controller.isPlaying.value;
                      return AppPrimaryButton(
                        label: isPlaying ? 'Stop' : 'Play',
                        icon: isPlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        color: isPlaying ? AppColors.danger : null,
                        onPressed: () => {
                          if (controller.isPlaying.value)
                            {controller.stopPlayback()}
                          else if (controller.selectedFile.value != null)
                            {
                              controller.playRecording(
                                  controller.selectedFile.value!)
                            }
                        },
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
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

class _WaveFrame extends StatelessWidget {
  final Widget child;
  const _WaveFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorName.cardBorder),
      ),
      child: child,
    );
  }
}
