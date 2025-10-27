/// Base error class for all application errors
/// Provides type-safe error handling with specific error types
abstract class AppError implements Exception {
  const AppError({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  /// Factory constructors for common error types
  factory AppError.network({
    required String message,
    String? code,
    dynamic originalError,
  }) = NetworkError;

  factory AppError.validation({
    required String message,
    String? code,
  }) = ValidationError;

  factory AppError.api({
    required String message,
    int? statusCode,
    dynamic originalError,
  }) = ApiError;

  factory AppError.auth({
    required String message,
    String? code,
  }) = AuthError;

  factory AppError.database({
    required String message,
    String? code,
    dynamic originalError,
  }) = DatabaseError;

  factory AppError.unknown({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) = UnknownError;

  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppError: $message';
}

/// Network-related errors (connectivity, timeouts)
class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'NetworkError: $message';
}

/// Validation errors (form inputs, data constraints)
class ValidationError extends AppError {
  const ValidationError({
    required super.message,
    super.code,
  });

  @override
  String toString() => 'ValidationError: $message';
}

/// API errors (HTTP status codes, API responses)
class ApiError extends AppError {
  const ApiError({
    required super.message,
    this.statusCode,
    super.originalError,
  });

  final int? statusCode;

  @override
  String toString() => 'ApiError [$statusCode]: $message';
}

/// Authentication/Authorization errors
class AuthError extends AppError {
  const AuthError({
    required super.message,
    super.code,
  });

  @override
  String toString() => 'AuthError: $message';
}

/// Database errors (Supabase, local storage)
class DatabaseError extends AppError {
  const DatabaseError({
    required super.message,
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'DatabaseError: $message';
}

/// Unknown/unexpected errors
class UnknownError extends AppError {
  const UnknownError({
    required super.message,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'UnknownError: $message';
}
