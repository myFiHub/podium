import 'dart:async';

/// A simple lock implementation to prevent multiple simultaneous operations
class Lock {
  bool _locked = false;
  final _completers = <Completer<void>>[];

  Future<T> synchronized<T>(Future<T> Function() action) async {
    if (_locked) {
      final completer = Completer<void>();
      _completers.add(completer);
      await completer.future;
    }

    _locked = true;
    try {
      return await action();
    } finally {
      _locked = false;
      if (_completers.isNotEmpty) {
        final completer = _completers.removeAt(0);
        completer.complete();
      }
    }
  }
}
