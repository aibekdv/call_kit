import 'package:call_native_kit/call_native_kit.dart' show CallHandle;
import 'package:flutter/foundation.dart';

import '../config/call_engine_strings.dart';
import '../domain/entities/call_lifecycle_state.dart';
import '../domain/entities/call_media_state.dart';
import '../domain/entities/call_session_state.dart';
import '../domain/entities/call_view_state.dart';
import '../domain/models/call_connection_info.dart';
import '../ports/call_logger.dart';
import '../ports/call_room_service.dart';
import '../ports/call_signaling_client.dart';
import 'call_media_controls.dart';
import 'call_retry.dart';
import 'call_room_event_handler.dart';
import 'call_server_actions.dart';
import 'call_timer_manager.dart';

/// Joining, answering and hanging up.
class CallLifecycleActions {
  CallLifecycleActions({
    required ValueNotifier<CallSessionState> session,
    required ValueNotifier<CallMediaState> media,
    required ValueNotifier<CallViewState> view,
    required CallSignalingClient signaling,
    required CallRoomService roomService,
    required CallTimerManager timers,
    required CallRoomEventHandler roomHandler,
    required CallMediaControls mediaControls,
    required Future<void> Function(CallHandle call) onTransitionSystemUi,
    required void Function(CallLifecycleState next, {String? error})
        onTransition,
    required void Function(Object error) onError,
    required Future<void> Function() onClear,
    required bool Function() isDisposed,
    required CallEngineStringsResolver strings,
    CallLogger logger = const SilentCallLogger(),
  })  : _session = session,
        _media = media,
        _view = view,
        _signaling = signaling,
        _roomService = roomService,
        _timers = timers,
        _roomHandler = roomHandler,
        _mediaControls = mediaControls,
        _onTransitionSystemUi = onTransitionSystemUi,
        _onTransition = onTransition,
        _onError = onError,
        _onClear = onClear,
        _isDisposed = isDisposed,
        _strings = strings,
        _logger = logger,
        _server = CallServerActions(signaling: signaling, logger: logger),
        _retry = CallRetry(logger: logger);

  final ValueNotifier<CallSessionState> _session;
  final ValueNotifier<CallMediaState> _media;
  final ValueNotifier<CallViewState> _view;
  final CallSignalingClient _signaling;
  final CallRoomService _roomService;
  final CallTimerManager _timers;
  final CallRoomEventHandler _roomHandler;
  final CallMediaControls _mediaControls;
  final Future<void> Function(CallHandle call) _onTransitionSystemUi;
  final void Function(CallLifecycleState next, {String? error}) _onTransition;
  final void Function(Object error) _onError;
  final Future<void> Function() _onClear;
  final bool Function() _isDisposed;
  final CallEngineStringsResolver _strings;
  final CallLogger _logger;
  final CallServerActions _server;
  final CallRetry _retry;

  String? currentRoomName;
  String? currentCallId;

  /// Guards against two hang-ups racing — from the button and from the system
  /// call UI, which is a normal thing for a user to manage.
  bool _hangingUp = false;

  String? get _callId => _server.resolveCallId(
        currentCallId,
        currentRoomName,
        _session.value.roomName,
      );

  /// Connects to the media room and starts publishing.
  Future<void> joinRoom({
    required CallConnectionInfo connectionInfo,
    required bool isVideo,
    required bool isGroup,
    String? callId,
    String? displayName,
    String? avatarUrl,
    bool acceptedViaSystemUi = false,
  }) async {
    if (_isDisposed()) return;

    _timers.startAnswerGuard();
    currentRoomName = connectionInfo.roomName;
    currentCallId = callId ?? connectionInfo.callId;

    _session.value = CallSessionState(
      status: CallLifecycleState.connecting,
      callId: currentCallId,
      roomName: connectionInfo.roomName,
      displayName: displayName,
      avatarUrl: avatarUrl,
      isVideo: isVideo,
      isGroup: isGroup,
    );
    _view.value = _view.value.copyWith(isOverlayExpanded: true);
    _timers.startConnectingTimeout();

    if (!await _mediaControls.requestPermissions(isVideo: isVideo)) {
      _timers.cancelAnswerGuard();
      // The message is already in the session; failing without one would
      // replace an actionable explanation with a blank error.
      _onTransition(CallLifecycleState.failed);
      await _onClear();
      return;
    }

    try {
      final room = await _roomService.connect(
        connectionInfo.serverUrl,
        connectionInfo.token,
      );
      await _roomHandler.subscribe(room);
      // Anyone already in the room never announces themselves, so without this
      // the call looks empty until the next person moves.
      _roomHandler.refreshRemoteState();

      await _mediaControls.initAudioForCall(
        isVideo: isVideo,
        acceptedViaSystemUi: acceptedViaSystemUi,
      );

      await room.localParticipant?.setMicrophoneEnabled(true);
      if (isVideo) {
        await room.localParticipant?.setCameraEnabled(true);
        _media.value = _media.value.copyWith(isLocalVideoEnabled: true);
      }

      if (room.remoteParticipants.isNotEmpty) {
        _timers.cancelAnswerGuard();
        _timers.cancelConnectingTimeout();
        _onTransition(CallLifecycleState.inCall);
      }
    } catch (e, st) {
      _logger.recordError(e, st, reason: 'join call');
      _timers.cancelAnswerGuard();
      _onError(e);
      await _onClear();
    }
  }

  /// Answers a call the user accepted.
  Future<void> acceptIncomingCall() async {
    if (_isDisposed()) return;
    if (_session.value.status != CallLifecycleState.incomingRinging) return;

    final session = _session.value;
    final roomName = session.roomName;
    if (roomName == null) return;

    _session.value = session.copyWith(status: CallLifecycleState.connecting);
    _view.value = _view.value.copyWith(isOverlayExpanded: true);

    CallConnectionInfo? connection;
    try {
      // Retried, unlike most requests: this one stands between the user and a
      // call they have already agreed to take.
      connection = await _retry.call<CallConnectionInfo>(
        action: () => _signaling.joinCall(
          callId: currentCallId ?? roomName,
          roomName: roomName,
        ),
        shouldContinue: () => _session.value.hasActiveCall,
        onError: (e, attempt) => _logger.log('answer attempt $attempt: $e'),
      );
    } catch (e, st) {
      _logger.recordError(e, st, reason: 'answer call');
      _onError(_strings().couldNotConnect);
      await _onClear();
      return;
    }

    // Null means the call went away while we were retrying.
    if (connection == null) return;

    // Promote the system call entry before joining: on Android the incoming
    // full-screen UI does not go away on its own, and the user would be in a
    // call while their phone still looks like it is ringing.
    await _onTransitionSystemUi(
      CallHandle(
        callId: currentCallId ?? roomName,
        roomName: roomName,
        displayName: session.displayName ?? '',
        isVideo: session.isVideo,
        isGroup: session.isGroup,
        avatarUrl: session.avatarUrl,
      ),
    );

    await joinRoom(
      connectionInfo: connection,
      isVideo: session.isVideo,
      isGroup: session.isGroup,
      callId: currentCallId,
      displayName: session.displayName,
      avatarUrl: session.avatarUrl,
      acceptedViaSystemUi: true,
    );
  }

  /// Rejects a call that is ringing.
  ///
  /// Ignored while an accept is in flight: the system takes its call UI away
  /// the moment the user accepts, and a late decline arriving from it would
  /// hang up the call they just answered.
  Future<void> declineCall() =>
      _finish('decline', () => _server.decline(_callId), skipIfAnswering: true);

  /// Withdraws a call that has not been answered.
  Future<void> cancelOutgoingCall() =>
      _finish('cancel', () => _server.cancel(_callId));

  /// Ends the call for everyone.
  Future<void> hangupCall() => _finish('end', () => _server.end(_callId));

  /// Leaves a group call without ending it for the others.
  Future<void> leaveGroupCall() =>
      _finish('leave', () => _server.leave(_callId));

  Future<void> heartbeat() => _server.heartbeat(_callId);

  Future<void> _finish(
    String action,
    Future<void> Function() request, {
    bool skipIfAnswering = false,
  }) async {
    if (skipIfAnswering && _timers.isAnswering) return;
    if (_hangingUp) return;

    _hangingUp = true;
    _logger.log('$action call ${_callId ?? '-'}');
    try {
      await request();
      _onTransition(CallLifecycleState.ended);
    } finally {
      _hangingUp = false;
    }
  }
}
