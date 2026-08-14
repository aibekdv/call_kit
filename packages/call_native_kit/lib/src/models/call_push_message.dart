import '../config/call_native_timeouts.dart';
import 'call_handle.dart';

/// A decoded call push.
sealed class CallPushMessage {
  const CallPushMessage({required this.callId, required this.raw});

  /// Your server's call id.
  final String callId;

  /// The untouched payload, so nothing the plugin does not model is lost.
  final Map<String, Object?> raw;
}

/// Somebody is calling.
final class IncomingCallPush extends CallPushMessage {
  const IncomingCallPush({
    required super.callId,
    required super.raw,
    required this.callerName,
    required this.roomName,
    required this.isVideo,
    this.callerId,
    this.isGroup = false,
    this.avatarUrl,
    this.createdAt,
    this.timeoutAt,
  });

  final String callerName;
  final String roomName;
  final bool isVideo;
  final bool isGroup;
  final String? callerId;
  final String? avatarUrl;

  /// When the server created the call, in UTC.
  final DateTime? createdAt;

  /// When the server stops ringing, in UTC. Authoritative — a push that
  /// arrives after this is for a call nobody is waiting on any more.
  final DateTime? timeoutAt;

  /// Whether this push is too old to act on.
  ///
  /// Prefers [timeoutAt]. Falls back to [createdAt] plus
  /// [CallNativeTimeouts.pushStaleThreshold]. With neither, returns `false`:
  /// a server that sends no timestamps must not have all its calls dropped.
  ///
  /// [now] is injectable for tests.
  bool isStale({
    CallNativeTimeouts timeouts = const CallNativeTimeouts(),
    DateTime? now,
  }) {
    final at = (now ?? DateTime.now()).toUtc();
    final deadline = timeoutAt;
    if (deadline != null) {
      return at.isAfter(deadline.add(timeouts.pushClockSkew));
    }
    final created = createdAt;
    if (created != null) {
      return at.difference(created) > timeouts.pushStaleThreshold;
    }
    return false;
  }

  CallHandle toHandle() => CallHandle(
        callId: callId,
        roomName: roomName,
        displayName: callerName,
        isVideo: isVideo,
        isGroup: isGroup,
        avatarUrl: avatarUrl,
        extra: raw,
      );

  @override
  String toString() => 'IncomingCallPush(callId: $callId, caller: $callerName, '
      'room: $roomName, isVideo: $isVideo, isGroup: $isGroup, '
      'timeoutAt: $timeoutAt)';
}

/// The call is over before it was answered — the caller hung up, it timed out
/// or another device picked it up.
final class CallCancelledPush extends CallPushMessage {
  const CallCancelledPush({
    required super.callId,
    required super.raw,
    required this.roomName,
    this.reason,
  });

  final String roomName;

  /// Server-side reason, e.g. `timeout`, `declined`, `caller_cancelled`.
  final String? reason;

  @override
  String toString() =>
      'CallCancelledPush(callId: $callId, room: $roomName, reason: $reason)';
}
