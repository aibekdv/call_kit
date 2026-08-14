import 'dart:async';

import 'package:call_native_kit/call_native_kit.dart' show CallHandle;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../config/call_engine_strings.dart';
import '../domain/entities/call_lifecycle_state.dart';
import '../domain/entities/call_media_state.dart';
import '../domain/entities/call_participants_state.dart';
import '../domain/entities/call_screen_share_state.dart';
import '../domain/entities/call_session_state.dart';
import '../domain/entities/call_timing_state.dart';
import '../domain/entities/call_view_state.dart';
import '../domain/models/call_connection_info.dart';
import '../domain/models/call_signaling_exception.dart';
import '../ports/call_logger.dart';
import '../ports/call_room_service.dart';
import 'call_lifecycle_actions.dart';
import 'call_media_controls.dart';
import 'call_room_event_handler.dart';
import 'call_timer_manager.dart';

/// Placing a call.
///
/// Most of this is refusing to start one: without a network, twice by
/// accident, or on top of a previous call that has not finished dying.
class CallOutgoingFlow {
  CallOutgoingFlow({
    required this.session,
    required this.media,
    required this.participants,
    required this.screenShare,
    required this.view,
    required this.timing,
    required this.toastError,
    required CallRoomService roomService,
    required CallTimerManager timers,
    required CallRoomEventHandler roomHandler,
    required CallMediaControls mediaControls,
    required CallLifecycleActions actions,
    required Connectivity connectivity,
    required Future<void> Function(CallHandle call) onRegisterWithSystemUi,
    required this.onTransition,
    required this.onError,
    required this.onClear,
    required this.isDisposed,
    required void Function() onInvalidatePendingClear,
    required CallEngineStringsResolver strings,
    CallLogger logger = const SilentCallLogger(),
  })  : _roomService = roomService,
        _timers = timers,
        _roomHandler = roomHandler,
        _mediaControls = mediaControls,
        _actions = actions,
        _connectivity = connectivity,
        _onRegisterWithSystemUi = onRegisterWithSystemUi,
        _onInvalidatePendingClear = onInvalidatePendingClear,
        _strings = strings,
        _logger = logger;

  /// How long a start may be in flight before a second tap is believed rather
  /// than treated as a double tap.
  static const _stuckStartThreshold = Duration(seconds: 10);

  /// Budget for clearing a previous call. Past it we start anyway — a hung
  /// disconnect must not make the phone unable to place calls.
  static const _staleClearBudget = Duration(seconds: 3);

  final ValueNotifier<CallSessionState> session;
  final ValueNotifier<CallMediaState> media;
  final ValueNotifier<CallParticipantsState> participants;
  final ValueNotifier<CallScreenShareState> screenShare;
  final ValueNotifier<CallViewState> view;
  final ValueNotifier<CallTimingState> timing;
  final ValueNotifier<String?> toastError;

  final CallRoomService _roomService;
  final CallTimerManager _timers;
  final CallRoomEventHandler _roomHandler;
  final CallMediaControls _mediaControls;
  final CallLifecycleActions _actions;
  final Connectivity _connectivity;
  final Future<void> Function(CallHandle call) _onRegisterWithSystemUi;
  final void Function() _onInvalidatePendingClear;
  final CallEngineStringsResolver _strings;
  final CallLogger _logger;

  final void Function(CallLifecycleState next, {String? error}) onTransition;
  final void Function(Object error) onError;
  final Future<void> Function() onClear;
  final bool Function() isDisposed;

  DateTime? _startingSince;

  Future<void> startOutgoingCall({
    required Future<CallConnectionInfo> Function() fetchConnection,
    required String roomName,
    required String displayName,
    required bool isVideo,
    String? avatarUrl,
    bool isGroup = false,
  }) async {
    if (isDisposed()) return;
    if (!await _preflight()) return;

    try {
      if (!await _clearStaleSession()) return;
      // A clear from the previous call may still be in flight; tell it not to
      // reset the state we are about to set.
      _onInvalidatePendingClear();

      _actions.currentRoomName = roomName;
      _setRingingState(roomName, displayName, avatarUrl, isVideo, isGroup);

      if (!await _mediaControls.requestPermissions(isVideo: isVideo)) {
        onTransition(CallLifecycleState.failed);
        await onClear();
        return;
      }

      final connection = await _fetchConnection(fetchConnection);
      if (connection == null || isDisposed()) return;

      // The call could have been cleared while we waited — by the user, by the
      // app going away, or by a cancellation arriving. Do not connect anyway.
      if (!session.value.hasActiveCall) {
        toastError.value = _strings().couldNotStartCall;
        return;
      }

      _timers.startRingingTimeout();
      _actions.currentRoomName = connection.roomName;
      _actions.currentCallId = connection.callId;
      _registerWithSystemUi(connection, isVideo);
      await _connect(connection, isVideo);
    } finally {
      _startingSince = null;
    }
  }

  /// Whether a call may be started at all.
  Future<bool> _preflight() async {
    final connectivity = await _connectivity.checkConnectivity();
    if (!connectivity.any((result) => result != ConnectivityResult.none)) {
      toastError.value = _strings().noConnection;
      return false;
    }

    final now = DateTime.now();
    final since = _startingSince;
    if (since != null && now.difference(since) < _stuckStartThreshold) {
      toastError.value = _strings().callAlreadyActive;
      return false;
    }
    _startingSince = now;
    return true;
  }

  /// Tears down whatever was left of a previous call, within a budget.
  Future<bool> _clearStaleSession() async {
    if (session.value.status == CallLifecycleState.idle) return true;
    _logger
        .log('clearing stale ${session.value.status.name} before a new call');
    await onClear().timeout(
      _staleClearBudget,
      onTimeout: () => _logger.log('stale clear timed out, starting anyway'),
    );
    return !isDisposed();
  }

  Future<CallConnectionInfo?> _fetchConnection(
    Future<CallConnectionInfo> Function() fetch,
  ) async {
    try {
      return await fetch();
    } on CallSignalingException catch (e) {
      _reportSignalingFailure(e);
      await onClear();
      return null;
    } catch (e, st) {
      _logger.recordError(e, st, reason: 'start call');
      onError(_strings().couldNotStartCall);
      await onClear();
      return null;
    }
  }

  /// Turns a refusal from the server into something the user can act on.
  void _reportSignalingFailure(CallSignalingException e) {
    final strings = _strings();
    switch (e.statusCode) {
      case 409:
        // The callee is on another call. Not an error — an outcome.
        onTransition(CallLifecycleState.ended, error: strings.partyBusy);
      case 429:
        toastError.value = strings.couldNotStartCall;
        onTransition(CallLifecycleState.ended);
      case 410:
        onTransition(CallLifecycleState.ended);
      default:
        onTransition(CallLifecycleState.ended);
        toastError.value = strings.couldNotStartCall;
    }
  }

  /// Registers the call with the operating system.
  ///
  /// Deliberately not awaited: iOS shows its call UI and Android raises a
  /// foreground service, and neither should delay connecting.
  void _registerWithSystemUi(CallConnectionInfo connection, bool isVideo) {
    unawaited(
      _onRegisterWithSystemUi(
        CallHandle(
          callId: connection.callId ?? connection.roomName,
          roomName: connection.roomName,
          displayName: session.value.displayName ?? '',
          isVideo: isVideo,
          isGroup: session.value.isGroup,
          avatarUrl: session.value.avatarUrl,
        ),
      ),
    );
  }

  void _setRingingState(
    String roomName,
    String displayName,
    String? avatarUrl,
    bool isVideo,
    bool isGroup,
  ) {
    session.value = CallSessionState(
      status: CallLifecycleState.outgoingRinging,
      roomName: roomName,
      displayName: displayName,
      avatarUrl: avatarUrl,
      isVideo: isVideo,
      isGroup: isGroup,
    );
    view.value = view.value.copyWith(isOverlayExpanded: true);
    media.value = CallMediaState.initial;
    participants.value = CallParticipantsState.empty;
    screenShare.value = CallScreenShareState.inactive;
    timing.value = CallTimingState.initial;
  }

  Future<void> _connect(CallConnectionInfo connection, bool isVideo) async {
    try {
      final room = await _roomService.connect(
        connection.serverUrl,
        connection.token,
      );
      await _roomHandler.subscribe(room);
      _roomHandler.refreshRemoteState();
      await _mediaControls.initAudioForCall(isVideo: isVideo);

      onTransition(CallLifecycleState.connecting);
      // Only a one-to-one call is worth ending server-side on timeout; a group
      // call outlives any one participant failing to arrive.
      _timers.startConnectingTimeout(notifyServer: !session.value.isGroup);

      await room.localParticipant?.setMicrophoneEnabled(true);
      if (isVideo) {
        await room.localParticipant?.setCameraEnabled(true);
        media.value = media.value.copyWith(isLocalVideoEnabled: true);
      }
    } catch (e, st) {
      _logger.recordError(e, st, reason: 'connect outgoing call');
      onError(e);
      await onClear();
    }
  }
}
