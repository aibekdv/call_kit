import 'package:call_engine_kit/call_engine_kit.dart';

/// A [CallSignalingClient] that records what it was asked to do.
class FakeSignalingClient implements CallSignalingClient {
  FakeSignalingClient({this.connection, this.status});

  /// Returned by [initiateCall] and [joinCall].
  CallConnectionInfo? connection;

  /// Returned by [fetchStatus].
  CallStatusInfo? status;

  /// Makes every method throw, for the error paths.
  bool failEverything = false;

  final List<String> calls = [];

  CallConnectionInfo get _connection =>
      connection ??
      const CallConnectionInfo(
        token: 'token',
        serverUrl: 'wss://fake',
        roomName: 'call_1',
        callId: '1',
      );

  @override
  Future<CallConnectionInfo> initiateCall(
    CallInitiationRequest request,
  ) async {
    _record('initiate:${request.participantIds.join(',')}');
    return _connection;
  }

  @override
  Future<CallConnectionInfo> joinCall({
    required String callId,
    required String roomName,
  }) async {
    _record('join:$callId');
    return _connection;
  }

  @override
  Future<void> endCall(String callId) async => _record('end:$callId');

  @override
  Future<void> declineCall(String callId) async => _record('decline:$callId');

  @override
  Future<void> cancelCall(String callId) async => _record('cancel:$callId');

  @override
  Future<void> leaveCall(String callId) async => _record('leave:$callId');

  @override
  Future<void> heartbeat(String callId) async => _record('heartbeat:$callId');

  @override
  Future<CallStatusInfo?> fetchStatus(String callId) async {
    _record('status:$callId');
    return status;
  }

  void _record(String entry) {
    if (failEverything) {
      throw const CallSignalingException(
        kind: CallSignalingErrorKind.network,
        message: 'fake failure',
      );
    }
    calls.add(entry);
  }
}
