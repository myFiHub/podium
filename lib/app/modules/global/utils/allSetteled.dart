enum AllSettledStatus {
  fulfilled,
  rejected,
}

Future<Map<String, dynamic>> allSettled(Map<String, Future> futures) async {
  final Map<String, dynamic> finalResults = {};

  await Future.wait(
    futures.keys.map((key) async {
      try {
        final result = await futures[key];
        finalResults[key] = {
          'status': AllSettledStatus.fulfilled,
          'value': result
        };
      } catch (error) {
        finalResults[key] = {
          'status': AllSettledStatus.rejected,
          'reason': error
        };
      }
    }),
    eagerError: false, // Do not stop on errors
  );

  return finalResults;
}
