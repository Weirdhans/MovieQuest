import '../errors/result.dart';
import '../errors/app_error.dart';
import '../utils/dev_log.dart';

/// Base service class with standardized error handling
/// All service implementations should extend this class
abstract class BaseService {
  /// Execute operation with standardized error handling
  Future<Result<T>> executeWithErrorHandling<T>(
    Future<T> Function() operation,
    String operationName, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      devLog('Executing: $operationName', metadata: metadata);
      final result = await operation();
      devLogSuccess('Success: $operationName');
      return Result.success(result);
    } on AppError catch (e) {
      devLogError('AppError in $operationName', e);
      return Result.error(e);
    } catch (e, stackTrace) {
      devLogError('Unknown error in $operationName', e, stackTrace: stackTrace);
      final error = AppError.unknown(
        message: 'Unexpected error in $operationName',
        originalError: e,
        stackTrace: stackTrace,
      );
      return Result.error(error);
    }
  }

  /// Execute with retry logic
  Future<Result<T>> executeWithRetry<T>(
    Future<T> Function() operation,
    String operationName, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      final result = await executeWithErrorHandling(
        operation,
        '$operationName (attempt ${attempt + 1}/$maxRetries)',
      );

      if (result.isSuccess) return result;

      attempt++;
      if (attempt < maxRetries) {
        devLogWarning(
          'Retrying operation',
          metadata: {
            'operation': operationName,
            'attempt': attempt,
            'maxRetries': maxRetries,
          },
        );
        await Future<void>.delayed(retryDelay);
      }
    }

    return Result.error(
      AppError.network(
        message: '$operationName failed after $maxRetries attempts',
      ),
    );
  }

  /// Execute with timeout
  Future<Result<T>> executeWithTimeout<T>(
    Future<T> Function() operation,
    String operationName,
    Duration timeout,
  ) async {
    try {
      final result = await operation().timeout(
        timeout,
        onTimeout: () {
          throw AppError.network(
            message: '$operationName timed out after ${timeout.inSeconds}s',
          );
        },
      );
      return Result.success(result);
    } on AppError catch (e) {
      return Result.error(e);
    } catch (e, stackTrace) {
      return Result.error(
        AppError.unknown(
          message: 'Error in $operationName',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
