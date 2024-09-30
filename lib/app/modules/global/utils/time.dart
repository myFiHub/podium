String remainintTimeUntilMilSecondsFormated(
    {required int time, String? textIfAlreadyPassed}) {
//  if contains day or weeks or moths or years, show, if something is less than 10 add 0 before
  final now = DateTime.now().millisecondsSinceEpoch;
  final remainingTime = time - now;
  if (remainingTime < 0) {
    return textIfAlreadyPassed ?? '00:00:00';
  }
  final Duration duration = Duration(milliseconds: remainingTime);
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  final String twoDigitHours = twoDigits(duration.inHours.remainder(24));
  if (duration.inDays > 0) {
    return '${duration.inDays} d,$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds';
  }
  return '$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds';
}
