import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/app/services/replay/replay_archive.dart';
import 'package:podium/app/services/replay/replay_processor.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

/// Opens replay files the platform hands to Podium (open with, share to),
/// on launch and while running.
class ReplayImportService {
  ReplayImportService._();

  static final instance = ReplayImportService._();

  static const _channel = MethodChannel('podium/replay_import');

  bool _started = false;
  bool _taking = false;

  void start() {
    if (_started) return;
    _started = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'replayImportAvailable') await _takePending();
    });
    _takePending();
  }

  Future<void> _takePending() async {
    if (_taking) return;
    _taking = true;
    try {
      while (true) {
        final List<String> paths;
        try {
          paths = (await _channel.invokeListMethod<String>(
                'takePendingImports',
              )) ??
              const [];
        } on MissingPluginException {
          return;
        }
        if (paths.isEmpty) return;
        for (final path in paths) {
          await importFile(path);
        }
      }
    } finally {
      _taking = false;
    }
  }

  /// Imports the replay at [path], a copy that's deleted afterwards, and
  /// opens it.
  Future<void> importFile(String path) async {
    try {
      final id = await ReplayArchive.import(path);
      ReplayProcessor.instance.changes.value++;
      await _waitForStartup();
      // One replay page at a time: its controller isn't per page.
      if (Get.currentRoute == Routes.REPLAY) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      Get.toNamed(Routes.REPLAY, arguments: id);
    } on ReplayImportException catch (e) {
      Toast.error(title: "Couldn't open the replay", message: e.message);
    } catch (e, stackTrace) {
      l.e('Error importing replay $path: $e\n$stackTrace');
      Toast.error(
        title: "Couldn't open the replay",
        message: 'The file may be damaged.',
      );
    } finally {
      try {
        await File(path).delete();
      } on FileSystemException {
        // Already gone.
      }
    }
  }

  /// Logging in on launch replaces every page, so the replay opens after.
  static Future<void> _waitForStartup() async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      if (Get.isRegistered<GlobalController>() &&
          !Get.find<GlobalController>().isAutoLoggingIn.value) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }
}
