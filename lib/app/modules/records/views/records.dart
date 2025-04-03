import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/records/controllers/records_controller.dart';
import 'package:podium/gen/colors.gen.dart';

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
            Text('Name: ${file.name}'),
            const SizedBox(height: 8),
            Text('Date: ${file.date.toString().split('.')[0]}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () => Get.close(),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => controller.shareRecording(file),
                  child: const Text('Share'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => {
                    if (isPlaying)
                      {controller.stopPlayback()}
                    else
                      {controller.playRecording(file)}
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 36),
                  ),
                  child: Text(isPlaying ? 'Stop' : 'Play'),
                )
              ],
            ),
          ],
        ),
      );
    });
  }
}

class Records extends GetView<RecordsController> {
  const Records({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!Get.isRegistered<RecordsController>()) {
        return const SizedBox.shrink();
      }
      if (controller.recordings.isEmpty) {
        return const Center(
          child: Text('No recordings found'),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: controller.recordings.length,
        itemBuilder: (context, index) {
          final recording = controller.recordings[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Card(
              color: ColorName.cardBackground,
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 26),
              child: InkWell(
                onTap: () {
                  controller.selectRecording(recording);
                  Get.bottomSheet(const BottomSheetBody());
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
            ),
          );
        },
      );
    });
  }
}
