import 'package:equatable/equatable.dart';

/// What it takes to join a media room.
class CallConnectionInfo extends Equatable {
  const CallConnectionInfo({
    required this.token,
    required this.serverUrl,
    required this.roomName,
    this.callId,
  });

  /// Short-lived access token minted by your server.
  final String token;

  /// URL of the media server, e.g. `wss://sfu.example.com`.
  ///
  /// Comes from the server rather than app config on purpose: a server can
  /// route a call to whichever region is closest.
  final String serverUrl;

  final String roomName;

  /// Your server's call id, when it has one.
  final String? callId;

  @override
  List<Object?> get props => [token, serverUrl, roomName, callId];

  @override
  String toString() =>
      'CallConnectionInfo(room: $roomName, server: $serverUrl, '
      'callId: $callId)';
}
