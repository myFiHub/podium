import 'package:get/get.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost_ban.dart';
import 'package:podium/services/toast/toast.dart';

/// How long "Remove" keeps someone out, unless they're blocked.
const kickDuration = Duration(minutes: 15);

/// Removes or blocks [userId] from [outpostId]. Returns the restriction now
/// in force, or null after telling the host why it failed.
Future<OutpostBanInfo?> banFromOutpost({
  required String outpostId,
  required String userId,
  required OutpostBanKind kind,
  String? reason,
}) async {
  try {
    return await Get.find<OutpostRepository>().banUserFromOutpost(
      outpostId: outpostId,
      userId: userId,
      kind: kind,
      reason: reason,
      durationMinutes:
          kind == OutpostBanKind.kick ? kickDuration.inMinutes : null,
    );
  } on ApiFailure catch (e) {
    Toast.error(
      title: kind == OutpostBanKind.ban ? "Couldn't block" : "Couldn't remove",
      message: e.message,
    );
    return null;
  }
}

/// Lets [userId] back into [outpostId]. False after telling the host why it
/// failed.
Future<bool> unbanFromOutpost({
  required String outpostId,
  required String userId,
}) async {
  try {
    await Get.find<OutpostRepository>().unbanUserFromOutpost(
      outpostId: outpostId,
      userId: userId,
    );
    return true;
  } on ApiFailure catch (e) {
    Toast.error(title: "Couldn't let them back in", message: e.message);
    return false;
  }
}
