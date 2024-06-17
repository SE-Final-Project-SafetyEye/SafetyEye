


class IntegrityException implements Exception {
  final String message;

  IntegrityException(this.message);

  @override
  String toString() {
    return "IntegrityException: $message";
  }
}