import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/records/controllers/records_controller.dart';

import '../widgets/record_list_item.dart';

class Records extends GetView<RecordsController> {
  const Records({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.recordings.isEmpty) {
          return const Center(
            child: Text('No recordings found'),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: controller.recordings.length,
              itemBuilder: (context, index) {
                final recording = controller.recordings[index];
                return RecordListItem(
                  recording: recording,
                  controller: controller,
                );
              },
            ),
          ],
        );
      }),
    );
  }
}
