import 'package:flutter/foundation.dart';

/// Development-only logging (automatically disabled in release builds)
/// Zero performance impact in production
void devLog(
  String message, {
  String? name,
  Object? error,
  StackTrace? stackTrace,
  Map<String, dynamic>? metadata,
}) {
  if (!kDebugMode) return; // No-op in release mode

  final timestamp = DateTime.now().toIso8601String();
  final prefix = name != null ? '[$name]' : '[MovieQuest]';
  final metaStr = metadata != null ? ' | ${metadata.toString()}' : '';

  debugPrint('$timestamp $prefix $message$metaStr');

  if (error != null) {
    debugPrint('Error: $error');
  }

  if (stackTrace != null) {
    debugPrint('StackTrace: $stackTrace');
  }
}

/// Log error with stack trace
void devLogError(
  String message,
  Object error, {
  StackTrace? stackTrace,
  String? name,
}) {
  devLog(
    message,
    name: name,
    error: error,
    stackTrace: stackTrace,
  );
}

/// Log warning
void devLogWarning(
  String message, {
  Map<String, dynamic>? metadata,
  String? name,
}) {
  devLog(
    '⚠️ $message',
    name: name,
    metadata: metadata,
  );
}

/// Log success
void devLogSuccess(
  String message, {
  Map<String, dynamic>? metadata,
  String? name,
}) {
  devLog(
    '✅ $message',
    name: name,
    metadata: metadata,
  );
}

/// Log info
void devLogInfo(
  String message, {
  Map<String, dynamic>? metadata,
  String? name,
}) {
  devLog(
    'ℹ️ $message',
    name: name,
    metadata: metadata,
  );
}
