import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/ongoingGroupCall/widgets/widgetWithTimer/timer.dart';
import 'package:podium/utils/throttleAndDebounce/throttle.dart';

final thr = Throttling(duration: const Duration(seconds: 1));

class WidgetWithTimer extends StatelessWidget {
  final double size;
  final double? timerThickness;
  final double? fontSize;
  final String storageKey;
  final int? finishAt;
  final Widget child;
  final void Function()? onComplete;
  final void Function()? onProgress;

  const WidgetWithTimer({
    super.key,
    required this.child,
    this.size = 25,
    required this.storageKey,
    this.finishAt,
    this.fontSize,
    this.onComplete,
    this.onProgress,
    this.timerThickness,
  });

  duration(int finishTime) {
    final remaining = finishTime - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) {
      onComplete!();
      return 0;
    }
    return int.parse((remaining / 1000).toString().split(".")[0]);
  }

  @override
  Widget build(BuildContext context) {
    if (finishAt != null && GetStorage().read(storageKey) == null) {
      GetStorage().write(storageKey, finishAt);
    }
    if (finishAt == null && GetStorage().read(storageKey) == null) {
      return child;
    }
    int finishTime = GetStorage().read(storageKey) ??
        finishAt ??
        DateTime.now().millisecondsSinceEpoch + 10000;
    if (finishTime <= 0) {
      GetStorage().remove(storageKey);
      return child;
    }

    return CircularCountDownTimer(
      duration: duration(finishTime),
      initialDuration: 0,
      controller: CountDownController(),
      width: size,
      height: size,
      ringColor: Colors.grey[300]!,
      ringGradient: null,
      fillColor: Colors.purpleAccent[100]!,
      fillGradient: null,
      backgroundColor: Colors.transparent,
      backgroundGradient: null,
      strokeWidth: timerThickness ?? 4.0,
      strokeCap: StrokeCap.round,
      textStyle: TextStyle(
        fontSize: fontSize ?? 12.0,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
      textFormat: CountdownTextFormat.S,
      isReverse: true,
      isReverseAnimation: false,
      isTimerTextShown: true,
      autoStart: true,
      onComplete: () {
        if (onComplete != null) {
          GetStorage().remove(storageKey);
          onComplete!();
        }
      },
      onChange: (String timeStamp) {
        if (onProgress != null) {
          thr.throttle(() {
            onProgress!();
          });
        }
        if (finishAt != null) {}
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
