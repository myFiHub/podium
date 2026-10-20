import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:podium/app/services/replay/replay_format.dart';
import 'package:podium/utils/logger.dart';

/// Replays live in `<app support>/replays/<id>/`, out of the user's sight.
abstract final class ReplayStorage {
  static Directory? _root;

  static Future<Directory> root() async {
    final cached = _root;
    if (cached != null) return cached;
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'replays'));
    await dir.create(recursive: true);
    return _root = dir;
  }

  static Future<Directory> dirOf(String id) async {
    if (!ReplayMeta.isValidId(id)) {
      throw ArgumentError.value(id, 'id', 'not a replay id');
    }
    return Directory(p.join((await root()).path, id));
  }

  static final _random = Random();

  static String newId() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final suffix =
        _random.nextInt(0x10000).toRadixString(16).padLeft(4, '0');
    return '${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}-$suffix';
  }

  /// Writes through a temporary file so a crash never leaves half a file.
  static Future<void> writeAtomic(File file, String content) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(content, flush: true);
    await tmp.rename(file.path);
  }

  static Future<ReplayMeta?> readMeta(Directory dir) async {
    try {
      final file = File(p.join(dir.path, ReplayFormat.meta));
      if (!await file.exists()) return null;
      return ReplayMeta.decode(await file.readAsString());
    } on FileSystemException catch (e) {
      l.w('Could not read replay meta in ${dir.path}: $e');
      return null;
    }
  }

  static Future<ReplayState?> readState(Directory dir) async {
    try {
      final file = File(p.join(dir.path, ReplayFormat.state));
      if (!await file.exists()) return null;
      return ReplayState.decode(await file.readAsString());
    } on FileSystemException catch (e) {
      l.w('Could not read replay state in ${dir.path}: $e');
      return null;
    }
  }

  static Future<void> writeMeta(Directory dir, ReplayMeta meta) =>
      writeAtomic(File(p.join(dir.path, ReplayFormat.meta)), meta.encode());

  static Future<void> writeState(Directory dir, ReplayState state) =>
      writeAtomic(File(p.join(dir.path, ReplayFormat.state)), state.encode());

  /// Total size of a folder's files, in bytes.
  static Future<int> sizeOf(Directory dir) async {
    var total = 0;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) total += await entity.length();
      }
    } on FileSystemException {
      // Partially listed folders still give a useful estimate.
    }
    return total;
  }
}
