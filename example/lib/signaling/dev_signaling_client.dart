import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:flutter/foundation.dart';

import '../session/app_session.dart';
import 'dev_token_minter.dart';

/// The one interface a host implements.
///
/// A real one talks to your server: it creates the call, tells the callees'
/// devices to ring, and reports whether a call is still worth answering. This
/// one has no server, so it does the smallest honest thing — hands back a
/// token for a room and writes down everything the engine asked for.
///
/// What that costs, and the example says so plainly: "call Aibek" really means
/// "join the room Aibek is in". A phone rings only when a server tells it to,
/// and there is no server here. The push simulator on the Diagnostics page
/// covers that path instead, feeding the engine the payload FCM would.
class DevSignalingClient implements CallSignalingClient {
  DevSignalingClient({
    required AppSession session,
    this.explicitToken = _explicitToken,
    this.minter = const DevTokenMinter(),
  }) : _session = session;

  static const _serverUrl = String.fromEnvironment(
    'LIVEKIT_URL',
    defaultValue: 'ws://localhost:7880',
  );
  static const _explicitToken = String.fromEnvironment('LIVEKIT_TOKEN');

  /// Read on every request rather than captured once: the user signs in after
  /// the engine is built, and a token minted for the wrong identity puts two
  /// devices in the same room under the same name — where the media server
  /// treats the second one as a duplicate and drops it.
  final AppSession _session;

  String get serverUrl =>
      _session.serverUrl.isNotEmpty ? _session.serverUrl : _serverUrl;

  String get identity => _session.identity ?? 'guest';

  String get displayName =>
      _session.displayName.isEmpty ? 'Guest' : _session.displayName;

  /// A token you passed in yourself, which always wins over minting one.
  final String explicitToken;

  final DevTokenMinter minter;

  /// Every request the engine made, oldest first. Shown in the app, so the
  /// conversation between engine and "server" is visible rather than implied.
  final ValueNotifier<List<String>> log = ValueNotifier(const []);

  /// Whether a call can actually connect.
  bool get canConnect =>
      serverUrl.isNotEmpty && (explicitToken.isNotEmpty || !kReleaseMode);

  CallConnectionInfo _connectionFor(String room) {
    final token = explicitToken.isNotEmpty
        ? explicitToken
        : minter.mint(room: room, identity: identity, name: displayName);
    return CallConnectionInfo(
      token: token,
      serverUrl: serverUrl,
      roomName: room,
      // No server means no server-side id; the room is the call.
      callId: room,
    );
  }

  @override
  Future<CallConnectionInfo> initiateCall(
    CallInitiationRequest request,
  ) async {
    final room = request.externalId ?? request.participantIds.join('-');
    _record('initiate → $room (${request.isVideo ? 'video' : 'audio'})');
    return _connectionFor(room);
  }

  @override
  Future<CallConnectionInfo> joinCall({
    required String callId,
    required String roomName,
  }) async {
    _record('join → $roomName');
    return _connectionFor(roomName);
  }

  @override
  Future<void> endCall(String callId) async => _record('end → $callId');

  @override
  Future<void> declineCall(String callId) async => _record('decline → $callId');

  @override
  Future<void> cancelCall(String callId) async => _record('cancel → $callId');

  @override
  Future<void> leaveCall(String callId) async => _record('leave → $callId');

  @override
  Future<void> heartbeat(String callId) async => _record('heartbeat');

  @override
  Future<CallStatusInfo?> fetchStatus(String callId) async {
    _record('status → $callId');
    // Asked before ringing. With no server to ask, a demo call is always
    // still worth ringing for.
    return const CallStatusInfo(status: CallLiveStatus.ringing);
  }

  void _record(String entry) => log.value = [...log.value, entry];

  void dispose() => log.dispose();
}
