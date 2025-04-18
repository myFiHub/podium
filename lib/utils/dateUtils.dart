List<String> formatDuration(int timeDurationInSeconds) {
  final Duration duration = Duration(seconds: timeDurationInSeconds);
  String hours = duration.inHours.toString().padLeft(0, '2');
  String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  String seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return [hours, minutes, seconds];
}
