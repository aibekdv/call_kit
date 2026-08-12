import 'call_handle.dart';

/// A call the user accepted on the system UI while the app was not running.
///
/// The operating system launches the app afterwards, and this is how the app
/// finds out what it is supposed to join. Written natively at the moment the
/// call is shown, marked accepted when the user accepts, and dropped after
/// `CallNativeTimeouts.pendingCallTtl`.
class PendingCall {
  const PendingCall({
    required this.call,
    required this.savedAt,
    required this.isAccepted,
  });

  final CallHandle call;

  /// When the call was first shown, in UTC.
  final DateTime savedAt;

  /// `true` once the user accepted. Only accepted calls are handed to Dart —
  /// a call that is merely still ringing is the system UI's business.
  final bool isAccepted;

  bool isExpired(Duration ttl, {DateTime? now}) =>
      (now ?? DateTime.now()).toUtc().difference(savedAt) > ttl;

  static PendingCall? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final call = CallHandle.fromJson(json);
    if (call == null) return null;
    final savedAtMs = json['savedAt'];
    return PendingCall(
      call: call,
      savedAt: savedAtMs is int
          ? DateTime.fromMillisecondsSinceEpoch(savedAtMs, isUtc: true)
          : DateTime.now().toUtc(),
      isAccepted: json['isAccepted'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() => {
        ...call.toJson(),
        'savedAt': savedAt.toUtc().millisecondsSinceEpoch,
        'isAccepted': isAccepted,
      };

  @override
  String toString() =>
      'PendingCall(call: $call, savedAt: $savedAt, isAccepted: $isAccepted)';
}
