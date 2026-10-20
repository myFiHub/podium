import 'package:flutter/material.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/widgetWithTimer/timer.dart';
import 'package:podium/utils/throttleAndDebounce/throttle.dart';

final thr = Throttling(duration: const Duration(seconds: 1));

class WidgetWithTimer extends StatefulWidget {
  final double size;
  final double? timerThickness;
  final double? fontSize;
  final int? finishAt;
  final Widget child;
  final void Function()? onComplete;
  final void Function()? onProgress;

  const WidgetWithTimer({
    super.key,
    required this.child,
    this.size = 25,
    this.finishAt,
    this.fontSize,
    this.onComplete,
    this.onProgress,
    this.timerThickness,
  });

  @override
  State<WidgetWithTimer> createState() => _WidgetWithTimerState();
}

class _WidgetWithTimerState extends State<WidgetWithTimer> {
  final _controller = CountDownController();

  /// Whole seconds left; a finished timer completes through its own
  /// onComplete, so nothing is called from build.
  int _secondsLeft(int finishTime) {
    final remaining = finishTime - DateTime.now().millisecondsSinceEpoch;
    return remaining <= 0 ? 0 : remaining ~/ 1000;
  }

  @override
  Widget build(BuildContext context) {
    final finishTime = widget.finishAt;
    if (finishTime == null || finishTime <= 0) {
      return widget.child;
    }
    final size = widget.size;
    final onComplete = widget.onComplete;
    final onProgress = widget.onProgress;

    return CircularCountDownTimer(
      duration: _secondsLeft(finishTime),
      initialDuration: 0,
      controller: _controller,
      width: size,
      height: size,
      ringColor: Colors.grey[300]!,
      ringGradient: null,
      fillColor: Colors.purpleAccent[100]!,
      fillGradient: null,
      backgroundColor: Colors.transparent,
      backgroundGradient: null,
      strokeWidth: widget.timerThickness ?? 4.0,
      strokeCap: StrokeCap.round,
      textStyle: TextStyle(
        fontSize: widget.fontSize ?? 12.0,
        color: ColorName.white,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
      textFormat: CountdownTextFormat.S,
      isReverse: true,
      isReverseAnimation: false,
      isTimerTextShown: true,
      autoStart: true,
      onComplete: onComplete,
      onChange: (String timeStamp) {
        if (onProgress != null) thr.throttle(onProgress);
      },
      timeFormatterFunction: (defaultFormatterFunction, duration) {
        if (duration.inSeconds == 0) {
          return "0";
        } else {
          return Function.apply(defaultFormatterFunction, [duration]);
        }
      },
    );
  }
}
