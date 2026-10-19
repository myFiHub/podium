import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/records/controllers/records_controller.dart';
import 'package:podium/widgets/ui/app_ui.dart';

import '../widgets/record_list_item.dart';

class Records extends GetView<RecordsController> {
  const Records({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.recordings.isEmpty) {
          return const Center(
            child: SingleChildScrollView(
              child: AppEmptyState(
                icon: Icons.mic_none_rounded,
                title: 'No recordings found',
                message: 'Recordings you make in outposts will show up here.',
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          itemCount: controller.recordings.length,
          itemBuilder: (context, index) {
            final recording = controller.recordings[index];
            return RecordListItem(
              recording: recording,
              controller: controller,
            );
          },
        );
      }),
    );
  }
}
