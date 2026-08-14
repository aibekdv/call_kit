import '../domain/models/call_connection_info.dart';
import '../domain/models/call_initiation_request.dart';
import '../domain/models/call_status_info.dart';

/// Everything the engine needs from your backend.
///
/// This is the seam that makes the package universal: the engine knows how to
/// run a call, and nothing at all about how calls are created, authorized or
/// torn down on your server. Implement it, or use `RestCallSignalingClient` if
/// your API is shaped like the one it was extracted from.
///
/// Failures should be thrown as `CallSignalingException` so the engine can
/// tell "no network" from "the callee declined".
abstract interface class CallSignalingClient {
  /// Creates a call and returns what is needed to join it.
  ///
  /// The server is expected to notify the callees; the engine does not.
  Future<CallConnectionInfo> initiateCall(CallInitiationRequest request);

  /// Joins a call that already exists — the other side of an incoming call,
  /// or a group call already in progress.
  Future<CallConnectionInfo> joinCall({
    required String callId,
    required String roomName,
  });

  /// Ends the call for everyone.
  Future<void> endCall(String callId);

  /// Rejects an incoming call.
  Future<void> declineCall(String callId);

  /// Withdraws an outgoing call before it was answered.
  Future<void> cancelCall(String callId);

  /// Leaves a group call without ending it for the others.
  Future<void> leaveCall(String callId);

  /// Periodic liveness ping, so the server can end a call whose participant
  /// vanished without saying goodbye.
  Future<void> heartbeat(String callId);

  /// Current state of a call.
  ///
  /// Asked before ringing, so a call the caller already abandoned does not
  /// wake the callee. Return `null` if your server offers no such endpoint —
  /// the engine will simply skip the check.
  Future<CallStatusInfo?> fetchStatus(String callId);
}
