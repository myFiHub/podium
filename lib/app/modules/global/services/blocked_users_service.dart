import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/podium/models/users/blocked_user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

/// People the signed-in user blocked. Blocked people can't message them, and
/// their messages in room chat are hidden.
class BlockedUsersService extends GetxService {
  final blocked = <String, BlockedUserModel>{}.obs;

  /// False when the server can't block yet.
  final available = true.obs;

  String? _loadedFor;
  Future<void>? _loading;

  CallAccessRepository get _repo => Get.find<CallAccessRepository>();

  bool isBlocked(String? uuid) => uuid != null && blocked.containsKey(uuid);

  /// Loads the list once per signed-in user.
  Future<void> ensureLoaded() {
    if (_loadedFor == myId) return Future.value();
    return _loading ??= refresh().whenComplete(() => _loading = null);
  }

  Future<void> refresh() async {
    final owner = myId;
    try {
      final users = await _repo.getBlockedUsers();
      if (owner != myId) return;
      blocked.assignAll({for (final user in users) user.uuid: user});
      available.value = true;
      _loadedFor = owner;
    } on ApiFailure catch (e) {
      l.e('cannot load blocked users: $e');
      if (e.statusCode == 404) {
        available.value = false;
        _loadedFor = owner;
      }
    }
  }

  Future<bool> block(String uuid, {String? name, String? image}) async {
    try {
      await _repo.blockUser(uuid, block: true);
      blocked[uuid] = BlockedUserModel(
        uuid: uuid,
        name: name,
        image: image,
        blockedAt: DateTime.now(),
      );
      return true;
    } on ApiFailure catch (e) {
      _toastFailure(e, 'Could not block');
      return false;
    }
  }

  Future<bool> unblock(String uuid) async {
    try {
      await _repo.blockUser(uuid, block: false);
      blocked.remove(uuid);
      return true;
    } on ApiFailure catch (e) {
      _toastFailure(e, 'Could not unblock');
      return false;
    }
  }

  void _toastFailure(ApiFailure e, String title) {
    if (e.statusCode == 404) available.value = false;
    Toast.error(
      title: title,
      message: e.statusCode == 404
          ? 'Blocking is not available on this server yet'
          : e.message,
    );
  }
}
