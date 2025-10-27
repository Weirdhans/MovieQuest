import 'app_error.dart';

/// Result type for operations that can succeed or fail
/// Replaces throwing exceptions with explicit error handling
class Result<T> {
  final T? _data;
  final AppError? _error;

  const Result.success(T data)
      : _data = data,
        _error = null;

  const Result.error(AppError error)
      : _data = null,
        _error = error;

  bool get isSuccess => _error == null;
  bool get isError => _error != null;

  T get data {
    if (_data == null) {
      throw StateError('No data available - Result is an error');
    }
    return _data!;
  }

  T? get dataOrNull => _data;

  AppError get error {
    if (_error == null) {
      throw StateError('No error available - Result is a success');
    }
    return _error!;
  }

  AppError? get errorOrNull => _error;

  /// Unwrap or throw
  T unwrap() => data;

  /// Unwrap or return default
  T unwrapOr(T defaultValue) => _data ?? defaultValue;

  /// Transform success value
  Result<U> map<U>(U Function(T) transform) {
    if (isSuccess) {
      return Result.success(transform(data));
    }
    return Result.error(error);
  }

  /// Chain async operations
  Future<Result<U>> flatMapAsync<U>(
    Future<Result<U>> Function(T) operation,
  ) async {
    if (isSuccess) {
      return await operation(data);
    }
    return Result.error(error);
  }

  /// Execute if successful
  Result<T> onSuccess(void Function(T) action) {
    if (isSuccess) action(data);
    return this;
  }

  /// Execute if error
  Result<T> onError(void Function(AppError) action) {
    if (isError) action(error);
    return this;
  }

  /// Match pattern (like Rust/Kotlin)
  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) error,
  }) {
    if (isSuccess) {
      return success(_data as T);
    } else {
      return error(this.error);
    }
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'Result.success($_data)';
    } else {
      return 'Result.error($_error)';
    }
  }
}
