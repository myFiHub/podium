import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:podium/app/services/replay/replay_format.dart';
import 'package:podium/app/services/replay/replay_storage.dart';

class ReplayImportException implements Exception {
  final String message;
  const ReplayImportException(this.message);

  @override
  String toString() => message;
}

/// Packs replays into `.podium` files to share, and unpacks received ones.
abstract final class ReplayArchive {
  static const _maxBytes = 4 * 1024 * 1024 * 1024;
  static final _clipName = RegExp(r'^screen/clip_\d{3}\.mp4$');

  /// Writes the replay [id] into a `.podium` file in the temporary folder,
  /// named after its outpost.
  static Future<File> export(String id) async {
    final dir = await ReplayStorage.dirOf(id);
    final meta = await ReplayStorage.readMeta(dir);
    if (meta == null) throw StateError('Replay $id has no meta');
    final outDir = Directory(
      p.join((await getTemporaryDirectory()).path, 'replay_exports'),
    );
    await outDir.create(recursive: true);
    await _deleteOldExports(outDir);
    final safeName = meta.outpost.name
        .replaceAll(RegExp(r'[^\w\- ]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final name = safeName.isEmpty ? 'replay' : safeName;
    final outPath = p.join(outDir.path, '${name}_$id.${ReplayFormat.extension}');
    final entries = [
      ...ReplayFormat.exported,
      for (final clip in meta.clips) clip.file,
    ];
    await Isolate.run(() => pack(dir.path, entries, outPath));
    return File(outPath);
  }

  /// The share sheet gives no reliable signal that the receiving app has
  /// finished reading, so exports are kept for a while.
  static Future<void> _deleteOldExports(Directory dir) async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 6));
    await for (final entity in dir.list()) {
      try {
        if (entity is File && (await entity.lastModified()).isBefore(cutoff)) {
          await entity.delete();
        }
      } on FileSystemException {
        continue;
      }
    }
  }

  /// Zips [entries] of the folder at [dirPath] into [outPath], uncompressed.
  static Future<void> pack(
    String dirPath,
    List<String> entries,
    String outPath,
  ) async {
    final tmp = '$outPath.tmp';
    final encoder = ZipFileEncoder()..create(tmp, level: ZipFileEncoder.store);
    try {
      for (final entry in entries) {
        final file = File(p.join(dirPath, entry));
        if (await file.exists()) await encoder.addFile(file, entry);
      }
    } finally {
      await encoder.close();
    }
    await File(tmp).rename(outPath);
  }

  /// Validates the `.podium` file at [path] and adds it to the library.
  /// Returns the replay's id; a replay already in the library isn't copied
  /// again.
  static Future<String> import(String path) async {
    final root = await ReplayStorage.root();
    final staging = p.join(
      root.path,
      '.import_${DateTime.now().microsecondsSinceEpoch}_'
      '${Random().nextInt(1 << 16)}',
    );
    try {
      final meta = await Isolate.run(() => extract(path, staging));
      final target = await ReplayStorage.dirOf(meta.id);
      if (await target.exists() &&
          await ReplayStorage.readMeta(target) != null) {
        return meta.id;
      }
      await ReplayStorage.writeState(
        Directory(staging),
        ReplayState(status: ReplayStatus.ready, clips: meta.clips),
      );
      if (await target.exists()) await target.delete(recursive: true);
      await Directory(staging).rename(target.path);
      return meta.id;
    } finally {
      final leftover = Directory(staging);
      if (await leftover.exists()) await leftover.delete(recursive: true);
    }
  }

  /// Validates the `.podium` file at [path] and extracts it into [staging].
  static Future<ReplayMeta> extract(String path, String staging) async {
    final source = File(path);
    if (!await source.exists()) {
      throw const ReplayImportException('The file could not be opened');
    }
    if (await source.length() > _maxBytes) {
      throw const ReplayImportException('This replay is too large');
    }
    final input = InputFileStream(path);
    try {
      final Archive archive;
      try {
        archive = ZipDecoder().decodeStream(input);
      } catch (_) {
        throw const ReplayImportException('This is not a Podium replay');
      }

      final files = <String, ArchiveFile>{};
      var total = 0;
      for (final file in archive.files) {
        if (!file.isFile) continue;
        final name = file.name;
        // Only known names are extracted, which also rules out paths that
        // would escape the replay folder.
        if (!ReplayFormat.exported.contains(name) && !_clipName.hasMatch(name)) {
          continue;
        }
        total += file.size;
        files[name] = file;
      }
      if (total > _maxBytes) {
        throw const ReplayImportException('This replay is too large');
      }

      final metaFile = files[ReplayFormat.meta];
      final metaBytes = metaFile?.readBytes();
      final meta = metaBytes == null
          ? null
          : ReplayMeta.decode(utf8.decode(metaBytes, allowMalformed: true));
      if (meta == null) {
        throw const ReplayImportException('This is not a Podium replay');
      }
      if (!meta.isSupported) {
        throw const ReplayImportException(
          'Update Podium to play this replay',
        );
      }
      if (files[ReplayFormat.audio] == null ||
          files[ReplayFormat.events] == null) {
        throw const ReplayImportException('This replay is incomplete');
      }
      for (final clip in meta.clips) {
        if (files[clip.file] == null) {
          throw const ReplayImportException('This replay is incomplete');
        }
      }

      await Directory(p.join(staging, ReplayFormat.screen))
          .create(recursive: true);
      for (final entry in files.entries) {
        final output = OutputFileStream(p.join(staging, entry.key));
        try {
          entry.value.writeContent(output);
        } finally {
          await output.close();
        }
      }
      return meta;
    } finally {
      await input.close();
    }
  }
}
