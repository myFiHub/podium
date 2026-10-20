import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/records/controllers/records_controller.dart';
import 'package:podium/app/modules/records/controllers/replays_controller.dart';
import 'package:podium/app/modules/records/widgets/replay_list_item.dart';
import 'package:podium/widgets/ui/app_ui.dart';

import '../widgets/record_list_item.dart';

/// Replays first, then audio-only recordings made by older app versions.
class Records extends GetView<RecordsController> {
  const Records({super.key});

  @override
  Widget build(BuildContext context) {
    final replays = Get.find<ReplaysController>();
    return Scaffold(
      body: Obx(() {
        final entries = replays.entries.toList();
        final recordings = controller.recordings.toList();
        if (entries.isEmpty && recordings.isEmpty) {
          if (replays.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return const Center(
            child: SingleChildScrollView(
              child: AppEmptyState(
                icon: Icons.mic_none_rounded,
                title: 'No recordings found',
                message: 'Outposts you record will show up here to replay '
                    'and share.',
              ),
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            if (entries.isNotEmpty) ...[
              AppSectionHeader(
                title: 'Replays',
                count: entries.length,
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
              ),
              for (final entry in entries)
                ReplayListItem(key: ValueKey(entry.id), entry: entry),
            ],
            if (recordings.isNotEmpty) ...[
              AppSectionHeader(
                title: 'Audio recordings',
                count: recordings.length,
                padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
              ),
              for (final recording in recordings)
                RecordListItem(
                  key: ValueKey(recording.path),
                  recording: recording,
                  controller: controller,
                ),
            ],
          ],
        );
      }),
    );
  }
}
