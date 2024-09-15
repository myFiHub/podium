import 'package:logger/logger.dart';
import 'package:podium/env.dart';

class L {
  static final L _singleton = L._internal();
  factory L() {
    return _singleton;
  }
  L._internal();

  static final log = Logger(
    filter: CustomFilter(),
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      stackTraceBeginIndex: 0,
      lineLength: 100,
      colors: true,
      printEmojis: true,
    ),
  );
}

class CustomFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return Env.environment == DEV;
  }
}

final log = L.log;
final logError = log.e;
