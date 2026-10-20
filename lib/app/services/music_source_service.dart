import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/ongoingOutpostCall/controllers/call_room_controller.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

/// Where room music comes from: a curated library in Firebase Storage, a file
/// uploaded from the device, or a direct link to an audio file.
class MusicSourceService {
  MusicSourceService._();
  static final instance = MusicSourceService._();

  static const maxUploadBytes = 30 * 1024 * 1024;
  static const audioExtensions = ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'];
  static const _libraryManifest = 'music_library/index.json';

  final uploading = false.obs;
  final uploadProgress = 0.0.obs;
  List<MusicTrack>? _library;

  /// A track for a pasted link, or null when it isn't an http(s) URL.
  static MusicTrack? trackFromLink(String input, {String? title}) {
    final url = input.trim();
    final uri = Uri.tryParse(url);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return null;
    }
    final name = title?.trim() ?? '';
    return MusicTrack.tryParse({
      'id': 'link-${url.hashCode.toUnsigned(32).toRadixString(16)}',
      'url': url,
      'title': name.isNotEmpty ? name : titleFromPath(uri.path),
    });
  }

  /// "/music/My%20Song.mp3" -> "My Song".
  static String titleFromPath(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty);
    if (segments.isEmpty) return 'Link';
    var name = Uri.decodeComponent(segments.last);
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);
    name = name.replaceAll(RegExp(r'[_]+'), ' ').trim();
    return name.isEmpty ? 'Link' : name;
  }

  /// Tracks listed in `music_library/index.json` as
  /// `[{id, title, artist, url, durationMs}]`.
  Future<List<MusicTrack>> loadLibrary({bool refresh = false}) async {
    final cached = _library;
    if (cached != null && !refresh) return cached;
    try {
      final bytes = await FirebaseStorage.instance
          .ref(_libraryManifest)
          .getData(1024 * 1024);
      if (bytes == null) return const [];
      final raw = jsonDecode(utf8.decode(bytes));
      final tracks = [
        if (raw is List)
          for (final item in raw)
            if (item is Map)
              MusicTrack.tryParse({
                ...item,
                'id': 'lib-${item['id'] ?? item['url']}',
              }),
      ].whereType<MusicTrack>().toList();
      _library = tracks;
      return tracks;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        _library = const [];
        return const [];
      }
      l.e('music: cannot load library: $e');
      rethrow;
    }
  }

  /// Lets a host pick an audio file and uploads it for everyone to stream.
  Future<MusicTrack?> pickAndUpload({required String outpostId}) async {
    if (uploading.value) return null;
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: audioExtensions,
    );
    final file = picked?.files.singleOrNull;
    final path = file?.path;
    if (file == null || path == null) return null;
    if (file.size > maxUploadBytes) {
      Toast.error(
        title: 'File too large',
        message: 'Audio files must be under 30 MB',
      );
      return null;
    }
    uploading.value = true;
    uploadProgress.value = 0;
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final safeName = file.name.replaceAll(RegExp(r'[^\w.\-]+'), '_');
      final ref =
          FirebaseStorage.instance.ref('room_music/$outpostId/${ts}_$safeName');
      final task = ref.putFile(
        File(path),
        SettableMetadata(contentType: _contentType(file.extension)),
      );
      final sub = task.snapshotEvents.listen((s) {
        if (s.totalBytes > 0) {
          uploadProgress.value = s.bytesTransferred / s.totalBytes;
        }
      });
      try {
        await task;
      } finally {
        await sub.cancel();
      }
      final url = await ref.getDownloadURL();
      return MusicTrack.tryParse({
        'id': 'upload-$ts',
        'url': url,
        'title': titleFromPath(file.name),
      });
    } catch (e) {
      l.e('music: upload failed: $e');
      Toast.error(
        title: 'Upload failed',
        message: 'The audio file could not be uploaded',
      );
      return null;
    } finally {
      uploading.value = false;
    }
  }

  static String _contentType(String? extension) =>
      switch (extension?.toLowerCase()) {
        'mp3' => 'audio/mpeg',
        'm4a' => 'audio/mp4',
        'aac' => 'audio/aac',
        'wav' => 'audio/wav',
        'ogg' => 'audio/ogg',
        'flac' => 'audio/flac',
        _ => 'application/octet-stream',
      };
}
