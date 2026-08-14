/// What went wrong talking to your server.
///
/// Classified rather than raw, because the engine reacts differently to each:
/// a network failure is worth retrying, a decline is not.
enum CallSignalingErrorKind {
  /// The call could not be created.
  createFailed,

  /// The call exists but could not be joined.
  joinFailed,

  /// No connection, or the request timed out.
  network,

  /// The user is not allowed to make this call.
  unauthorized,

  /// The call is gone.
  notFound,

  unknown,
}

/// Thrown by a [CallSignalingClient] when a request fails.
class CallSignalingException implements Exception {
  const CallSignalingException({
    required this.kind,
    required this.message,
    this.statusCode,
  });

  /// Convenience for the common case of an HTTP failure.
  factory CallSignalingException.http({
    required int statusCode,
    required String message,
    CallSignalingErrorKind? kind,
  }) =>
      CallSignalingException(
        kind: kind ?? _kindFor(statusCode),
        message: message,
        statusCode: statusCode,
      );

  final CallSignalingErrorKind kind;

  /// Technical detail, for logs. Never shown to a user — the engine maps
  /// failures to `CallEngineStrings` for that.
  final String message;

  final int? statusCode;

  static CallSignalingErrorKind _kindFor(int statusCode) =>
      switch (statusCode) {
        401 || 403 => CallSignalingErrorKind.unauthorized,
        404 || 410 => CallSignalingErrorKind.notFound,
        >= 500 => CallSignalingErrorKind.network,
        _ => CallSignalingErrorKind.unknown,
      };

  @override
  String toString() => 'CallSignalingException(${kind.name}, $message'
      '${statusCode == null ? '' : ', status: $statusCode'})';
}
