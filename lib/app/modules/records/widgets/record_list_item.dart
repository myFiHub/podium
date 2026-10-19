import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/records/controllers/records_controller.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/widgets/ui/app_ui.dart';

import '../widgets/bottom_sheet_body.dart';

class RecordListItem extends StatelessWidget {
  final RecordingFile recording;
  final RecordsController controller;

  const RecordListItem({
    super.key,
    required this.recording,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Slidable(
        key: ValueKey(recording.name),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.4,
          dragDismissible: true,
          dismissible: DismissiblePane(
            onDismissed: () => controller.deleteRecording(recording),
          ),
          children: [
            _ShareAction(recording: recording, controller: controller),
            _DeleteAction(recording: recording, controller: controller),
          ],
        ),
        child: _RecordCard(
          recording: recording,
          controller: controller,
        ),
      ),
    );
  }
}

class _ShareAction extends StatelessWidget {
  final RecordingFile recording;
  final RecordsController controller;

  const _ShareAction({
    required this.recording,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SlidableAction(
      onPressed: (context) => controller.shareRecording(recording),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: Icons.ios_share_rounded,
      label: 'Share',
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(AppRadius.lg),
      ),
      autoClose: true,
    );
  }
}

class _DeleteAction extends StatelessWidget {
  final RecordingFile recording;
  final RecordsController controller;

  const _DeleteAction({
    required this.recording,
    required this.controller,
  });

  Future<void> _showDeleteConfirmationDialog() async {
    final confirmed = await showAppConfirm(
      title: 'Delete Recording',
      message: 'Are you sure you want to delete this recording?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) {
      controller.deleteRecording(recording);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlidableAction(
      onPressed: (context) => _showDeleteConfirmationDialog(),
      backgroundColor: AppColors.danger,
      foregroundColor: Colors.white,
      icon: Icons.delete_outline_rounded,
      label: 'Delete',
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      borderRadius: const BorderRadius.horizontal(
        right: Radius.circular(AppRadius.lg),
      ),
      autoClose: true,
    );
  }
}

class _RecordCard extends StatelessWidget {
  final RecordingFile recording;
  final RecordsController controller;

  const _RecordCard({
    required this.recording,
    required this.controller,
  });

  void _showBottomSheet() {
    controller.selectRecording(recording);
    Get.bottomSheet(
      const BottomSheetBody(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
    ).then((value) {
      controller.stopPlayback();
      controller.selectedFile.value = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: _showBottomSheet,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withAlpha(70),
                  AppColors.primary.withAlpha(25),
                ],
              ),
              border: Border.all(color: AppColors.primary.withAlpha(60)),
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RecordName(recording: recording),
                const SizedBox(height: 4),
                _RecordDate(recording: recording),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.fill,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordName extends StatelessWidget {
  final RecordingFile recording;

  const _RecordName({required this.recording});

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      recording.name,
      style: AppText.cardTitle,
      minFontSize: 12,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _RecordDate extends StatelessWidget {
  final RecordingFile recording;

  const _RecordDate({required this.recording});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.schedule_rounded,
          size: 13,
          color: ColorName.greyText,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            recording.date.toString().split('.')[0],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption,
          ),
        ),
      ],
    );
  }
}
