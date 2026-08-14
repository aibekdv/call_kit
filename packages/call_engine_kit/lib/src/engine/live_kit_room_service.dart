import 'dart:async';

import 'package:livekit_client/livekit_client.dart';

import '../ports/call_logger.dart';
import '../ports/call_room_service.dart';

/// Options for the LiveKit room, exposed so a host can tune them without the
/// engine leaking `livekit_client` types into its own configuration.
class CallRoomOptions {
  const CallRoomOptions({
    this.adaptiveStream = true,
    this.dynacast = true,
    this.simulcast = true,
    this.captureScreenAudio = true,
    this.useIosBroadcastExtension = true,
  });

  /// Drop video quality for participants rendered small.
  final bool adaptiveStream;

  /// Stop sending layers nobody is watching.
  final bool dynacast;

  /// Publish several qualities at once, so weak connections get a small one.
  final bool simulcast;

  final bool captureScreenAudio;

  /// iOS captures the screen through a broadcast extension. Without it,
  /// sharing stops the moment the app leaves the foreground — which is
  /// exactly when a user shares their screen.
  final bool useIosBroadcastExtension;

  RoomOptions toRoomOptions() => RoomOptions(
        adaptiveStream: adaptiveStream,
        dynacast: dynacast,
        defaultVideoPublishOptions: VideoPublishOptions(simulcast: simulcast),
        defaultScreenShareCaptureOptions: ScreenShareCaptureOptions(
          useiOSBroadcastExtension: useIosBroadcastExtension,
          captureScreenAudio: captureScreenAudio,
        ),
      );
}

/// The only place a LiveKit [Room] is created.
class LiveKitRoomService implements CallRoomService {
  LiveKitRoomService({
    CallRoomOptions options = const CallRoomOptions(),
    CallLogger logger = const SilentCallLogger(),
  })  : _options = options,
        _logger = logger;

  final CallRoomOptions _options;
  final CallLogger _logger;

  Room? _room;
  String? _roomName;
  StreamSubscription<RoomEvent>? _roomEvents;
  final StreamController<CallRoomEvent> _lifecycle =
      StreamController<CallRoomEvent>.broadcast();

  /// Serializes connect against disconnect.
  ///
  /// On a fast hang-up followed by a new call, the previous room can still be
  /// tearing down while the next one connects. Rejoining with the same
  /// identity before the server has processed the leave makes LiveKit treat it
  /// as a duplicate and silently drop the freshly published camera track — the
  /// call looks connected and nobody can see you. Queueing the operations
  /// forces the old participant fully out before the new one goes in.
  Future<void> _operations = Future<void>.value();

  @override
  Room? get room => _room;

  @override
  String? get roomName => _roomName;

  @override
  Stream<CallRoomEvent> get lifecycle => _lifecycle.stream;

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _operations.then((_) => operation());
    // Errors are handed to the caller but must not poison the queue for the
    // next operation.
    _operations = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  @override
  Future<Room> connect(String serverUrl, String token) =>
      _enqueue(() => _connect(serverUrl, token));

  Future<Room> _connect(String serverUrl, String token) async {
    await _disconnect();

    final room = Room(roomOptions: _options.toRoomOptions());
    _roomEvents = room.events.streamCtrl.stream.listen(_onRoomEvent);

    try {
      await room.connect(serverUrl, token);
    } catch (e, st) {
      // The user cannot join the call at all — worth reporting, not just
      // logging, because it is invisible from the outside.
      _logger.recordError(e, st, reason: 'LiveKit connect failed: $serverUrl');
      await _roomEvents?.cancel();
      _roomEvents = null;
      try {
        await room.dispose();
      } catch (_) {}
      rethrow;
    }

    _room = room;
    _roomName = room.name;
    _lifecycle.add(
      CallRoomEvent(
          lifecycle: CallRoomLifecycle.connected, roomName: room.name),
    );
    return room;
  }

  @override
  Future<void> disconnect() => _enqueue(_disconnect);

  Future<void> _disconnect() async {
    await _roomEvents?.cancel();
    _roomEvents = null;

    final room = _room;
    _room = null;
    _roomName = null;
    if (room == null) return;

    try {
      await room.disconnect();
    } catch (e) {
      _logger.log('disconnect failed: $e');
    }
    try {
      await room.dispose();
    } catch (e) {
      _logger.log('dispose failed: $e');
    }
  }

  void _onRoomEvent(RoomEvent event) {
    final lifecycle = switch (event) {
      RoomReconnectingEvent() => CallRoomLifecycle.reconnecting,
      RoomReconnectedEvent() => CallRoomLifecycle.reconnected,
      RoomDisconnectedEvent() => CallRoomLifecycle.disconnected,
      _ => null,
    };
    if (lifecycle == null) return;

    _lifecycle.add(
      CallRoomEvent(
        lifecycle: lifecycle,
        roomName: _roomName,
        reason: event is RoomDisconnectedEvent ? '${event.reason}' : null,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _lifecycle.close();
  }
}
