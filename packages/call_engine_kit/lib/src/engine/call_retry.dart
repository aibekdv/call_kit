import '../ports/call_logger.dart';

/// Retries an operation with exponential backoff.
///
/// Used for the requests that stand between the user and a call they are
/// trying to answer — a transient failure there is the difference between a
/// call connecting and a missed call.
class CallRetry {
  const CallRetry({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.logger = const SilentCallLogger(),
  });

  final int maxRetries;
  final Duration baseDelay;
  final CallLogger logger;

  /// Runs [action], retrying on failure.
  ///
  /// Returns `null` if [shouldContinue] goes false between attempts — the call
  /// ended while we were retrying, and there is nothing left to retry for.
  /// Rethrows once the attempts are exhausted.
  Future<T?> call<T>({
    required Future<T> Function() action,
    required bool Function() shouldContinue,
    void Function(Object error, int attempt)? onError,
  }) async {
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await action();
      } catch (e) {
        onError?.call(e, attempt);
        if (attempt == maxRetries) rethrow;

        final delay = baseDelay * (1 << attempt);
        logger.log(
            'retry ${attempt + 1}/$maxRetries in ${delay.inMilliseconds}ms');
        await Future<void>.delayed(delay);
        if (!shouldContinue()) return null;
      }
    }
    return null;
  }
}
