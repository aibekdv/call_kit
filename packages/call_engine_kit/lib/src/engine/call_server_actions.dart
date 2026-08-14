import '../ports/call_logger.dart';
import '../ports/call_signaling_client.dart';

/// Tells the server how a call ended.
///
/// Every method here swallows its failure on purpose. These run while the call
/// is already being torn down locally, and the user has moved on — a failed
/// `end` must not leave them stuck on a screen for a call that is over. The
/// server's own timeout is the backstop.
class CallServerActions {
  const CallServerActions({
    required CallSignalingClient signaling,
    CallLogger logger = const SilentCallLogger(),
  })  : _signaling = signaling,
        _logger = logger;

  final CallSignalingClient _signaling;
  final CallLogger _logger;

  /// The best available identifier for the current call.
  ///
  /// The server's id if we have one; otherwise the room name, which some
  /// servers accept as an alias. Null means the call was never registered
  /// server-side and there is nothing to notify.
  String? resolveCallId(
          String? callId, String? roomName, String? sessionRoom) =>
      callId ?? roomName ?? sessionRoom;

  Future<void> end(String? callId) =>
      _run(callId, 'end', () => _signaling.endCall(callId!));

  Future<void> decline(String? callId) =>
      _run(callId, 'decline', () => _signaling.declineCall(callId!));

  Future<void> cancel(String? callId) =>
      _run(callId, 'cancel', () => _signaling.cancelCall(callId!));

  Future<void> leave(String? callId) =>
      _run(callId, 'leave', () => _signaling.leaveCall(callId!));

  Future<void> heartbeat(String? callId) =>
      _run(callId, 'heartbeat', () => _signaling.heartbeat(callId!));

  Future<void> _run(
    String? callId,
    String action,
    Future<void> Function() request,
  ) async {
    if (callId == null) {
      _logger.log('$action: no call id, the server will not be told');
      return;
    }
    try {
      await request();
    } catch (e) {
      _logger.log('$action failed: $e');
    }
  }
}
