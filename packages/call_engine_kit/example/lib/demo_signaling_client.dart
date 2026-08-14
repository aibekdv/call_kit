import 'package:call_engine_kit/call_engine_kit.dart';

/// A signaling client with no server behind it.
///
/// Real signaling is the one thing an example cannot ship: creating a call
/// means minting a LiveKit token, which needs an API secret that must never
/// live in an app. So this returns a token you supply yourself and records
/// everything else.
///
/// Get a room and a token from the LiveKit sandbox
/// (https://cloud.livekit.io) and pass them in:
///
/// ```
/// flutter run \
///   --dart-define=LIVEKIT_URL=wss://your-project.livekit.cloud \
///   --dart-define=LIVEKIT_TOKEN=eyJhbGci...
/// ```
///
/// Run it on two devices with two tokens for the same room and you have a real
/// call, with real media, driven by the real engine.
class DemoSignalingClient implements CallSignalingClient {
  DemoSignalingClient({required this.serverUrl, required this.token});

  static const _url = String.fromEnvironment('LIVEKIT_URL');
  static const _token = String.fromEnvironment('LIVEKIT_TOKEN');
  static const _room = String.fromEnvironment(
    'LIVEKIT_ROOM',
    defaultValue: 'call_kit_demo',
  );

  factory DemoSignalingClient.fromEnvironment() =>
      DemoSignalingClient(serverUrl: _url, token: _token);

  final String serverUrl;
  final String token;

  /// Whether enough was passed in to actually connect.
  bool get isConfigured => serverUrl.isNotEmpty && token.isNotEmpty;

  /// Every request the engine made, newest last. Shown in the app so the
  /// call's conversation with its "server" is visible.
  final List<String> log = [];

  CallConnectionInfo get _connection => CallConnectionInfo(
        token: token,
        serverUrl: serverUrl,
        roomName: _room,
        callId: 'demo',
      );

  @override
  Future<CallConnectionInfo> initiateCall(
    CallInitiationRequest request,
  ) async {
    log.add('initiate → ${request.participantIds.join(', ')}');
    _requireConfiguration();
    return _connection;
  }

  @override
  Future<CallConnectionInfo> joinCall({
    required String callId,
    required String roomName,
  }) async {
    log.add('join → $callId');
    _requireConfiguration();
    return _connection;
  }

  @override
  Future<void> endCall(String callId) async => log.add('end → $callId');

  @override
  Future<void> declineCall(String callId) async => log.add('decline → $callId');

  @override
  Future<void> cancelCall(String callId) async => log.add('cancel → $callId');

  @override
  Future<void> leaveCall(String callId) async => log.add('leave → $callId');

  @override
  Future<void> heartbeat(String callId) async => log.add('heartbeat');

  @override
  Future<CallStatusInfo?> fetchStatus(String callId) async {
    log.add('status → $callId');
    // A demo call is always worth ringing for.
    return const CallStatusInfo(status: CallLiveStatus.ringing);
  }

  void _requireConfiguration() {
    if (isConfigured) return;
    throw const CallSignalingException(
      kind: CallSignalingErrorKind.createFailed,
      message: 'Pass --dart-define=LIVEKIT_URL and --dart-define=LIVEKIT_TOKEN '
          'to place a real call.',
    );
  }
}
