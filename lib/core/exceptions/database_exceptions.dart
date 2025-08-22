class DatabaseException implements Exception {
  final String message;
  final String? code;

  DatabaseException(this.message, {this.code});

  @override
  String toString() =>
      'DatabaseException: $message${code != null ? ' ($code)' : ''}';
}
