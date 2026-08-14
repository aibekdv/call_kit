import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' show Room;

import '../domain/entities/call_media_state.dart';
import '../domain/entities/call_participants_state.dart';
import '../domain/entities/call_screen_share_state.dart';
import '../domain/entities/call_session_state.dart';
import '../domain/entities/call_snapshot.dart';
import '../domain/entities/call_timing_state.dart';
import '../domain/entities/call_view_state.dart';

/// Owns the call's state and publishes it two ways.
///
/// Six separate listenables rather than one, because a call screen has parts
/// that update at wildly different rates: a mute button changes when the user
/// taps it, the participant list changes when the room does, and the speaker
/// indicator changes several times a second. One combined listenable would
/// rebuild every video surface on each of those.
///
/// [snapshots] is for consumers that want the whole thing as a stream.
class CallSnapshotPublisher {
  CallSnapshotPublisher({required Room? Function() roomGetter})
      : _roomGetter = roomGetter;

  final Room? Function() _roomGetter;

  final session = ValueNotifier(CallSessionState.idle);
  final media = ValueNotifier(CallMediaState.initial);
  final participants = ValueNotifier(CallParticipantsState.empty);
  final screenShare = ValueNotifier(CallScreenShareState.inactive);
  final view = ValueNotifier(CallViewState.initial);
  final timing = ValueNotifier(CallTimingState.initial);

  bool _disposed = false;
  VoidCallback? _dispatcher;
  final StreamController<CallSnapshot> _snapshots =
      StreamController<CallSnapshot>.broadcast();

  List<ValueNotifier<Object?>> get _all => [
        session,
        media,
        participants,
        screenShare,
        view,
        timing,
      ];

  /// Fires when any part changes.
  late final Listenable stateChanged = Listenable.merge(_all);

  Stream<CallSnapshot> get snapshots => _snapshots.stream;

  CallSnapshot get current => CallSnapshot(
        session: session.value,
        media: media.value,
        participants: participants.value,
        screenShare: screenShare.value,
        view: view.value,
        timing: timing.value,
        room: _roomGetter(),
      );

  void start() {
    _dispatcher = () {
      if (_disposed || _snapshots.isClosed) return;
      _snapshots.add(current);
    };
    stateChanged.addListener(_dispatcher!);
  }

  /// Returns every part to its initial value.
  void resetAll() {
    session.value = CallSessionState.idle;
    media.value = CallMediaState.initial;
    participants.value = CallParticipantsState.empty;
    screenShare.value = CallScreenShareState.inactive;
    view.value = CallViewState.initial;
    timing.value = CallTimingState.initial;
  }

  Future<void> dispose() async {
    _disposed = true;
    final dispatcher = _dispatcher;
    if (dispatcher != null) {
      stateChanged.removeListener(dispatcher);
      _dispatcher = null;
    }
    await _snapshots.close();
    for (final notifier in _all) {
      notifier.dispose();
    }
  }
}
