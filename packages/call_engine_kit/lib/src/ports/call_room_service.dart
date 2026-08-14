import 'package:livekit_client/livekit_client.dart' show Room;

/// What happened to the media room.
enum CallRoomLifecycle {
  connected,
  reconnecting,
  reconnected,
  disconnected,
}

/// A change in the media room's connection.
class CallRoomEvent {
  const CallRoomEvent({required this.lifecycle, this.roomName, this.reason});

  final CallRoomLifecycle lifecycle;
  final String? roomName;

  /// Why, when the media server said.
  final String? reason;

  @override
  String toString() =>
      'CallRoomEvent(${lifecycle.name}, room: $roomName, reason: $reason)';
}

/// The media room, behind an interface.
///
/// The real implementation is `LiveKitRoomService` and there is no other — the
/// interface exists so the engine can be tested without a media server, which
/// is otherwise most of the engine's behaviour left uncovered.
abstract interface class CallRoomService {
  /// The live room, or null when not connected. Widgets need it to render
  /// video tracks.
  Room? get room;

  String? get roomName;

  Stream<CallRoomEvent> get lifecycle;

  /// Connects, replacing any existing connection.
  Future<Room> connect(String serverUrl, String token);

  Future<void> disconnect();

  Future<void> dispose();
}
