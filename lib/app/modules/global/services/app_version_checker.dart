import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/env.dart';
import 'package:podium/providers/api/podium/models/metadata/metadata.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/storage.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Whether semantic version [remote] is newer than [current]. Build suffixes
/// (`+171`) are ignored and missing or non-numeric parts count as 0.
bool isNewerVersion(String remote, String current) {
  List<int> parts(String v) =>
      v.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final r = parts(remote);
  final c = parts(current);
  for (var i = 0; i < r.length || i < c.length; i++) {
    final rp = i < r.length ? r[i] : 0;
    final cp = i < c.length ? c[i] : 0;
    if (rp != cp) return rp > cp;
  }
  return false;
}

/// Prompts for an update when the backend advertises a newer app version.
/// Optional updates can be dismissed once per version.
class AppVersionChecker {
  final _storage = GetStorage();

  void check(PodiumAppMetadata metadata) {
    if (!metadata.version_check) {
      l.d('version check disabled');
      return;
    }
    final version = metadata.version;
    final ignored = _storage.read<String>(StorageKeys.ignoredOrAcceptedVersion);
    if (ignored == version) {
      l.d('version already ignored/accepted');
      return;
    }
    if (!isNewerVersion(version, Env.VERSION)) {
      l.d('version is up to date');
      return;
    }
    l.e('New version available: $version (current: ${Env.VERSION})');
    _showUpdateDialog(version: version, force: metadata.force_update);
  }

  void _showUpdateDialog({required String version, required bool force}) {
    Get.dialog(
      barrierDismissible: false,
      AppDialog(
        icon: Icons.system_update_rounded,
        title: 'New version available',
        message: 'A new version of Podium ($version) is available',
        actions: [
          if (!force)
            AppSecondaryButton(
              label: 'Later',
              onPressed: () {
                _storage.write(StorageKeys.ignoredOrAcceptedVersion, version);
                Get.close();
              },
            ),
          AppPrimaryButton(
            label: 'Update',
            onPressed: () async {
              if (!force) {
                _storage.write(StorageKeys.ignoredOrAcceptedVersion, version);
              }
              try {
                await launchUrl(Uri.parse(Env.appStoreUrl));
              } catch (e) {
                l.e("error launching url $e");
              }
            },
          ),
        ],
      ),
    );
  }
}
