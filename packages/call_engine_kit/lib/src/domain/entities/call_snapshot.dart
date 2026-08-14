import 'package:equatable/equatable.dart';
import 'package:livekit_client/livekit_client.dart' show Room;

import 'call_media_state.dart';
import 'call_participants_state.dart';
import 'call_screen_share_state.dart';
import 'call_session_state.dart';
import 'call_timing_state.dart';
import 'call_view_state.dart';

/// The whole call, in one immutable value.
///
/// The engine also exposes each part as its own listenable, so a widget can
/// rebuild on just the piece it renders. This aggregate is for the cases that
/// need everything at once — logging, tests, and any consumer that would
/// rather have a stream than six listeners.
class CallSnapshot extends Equatable {
  const CallSnapshot({
    this.session = CallSessionState.idle,
    this.media = CallMediaState.initial,
    this.participants = CallParticipantsState.empty,
    this.screenShare = CallScreenShareState.inactive,
    this.view = CallViewState.initial,
    this.timing = CallTimingState.initial,
    this.room,
  });

  static const initial = CallSnapshot();

  final CallSessionState session;
  final CallMediaState media;
  final CallParticipantsState participants;
  final CallScreenShareState screenShare;
  final CallViewState view;
  final CallTimingState timing;

  /// The LiveKit room, for widgets that render video tracks.
  ///
  /// Compared by identity, not value — a `Room` is a live object whose
  /// internals change constantly, and deep-comparing it would make every
  /// snapshot differ from the last.
  final Room? room;

  CallSnapshot copyWith({
    CallSessionState? session,
    CallMediaState? media,
    CallParticipantsState? participants,
    CallScreenShareState? screenShare,
    CallViewState? view,
    CallTimingState? timing,
    Room? room,
    bool clearRoom = false,
  }) =>
      CallSnapshot(
        session: session ?? this.session,
        media: media ?? this.media,
        participants: participants ?? this.participants,
        screenShare: screenShare ?? this.screenShare,
        view: view ?? this.view,
        timing: timing ?? this.timing,
        room: clearRoom ? null : (room ?? this.room),
      );

  @override
  List<Object?> get props => [
        session,
        media,
        participants,
        screenShare,
        view,
        timing,
        room,
      ];
}
