import '../domain/models/call_connection_info.dart';
import '../domain/models/call_initiation_request.dart';
import '../domain/models/call_status_info.dart';

/// Everything the engine needs from your backend.
///
/// This is the seam that makes the package universal: the engine knows how to
/// run a call and nothing at all about how calls are created, authorized or
/// torn down on your server. There is no shipped implementation on purpose —
/// any that existed would encode one particular API's paths, bodies and
/// spellings, and yours will differ. Write these eight methods against your
/// own server.
///
/// A worked example against a REST API lives in the repository's
/// `example/lib/signaling/rest_call_signaling_client.dart`. It is meant to be
/// copied into your app and edited, not depended on.
///
/// Throw [CallSignalingException] on failure so the engine can tell "no
/// network" from "the callee is busy"; anything else is treated as unknown.
abstract interface class CallSignalingClient {
  /// Creates a call and returns what is needed to join it.
  ///
  /// The server is expected to notify the callees; the engine does not.
  ///
  /// **If creating succeeds but joining fails, cancel the call before
  /// throwing.** Otherwise the callee's phone rings for a call the caller will
  /// never be on the other end of, and they are left with a missed call from
  /// somebody who never called. On a two-step API — create, then fetch a token
  /// — that means wrapping the second step and calling [cancelCall] in the
  /// failure path.
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
  /// wake the callee.
  ///
  /// Two return values carry meaning beyond the obvious:
  ///
  /// * `null` — your server has no such endpoint. The engine skips the check
  ///   and rings; it does not treat the absence as "the call is gone".
  /// * [CallLiveStatus.ended] — the right answer for a call the server no
  ///   longer knows about. A 404 here is an answer, not a failure, and
  ///   throwing instead makes the phone ring for calls that are over.
  Future<CallStatusInfo?> fetchStatus(String callId);
}
