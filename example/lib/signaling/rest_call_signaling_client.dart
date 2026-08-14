import 'package:call_engine_kit/call_engine_kit.dart';

/// How this client reaches the network.
///
/// A function rather than an HTTP client, so the choice of `dio`, `http` or
/// anything else — with your interceptors, your auth, your retries — stays
/// yours, and a test can pass a fake.
///
/// Throw on a failed request. [CallSignalingException.http] turns a status
/// code into something the engine understands.
typedef CallHttpTransport = Future<Map<String, Object?>?> Function(
  String method,
  String path, {
  Map<String, Object?>? body,
});

/// A [CallSignalingClient] for a REST API — **copy this file and edit it**.
///
/// It is deliberately not part of `call_engine_kit`: every path, every body
/// key and every spelling below describes one particular server, and yours
/// will differ. The package ships the interface; this is one filled-in answer
/// to it.
///
/// The shape it assumes:
///
/// ```
/// POST /calls                 -> { "id": "…", "livekitRoom": "…" }
/// POST /calls/{id}/join       -> { "token": "…", "livekitHost": "wss://…" }
/// POST /calls/{id}/end
/// POST /calls/{id}/decline
/// POST /calls/{id}/cancel
/// POST /calls/{id}/leave
/// POST /calls/{id}/heartbeat
/// GET  /calls/{id}/status     -> { "status": "RINGING" | "ACTIVE" | "ENDED" }
/// ```
///
/// The names are literals in the method bodies rather than a configuration
/// object, because editing a literal you can see beats configuring an
/// indirection you have to learn.
///
/// What is worth keeping when you rewrite it is not the names — it is the two
/// rules the [CallSignalingClient] documentation asks for, both implemented
/// below: cancel a created call you could not join, and treat a forgotten call
/// as ended.
class RestCallSignalingClient implements CallSignalingClient {
  const RestCallSignalingClient({
    required this.transport,
    this.basePath = '/calls',
    this.deviceIdProvider,
  });

  final CallHttpTransport transport;

  final String basePath;

  /// Some servers pin a call to the device that joined it, so a second device
  /// on the same account cannot steal it. Drop this if yours does not.
  final Future<Object?> Function()? deviceIdProvider;

  @override
  Future<CallConnectionInfo> initiateCall(CallInitiationRequest request) async {
    if (request.participantIds.isEmpty) {
      throw const CallSignalingException(
        kind: CallSignalingErrorKind.createFailed,
        message: 'participantIds is empty',
      );
    }

    final created = await _send(
      'POST',
      basePath,
      body: {
        'type': request.isVideo ? 'VIDEO' : 'AUDIO',
        'participantIds': request.participantIds,
        if (request.participantNames.isNotEmpty)
          'participantNames': request.participantNames,
        if (request.externalId != null) 'externalId': request.externalId,
        if (request.isGroup && request.title != null)
          'groupTitle': request.title,
        ...request.metadata,
      },
      kind: CallSignalingErrorKind.createFailed,
    );

    final callId = created['id']?.toString();
    final roomName = created['livekitRoom']?.toString();
    if (callId == null || roomName == null) {
      throw CallSignalingException(
        kind: CallSignalingErrorKind.createFailed,
        message: 'response is missing id or livekitRoom: $created',
      );
    }

    try {
      return await joinCall(callId: callId, roomName: roomName);
    } catch (_) {
      // The call exists on the server but we cannot join it. Cancel it, or the
      // callee's phone rings for a call nobody will ever be on the other end
      // of, and they get a missed call from a caller who never called.
      try {
        await cancelCall(callId);
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<CallConnectionInfo> joinCall({
    required String callId,
    required String roomName,
  }) async {
    final deviceId = await deviceIdProvider?.call();
    final joined = await _send(
      'POST',
      '$basePath/$callId/join',
      body: {if (deviceId != null) 'deviceId': deviceId},
      kind: CallSignalingErrorKind.joinFailed,
    );

    final token = joined['token']?.toString();
    final serverUrl = joined['livekitHost']?.toString();
    if (token == null || serverUrl == null) {
      throw CallSignalingException(
        kind: CallSignalingErrorKind.joinFailed,
        message: 'response is missing token or livekitHost: $joined',
      );
    }

    return CallConnectionInfo(
      token: token,
      serverUrl: serverUrl,
      roomName: joined['livekitRoom']?.toString() ?? roomName,
      callId: callId,
    );
  }

  @override
  Future<void> endCall(String callId) => _post('$basePath/$callId/end');

  @override
  Future<void> declineCall(String callId) => _post('$basePath/$callId/decline');

  @override
  Future<void> cancelCall(String callId) => _post('$basePath/$callId/cancel');

  @override
  Future<void> leaveCall(String callId) => _post('$basePath/$callId/leave');

  @override
  Future<void> heartbeat(String callId) => _post('$basePath/$callId/heartbeat');

  @override
  Future<CallStatusInfo?> fetchStatus(String callId) async {
    final Map<String, Object?> response;
    try {
      response = await _send('GET', '$basePath/$callId/status');
    } on CallSignalingException catch (e) {
      // A call the server has forgotten is a call that stopped ringing, which
      // is an answer, not a failure.
      if (e.kind == CallSignalingErrorKind.notFound) {
        return const CallStatusInfo(status: CallLiveStatus.ended);
      }
      rethrow;
    }

    return CallStatusInfo(
      status: switch (response['status']?.toString().toUpperCase()) {
        'RINGING' => CallLiveStatus.ringing,
        'ACTIVE' => CallLiveStatus.active,
        'ENDED' => CallLiveStatus.ended,
        // An unfamiliar status is not a reason to drop the call.
        _ => CallLiveStatus.unknown,
      },
      isVideo: response['type']?.toString().toUpperCase() == 'VIDEO',
      startedBy: response['startedBy']?.toString(),
      endReason: response['endReason']?.toString(),
    );
  }

  Future<void> _post(String path) async {
    await _send('POST', path);
  }

  Future<Map<String, Object?>> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    CallSignalingErrorKind kind = CallSignalingErrorKind.unknown,
  }) async {
    try {
      return await transport(method, path, body: body) ?? const {};
    } on CallSignalingException {
      rethrow;
    } catch (e) {
      throw CallSignalingException(kind: kind, message: '$method $path: $e');
    }
  }
}
