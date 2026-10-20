import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class L {
  static final L _singleton = L._internal();
  factory L() {
    return _singleton;
  }
  L._internal();

  static final log = Logger(
    filter: CustomFilter(),
    printer: PrettyPrinter(
      methodCount: 4,
      errorMethodCount: 8,
      stackTraceBeginIndex: 0,
      lineLength: 150,
      colors: true,
      printEmojis: true,
    ),
  );
}

class CustomFilter extends LogFilter {
  @override
  // Off in profile builds too: each call captures a stack trace, which would
  // skew frame timings.
  bool shouldLog(LogEvent event) => kDebugMode;
}

final l = L.log;
