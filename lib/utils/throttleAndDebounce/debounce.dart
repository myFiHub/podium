import 'dart:async';

/// Debouncing status
enum DebouncingStatus {
  /// Ready to accept new events
  idle,

  /// Waiting for the end of the pause
  busy;

  const DebouncingStatus();

  /// Ready to accept new events
  bool get isIdle => this == DebouncingStatus.idle;

  /// Waiting for the end of the pause
  bool get isBusy => this == DebouncingStatus.busy;

  @override
  String toString() => switch (this) {
        DebouncingStatus.idle => 'idle',
        DebouncingStatus.busy => 'busy',
      };
}

/// Debouncing
/// Have method [debounce]
final class Debouncing<T> extends Stream<DebouncingStatus>
    implements Sink<T Function()> {
  ///  Debouncing
  ///  Have method [debounce]
  /// Must be closed with [close] method
  /// With [maxWait], a pending call runs at most that long after the first
  /// call of a burst, even if calls keep coming.
  Debouncing({Duration duration = const Duration(seconds: 1), this.maxWait})
      : assert(!duration.isNegative, 'Duration must be positive'),
        _duration = duration {
    _stateSC.sink.add(DebouncingStatus.idle);
  }
  Duration _duration;

  final Duration? maxWait;
  DateTime? _pendingSince;

  /// Get current duration
  Duration get duration => _duration;

  /// Set new duration
  set duration(Duration value) {
    assert(!duration.isNegative, 'Duration must be positive');
    _duration = value;
  }

  Timer? _timer;

  Completer<T?>? _completer;

  /// Is ready to accept new events
  bool get isIdle => switch (_timer?.isActive) {
        true => false,
        _ => true,
      };

  /// Waiting for the end of the pause
  bool get isBusy => !isIdle;

  // ignore: close_sinks
  final StreamController<DebouncingStatus> _stateSC =
      StreamController<DebouncingStatus>.broadcast(sync: true);

  /// Allows you to control events being triggered successively and,
  /// if the interval between two sequential occurrences is less than
  /// a certain amount of time (e.g. one second),
  /// it completely ignores the first one.
  Future<T?> debounce(T Function() func) async {
    if (_stateSC.isClosed) return null;
    if (isIdle) _stateSC.sink.add(DebouncingStatus.busy);
    final completer = _completer ??= Completer<T?>();
    _timer?.cancel();
    final pendingSince = _pendingSince ??= DateTime.now();
    var delay = _duration;
    if (maxWait != null) {
      final left = maxWait! - DateTime.now().difference(pendingSince);
      if (left < delay) delay = left.isNegative ? Duration.zero : left;
    }
    _timer = Timer(delay, () {
      _completer = null;
      _timer = null;
      _pendingSince = null;
      try {
        final result = func();
        completer.complete(result);
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace); // coverage:ignore-line
      } finally {
        if (!_stateSC.isClosed) _stateSC.sink.add(DebouncingStatus.idle);
      }
    });
    return completer.future;
  }

  @override
  StreamSubscription<DebouncingStatus> listen(
    void Function(DebouncingStatus status)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _stateSC.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  /// Shortcut for [debounce] method
  @override
  Future<T?> add(T Function() data) => debounce(data);

  /// Free resources
  /// If [force] is true, then the current event will be canceled.
  @override
  void close({bool force = false}) {
    // coverage:ignore-start
    if (force) {
      _timer?.cancel();
      _completer?.completeError(StateError('closed'));
      _timer = null;
      _completer = null;
      _pendingSince = null;
    }
    // coverage:ignore-end
    _stateSC.close().ignore();
  }
}
