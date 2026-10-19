import 'package:intl/intl.dart';

/// Formatting shared by the replay list and player.
abstract final class ReplayText {
  /// `4:05` or `1:02:03`.
  static String clock(Duration d) {
    final negative = d.isNegative;
    final total = d.abs().inSeconds;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = (total % 60).toString().padLeft(2, '0');
    final text = hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}:$seconds'
        : '$minutes:$seconds';
    return negative ? '-$text' : text;
  }

  static String size(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String date(DateTime at) =>
      DateFormat('MMM d, y · HH:mm').format(at.toLocal());
}
