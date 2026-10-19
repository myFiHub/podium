import 'package:podium/app/services/replay/replay_archive.dart';
import 'package:podium/app/services/replay/replay_format.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:share_plus/share_plus.dart';

/// Packs the replay into a `.podium` file and opens the share sheet.
Future<void> shareReplay(ReplayMeta meta) async {
  try {
    final file = await ReplayArchive.export(meta.id);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: ReplayFormat.mimeType)],
      subject: meta.outpost.name,
      text: 'Replay of "${meta.outpost.name}" on Podium',
    ));
  } catch (e, stackTrace) {
    l.e('Error sharing replay ${meta.id}: $e\n$stackTrace');
    Toast.error(
      title: "Couldn't share the replay",
      message: 'Please try again.',
    );
  }
}
