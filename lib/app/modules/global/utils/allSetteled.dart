enum SetteledStatus {
  fulfilled,
  rejected,
}

class SetteledResult<T> {
  final SetteledStatus status;
  final T? value;
  final Object? reason;

  const SetteledResult.fulfilled(this.value)
      : status = SetteledStatus.fulfilled,
        reason = null;

  const SetteledResult.rejected(this.reason)
      : status = SetteledStatus.rejected,
        value = null;

  bool get isFulfilled => status == SetteledStatus.fulfilled;
  bool get isRejected => status == SetteledStatus.rejected;

  T get valueOrThrow {
    if (isFulfilled) return value as T;
    throw reason ?? Exception('Result was rejected');
  }
}

typedef ProgressCallback = void Function(String key, SetteledStatus status);

Future<Map<String, SetteledResult>> allSettled<T>(
  Map<String, Future<T>> futures, {
  ProgressCallback? onProgress,
}) async {
  final Map<String, SetteledResult> finalResults = {};

  await Future.wait(
    futures.keys.map((key) async {
      try {
        final result = await futures[key];
        finalResults[key] = SetteledResult.fulfilled(result);
        onProgress?.call(key, SetteledStatus.fulfilled);
      } catch (error) {
        finalResults[key] = SetteledResult.rejected(error);
        onProgress?.call(key, SetteledStatus.rejected);
      }
    }),
    eagerError: false, // Do not stop on errors
  );

  return finalResults;
}

// Utility extensions for working with allSettled results
extension SetteledResultExtensions<T> on SetteledResult<T> {
  /// Returns the value if fulfilled, otherwise returns the default value
  T valueOr(T defaultValue) => isFulfilled ? value as T : defaultValue;

  /// Returns the value if fulfilled, otherwise returns null
  T? get valueOrNull => isFulfilled ? value : null;

  /// Executes a function if the result is fulfilled
  void ifFulfilled(void Function(T value) action) {
    if (isFulfilled) action(value as T);
  }

  /// Executes a function if the result is rejected
  void ifRejected(void Function(Object reason) action) {
    if (isRejected) action(reason!);
  }
}

extension AllSettledMapExtensions<T> on Map<String, SetteledResult<T>> {
  /// Returns only the fulfilled results
  Map<String, T> get fulfilled => Map.fromEntries(entries
      .where((e) => e.value.isFulfilled)
      .map((e) => MapEntry(e.key, e.value.value as T)));

  /// Returns only the rejected results with their reasons
  Map<String, Object> get rejected => Map.fromEntries(entries
      .where((e) => e.value.isRejected)
      .map((e) => MapEntry(e.key, e.value.reason!)));

  /// Returns true if all operations were successful
  bool get allFulfilled => values.every((result) => result.isFulfilled);

  /// Returns true if any operation failed
  bool get hasRejected => values.any((result) => result.isRejected);

  /// Returns the count of fulfilled operations
  int get fulfilledCount => values.where((result) => result.isFulfilled).length;

  /// Returns the count of rejected operations
  int get rejectedCount => values.where((result) => result.isRejected).length;
}
