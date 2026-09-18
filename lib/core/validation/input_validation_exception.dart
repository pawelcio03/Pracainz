class InputValidationException implements Exception {
  const InputValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
