class AppError implements Exception {
  final String message;
  final int? statusCode;
  final Object? raw;

  const AppError({
    required this.message,
    this.statusCode,
    this.raw,
  });

  @override
  String toString() => message;
}
