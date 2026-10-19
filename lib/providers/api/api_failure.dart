/// A request that did not succeed, as opposed to one that legitimately
/// returned nothing.
class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiFailure($statusCode): $message';
}
