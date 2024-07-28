```Dart
final thr = Throttling(duration: const Duration(seconds: 2));
thr.throttle(() {print(' * ping #1');});
await Future.delayed(const Duration(seconds: 1));
thr.throttle(() {print(' * ping #2');});
await Future.delayed(const Duration(seconds: 1));
thr.throttle(() {print(' * ping #3');});
await thr.close();
////////////////////////////////////////////////////////

final deb = Debouncing(duration: const Duration(seconds: 2));
deb.debounce(() {print(' * ping #1');});
await Future.delayed(const Duration(seconds: 1));
deb.debounce(() {print(' * ping #2');});
await Future.delayed(const Duration(seconds: 1));
deb.debounce(() {print(' * ping #3');});
await deb.close();

```
