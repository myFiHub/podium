import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/records/controllers/records_controller.dart';
import 'package:podium/gen/colors.gen.dart';

import '../widgets/bottom_sheet_body.dart';

class RecordListItem extends StatelessWidget {
  final RecordingFile recording;
  final RecordsController controller;

  const RecordListItem({
    super.key,
    required this.recording,
    required this.controller,
  });

  void _showDeleteConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: ColorName.cardBackground,
        title: const Text('Delete Recording'),
        content: const Text('Are you sure you want to delete this recording?'),
        actions: [
          TextButton(
            onPressed: () => Get.close(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteRecording(recording);
              Get.close();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(recording.name),
      // Right side actions
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.4,
        dragDismissible: true,
        dismissible: DismissiblePane(
          onDismissed: () {
            controller.deleteRecording(recording);
          },
        ),
        children: [
          SlidableAction(
            onPressed: (context) {
              controller.shareRecording(recording);
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.share,
            label: 'Share',
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            autoClose: true,
          ),
          SlidableAction(
            onPressed: (context) => _showDeleteConfirmationDialog(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            autoClose: true,
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
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
        },
        child: Card(
          color: ColorName.cardBackground,
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  recording.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
