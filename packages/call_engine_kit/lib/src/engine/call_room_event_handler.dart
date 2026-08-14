import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import '../config/call_timeouts.dart';
import '../domain/entities/call_chat_message.dart';
import '../domain/entities/call_lifecycle_state.dart';
import '../domain/entities/call_media_state.dart';
import '../domain/entities/call_participants_state.dart';
import '../domain/entities/call_screen_share_state.dart';
import '../domain/entities/call_session_state.dart';
import '../ports/call_logger.dart';
import '../ports/call_room_service.dart';
import 'call_chat_controller.dart';
import 'call_state_machine.dart';
import 'participants_state_reducer.dart';
import 'screen_share_event_handler.dart';

/// Turns what the media room reports into call state.
class CallRoomEventHandler {
  CallRoomEventHandler({
    required ValueNotifier<CallSessionState> session,
    required ValueNotifier<CallMediaState> media,
    required ValueNotifier<CallParticipantsState> participants,
    required ValueNotifier<CallScreenShareState> screenShare,
    required CallRoomService roomService,
    required void Function(CallLifecycleState next, {String? error})
        onTransition,
    required Future<void> Function() onClear,
    required VoidCallback onCancelAnswerGuard,
    required VoidCallback onCancelConnectingTimeout,
    Future<void> Function()? onLocalScreenShareStopped,
    VoidCallback? onPreferredVideoTrackChanged,
    CallTimeouts timeouts = const CallTimeouts(),
    CallLogger logger = const SilentCallLogger(),
  })  : _session = session,
        _participants = participants,
        _roomService = roomService,
        _onTransition = onTransition,
        _onClear = onClear,
        _onCancelAnswerGuard = onCancelAnswerGuard,
        _onCancelConnectingTimeout = onCancelConnectingTimeout,
        _onLocalScreenShareStopped = onLocalScreenShareStopped,
        _onPreferredVideoTrackChanged = onPreferredVideoTrackChanged,
        _timeouts = timeouts,
        _logger = logger,
        _reducer = ParticipantsStateReducer(
          media: media,
          participants: participants,
          session: session,
          roomGetter: () => roomService.room,
        ),
        _screenShareHandler = ScreenShareEventHandler(
          screenShare: screenShare,
          roomGetter: () => roomService.room,
        ),
        _chat = CallChatController(
          nameFor: (identity) => participants.value.names[identity],
          logger: logger,
        );

  /// How long an active-speaker change has to hold before the layout follows.
  ///
  /// Speaker detection flickers on every cough and keystroke; without this the
  /// main video swaps several times a second.
  static const _activeSpeakerDebounce = Duration(milliseconds: 300);

  final ValueNotifier<CallSessionState> _session;
  final ValueNotifier<CallParticipantsState> _participants;
  final CallRoomService _roomService;
  final void Function(CallLifecycleState next, {String? error}) _onTransition;
  final Future<void> Function() _onClear;
  final VoidCallback _onCancelAnswerGuard;
  final VoidCallback _onCancelConnectingTimeout;
  final Future<void> Function()? _onLocalScreenShareStopped;
  final VoidCallback? _onPreferredVideoTrackChanged;
  final CallTimeouts _timeouts;
  final CallLogger _logger;

  final ParticipantsStateReducer _reducer;
  final ScreenShareEventHandler _screenShareHandler;
  final CallChatController _chat;

  StreamSubscription<RoomEvent>? _events;
  Timer? _speakerDebounce;

  Room? get _room => _roomService.room;

  ValueListenable<List<CallChatMessage>> get chatMessages => _chat.messages;

  Future<void> subscribe(Room room) async {
    await _events?.cancel();
    _events = room.events.streamCtrl.stream.listen(_onRoomEvent);
    _chat.attach(room);
  }

  /// Recomputes remote state without waiting for an event.
  ///
  /// Call it right after joining: participants already in the room never
  /// announce themselves, so the call would otherwise look empty.
  void refreshRemoteState() => _reducer.recomputeNow();

  Future<void> sendChatMessage(String text, {required String localName}) {
    final room = _room;
    if (room == null) {
      _logger.log('chat: no room, dropping message');
      return Future.value();
    }
    return _chat.sendMessage(room, text, localName: localName);
  }

  Future<void> _onRoomEvent(RoomEvent event) async {
    switch (event) {
      case ParticipantConnectedEvent():
        _onCancelAnswerGuard();
        _onCancelConnectingTimeout();
        // Somebody arriving means the call is up — unless we are already past
        // that, in which case this is a stale event describing the past.
        if (!CallStateMachine.isBackward(
          _session.value.status,
          CallLifecycleState.inCall,
        )) {
          _onTransition(CallLifecycleState.inCall);
        }
        _reducer.schedule();
        _onPreferredVideoTrackChanged?.call();

      case ParticipantDisconnectedEvent():
        _reducer.schedule();
        _onPreferredVideoTrackChanged?.call();
        await _endIfEveryoneLeft();

      case TrackSubscribedEvent(:final publication):
        if (publication.isScreenShare) {
          _screenShareHandler.onRemoteStarted(
            publication.participant.identity,
          );
        }
        _reducer.schedule();
        _onPreferredVideoTrackChanged?.call();

      case TrackUnsubscribedEvent(:final publication):
        if (publication.isScreenShare) {
          _screenShareHandler.onRemoteStopped(
            publication.participant.identity,
          );
        }
        _reducer.schedule();
        _onPreferredVideoTrackChanged?.call();

      case LocalTrackPublishedEvent(:final publication):
        if (publication.isScreenShare) _screenShareHandler.onLocalPublished();

      case LocalTrackUnpublishedEvent(:final publication):
        if (publication.isScreenShare) {
          _screenShareHandler.onLocalUnpublished();
          // The user can stop sharing from the system UI, which the app never
          // sees otherwise.
          await _onLocalScreenShareStopped?.call();
        }

      case TrackMutedEvent():
      case TrackUnmutedEvent():
        _reducer.schedule();
        _onPreferredVideoTrackChanged?.call();

      case ActiveSpeakersChangedEvent(:final speakers):
        _onActiveSpeakers(speakers);

      case RoomReconnectingEvent():
        if (_session.value.status == CallLifecycleState.inCall) {
          _onTransition(CallLifecycleState.reconnecting);
        }

      case RoomReconnectedEvent():
        _onTransition(CallLifecycleState.inCall);
        _reducer.schedule();

      case RoomDisconnectedEvent():
        await _onRoomDisconnected();

      default:
        break;
    }
  }

  /// Ends a one-to-one call once the other side is gone.
  ///
  /// Group calls stay open: people drift in and out, and ending the call
  /// because it briefly emptied would be wrong.
  Future<void> _endIfEveryoneLeft() async {
    final remaining = _room?.remoteParticipants.length ?? 0;
    if (remaining > 0) return;
    if (_session.value.status != CallLifecycleState.inCall) return;
    if (_session.value.isGroup) return;

    _onTransition(CallLifecycleState.ended);
    await _onClear();
  }

  Future<void> _onRoomDisconnected() async {
    if (_session.value.status == CallLifecycleState.ended) return;

    // Still ringing: hold the caller's screen a moment so the callee's system
    // call UI dismisses first. Closing ours first looks like we hung up on
    // someone who is still being rung.
    if (_session.value.status == CallLifecycleState.outgoingRinging) {
      await Future<void>.delayed(_timeouts.outgoingCloseDelay);
      if (_session.value.status != CallLifecycleState.outgoingRinging) return;
    }

    _onTransition(CallLifecycleState.ended);
    await _onClear();
  }

  void _onActiveSpeakers(List<Participant> speakers) {
    _speakerDebounce?.cancel();
    _speakerDebounce = Timer(_activeSpeakerDebounce, () {
      final localIdentity = _room?.localParticipant?.identity;
      final remoteSpeaker = speakers
          .where((participant) => participant.identity != localIdentity)
          .firstOrNull;
      final previous = _participants.value.activeSpeakerIdentity;

      _participants.value = _participants.value.copyWith(
        isSpeaking: speakers.any(
          (participant) => participant.identity == localIdentity,
        ),
        activeSpeakerIdentity: remoteSpeaker?.identity,
      );

      if (previous != remoteSpeaker?.identity) {
        _onPreferredVideoTrackChanged?.call();
      }
    });
  }

  Future<void> unsubscribe() async {
    _speakerDebounce?.cancel();
    _speakerDebounce = null;
    await _events?.cancel();
    _events = null;

    final room = _room;
    if (room != null) _chat.detach(room);
    _chat.reset();
  }

  void dispose() => _chat.dispose();
}
