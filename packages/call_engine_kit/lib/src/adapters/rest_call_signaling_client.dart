import '../domain/models/call_connection_info.dart';
import '../domain/models/call_initiation_request.dart';
import '../domain/models/call_signaling_exception.dart';
import '../domain/models/call_status_info.dart';
import '../ports/call_signaling_client.dart';

/// How the adapter talks to the network.
///
/// A function rather than an HTTP client, so this package forces neither `dio`
/// nor `http` on you. Pass whatever you already use — with your interceptors,
/// your auth, your retry policy — and this adapter contributes only the paths,
/// the bodies and the parsing.
///
/// Throw on a failed request; [CallSignalingException] is preferred, anything
/// else is wrapped.
typedef CallHttpTransport = Future<Map<String, Object?>?> Function(
  String method,
  String path, {
  Map<String, Object?>? body,
  Map<String, Object?>? query,
});

/// Field names in your call API's requests and responses.
class RestCallFieldNames {
  const RestCallFieldNames({
    this.token = 'token',
    this.serverUrl = 'livekitHost',
    this.roomName = 'livekitRoom',
    this.callId = 'id',
    this.callType = 'type',
    this.status = 'status',
    this.startedBy = 'startedBy',
    this.endReason = 'endReason',
    this.participantIds = 'participantIds',
    this.participantNames = 'participantNames',
    this.externalId = 'externalId',
    this.groupTitle = 'groupTitle',
    this.deviceId = 'deviceId',
    this.videoValue = 'VIDEO',
    this.audioValue = 'AUDIO',
    this.ringingValue = 'RINGING',
    this.activeValue = 'ACTIVE',
    this.endedValue = 'ENDED',
  });

  final String token;
  final String serverUrl;
  final String roomName;
  final String callId;
  final String callType;
  final String status;
  final String startedBy;
  final String endReason;
  final String participantIds;
  final String participantNames;
  final String externalId;
  final String groupTitle;
  final String deviceId;

  final String videoValue;
  final String audioValue;
  final String ringingValue;
  final String activeValue;
  final String endedValue;
}

/// A [CallSignalingClient] for the common REST shape:
///
/// ```
/// POST /calls                  -> { id, livekitRoom, ... }
/// POST /calls/{id}/join        -> { token, livekitHost }
/// POST /calls/{id}/end | /decline | /cancel | /leave | /heartbeat
/// GET  /calls/{id}/status      -> { status, ... }
/// ```
///
/// Adjust the paths with [basePath] and the field names with [fields]. If your
/// API is shaped differently, implement [CallSignalingClient] directly — that
/// is the supported path, and this class is only a shortcut.
class RestCallSignalingClient implements CallSignalingClient {
  RestCallSignalingClient({
    required this.transport,
    this.basePath = '/calls',
    this.fields = const RestCallFieldNames(),
    this.deviceIdProvider,
  });

  final CallHttpTransport transport;
  final String basePath;
  final RestCallFieldNames fields;

  /// Some servers pin a call to the device that joined, so a second device
  /// signing in with the same account does not steal it.
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
        fields.callType:
            request.isVideo ? fields.videoValue : fields.audioValue,
        fields.participantIds: request.participantIds,
        if (request.participantNames.isNotEmpty)
          fields.participantNames: request.participantNames,
        if (request.externalId != null) fields.externalId: request.externalId,
        if (request.isGroup && request.title != null)
          fields.groupTitle: request.title,
        ...request.metadata,
      },
      kind: CallSignalingErrorKind.createFailed,
    );

    final callId = created[fields.callId]?.toString();
    final roomName = created[fields.roomName]?.toString();
    if (callId == null || roomName == null) {
      throw CallSignalingException(
        kind: CallSignalingErrorKind.createFailed,
        message: 'response is missing ${fields.callId} or ${fields.roomName}: '
            '$created',
      );
    }

    try {
      return await joinCall(callId: callId, roomName: roomName);
    } catch (_) {
      // The call exists on the server but we cannot join it. Cancel it, or the
      // callee's phone rings for a call nobody will ever be on the other end
      // of, and they get a missed call from a caller who never called.
      await _swallow(() => cancelCall(callId));
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
      body: {if (deviceId != null) fields.deviceId: deviceId},
      kind: CallSignalingErrorKind.joinFailed,
    );

    final token = joined[fields.token]?.toString();
    final serverUrl = joined[fields.serverUrl]?.toString();
    if (token == null || serverUrl == null) {
      throw CallSignalingException(
        kind: CallSignalingErrorKind.joinFailed,
        message: 'response is missing ${fields.token} or ${fields.serverUrl}: '
            '$joined',
      );
    }

    return CallConnectionInfo(
      token: token,
      serverUrl: serverUrl,
      roomName: joined[fields.roomName]?.toString() ?? roomName,
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

    final raw = response[fields.status]?.toString().toUpperCase();
    return CallStatusInfo(
      status: switch (raw) {
        final value? when value == fields.ringingValue.toUpperCase() =>
          CallLiveStatus.ringing,
        final value? when value == fields.activeValue.toUpperCase() =>
          CallLiveStatus.active,
        final value? when value == fields.endedValue.toUpperCase() =>
          CallLiveStatus.ended,
        _ => CallLiveStatus.unknown,
      },
      isVideo: response[fields.callType]?.toString().toUpperCase() ==
          fields.videoValue.toUpperCase(),
      startedBy: response[fields.startedBy]?.toString(),
      endReason: response[fields.endReason]?.toString(),
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

  Future<void> _swallow(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }
}
