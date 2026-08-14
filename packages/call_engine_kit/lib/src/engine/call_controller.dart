import 'dart:async';

import 'package:call_native_kit/call_native_kit.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' show Room;

import '../config/call_engine_config.dart';
import '../domain/entities/call_audio_route.dart';
import '../domain/entities/call_chat_message.dart';
import '../domain/entities/call_lifecycle_state.dart';
import '../domain/entities/call_media_state.dart';
import '../domain/entities/call_participants_state.dart';
import '../domain/entities/call_screen_share_state.dart';
import '../domain/entities/call_session_state.dart';
import '../domain/entities/call_snapshot.dart';
import '../domain/entities/call_timing_state.dart';
import '../domain/entities/call_view_state.dart';
import '../domain/models/call_connection_info.dart';
import '../ports/call_room_service.dart';
import 'call_event_dispatcher.dart';
import 'call_lifecycle_actions.dart';
import 'call_media_controls.dart';
import 'call_native_bridge.dart';
import 'call_outgoing_flow.dart';
import 'call_room_event_handler.dart';
import 'call_snapshot_publisher.dart';
import 'call_state_machine.dart';
import 'call_timer_manager.dart';
import 'live_kit_room_service.dart';

/// The call, as one object.
///
/// Everything here delegates: this class exists to wire nine collaborators
/// together and to own the two things that genuinely need a single owner —
/// the lifecycle transition, and teardown.
class CallController {
  CallController(CallEngineConfig config, {CallNativeKit? native})
      : _config = config,
        _native = native ?? CallNativeKit.instance,
        _roomService = config.roomService ??
            LiveKitRoomService(
              options: config.roomOptions,
              logger: config.logger,
            ) {
    _publisher = CallSnapshotPublisher(roomGetter: () => _roomService.room);

    _nativeBridge = CallNativeBridge(
      session: session,
      participants: participants,
      roomGetter: () => _roomService.room,
      native: _native,
    );

    _timers = CallTimerManager(
      session: session,
      timeouts: config.timeouts,
      strings: config.strings,
      logger: config.logger,
      onTransition: _transition,
      onClear: clear,
      onEndCall: _endOnServer,
      onHeartbeat: () => _actions.heartbeat(),
    );

    _stateMachine = CallStateMachine(
      session: session,
      timing: timing,
      logger: config.logger,
      onCancelAllTimers: _timers.cancelAllTimers,
    );

    _roomHandler = CallRoomEventHandler(
      session: session,
      media: media,
      participants: participants,
      screenShare: screenShare,
      roomService: _roomService,
      timeouts: config.timeouts,
      logger: config.logger,
      onTransition: _transition,
      onClear: clear,
      onCancelAnswerGuard: _timers.cancelAnswerGuard,
      onCancelConnectingTimeout: _timers.cancelConnectingTimeout,
      onLocalScreenShareStopped: () => _mediaControls.cleanupScreenShare(),
      onPreferredVideoTrackChanged: _nativeBridge.syncPreferredVideoTrack,
    );

    _mediaControls = CallMediaControls(
      session: session,
      media: media,
      screenShare: screenShare,
      view: view,
      roomService: _roomService,
      permissions: config.permissions,
      strings: config.strings,
      native: _native,
      logger: config.logger,
      onScreenShareBlocked: () =>
          toastError.value = config.strings().screenShareBlocked,
    );

    _actions = CallLifecycleActions(
      session: session,
      media: media,
      view: view,
      signaling: config.signaling,
      roomService: _roomService,
      timers: _timers,
      roomHandler: _roomHandler,
      mediaControls: _mediaControls,
      strings: config.strings,
      logger: config.logger,
      onTransitionSystemUi: _native.systemUi.transitionToOngoing,
      onTransition: _transition,
      onError: onError,
      onClear: clear,
      isDisposed: () => _disposed,
    );

    _outgoing = CallOutgoingFlow(
      session: session,
      media: media,
      participants: participants,
      screenShare: screenShare,
      view: view,
      timing: timing,
      toastError: toastError,
      roomService: _roomService,
      timers: _timers,
      roomHandler: _roomHandler,
      mediaControls: _mediaControls,
      actions: _actions,
      connectivity: config.connectivity ?? Connectivity(),
      strings: config.strings,
      logger: config.logger,
      onRegisterWithSystemUi: _native.systemUi.startOutgoing,
      onTransition: _transition,
      onError: onError,
      onClear: clear,
      isDisposed: () => _disposed,
      onInvalidatePendingClear: invalidatePendingClear,
    );

    _events = CallEventDispatcher(
      session: session,
      view: view,
      connectivity: config.connectivity ?? Connectivity(),
      roomService: _roomService,
      timers: _timers,
      native: _native,
      timeouts: config.timeouts,
      logger: config.logger,
      onCallNotificationTapped: config.onCallNotificationTapped,
      onTransition: _transition,
      onClear: clear,
      onAcceptIncoming: acceptIncomingCall,
      onDecline: declineCall,
      onHangup: hangupCall,
      onToggleMute: toggleMute,
      onIncomingCall: setIncomingCall,
      getCurrentRoomName: () => _actions.currentRoomName,
      getCurrentCallId: () => _actions.currentCallId,
      isDisposed: () => _disposed,
    );

    _publisher.start();
    _nativeBridge.start();
  }

  final CallEngineConfig _config;
  final CallNativeKit _native;
  final CallRoomService _roomService;

  late final CallSnapshotPublisher _publisher;
  late final CallNativeBridge _nativeBridge;
  late final CallTimerManager _timers;
  late final CallStateMachine _stateMachine;
  late final CallRoomEventHandler _roomHandler;
  late final CallMediaControls _mediaControls;
  late final CallLifecycleActions _actions;
  late final CallOutgoingFlow _outgoing;
  late final CallEventDispatcher _events;

  bool _disposed = false;
  int _clearSequence = 0;

  // ── State ──────────────────────────────────────────────────────────────

  ValueNotifier<CallSessionState> get session => _publisher.session;
  ValueNotifier<CallMediaState> get media => _publisher.media;
  ValueNotifier<CallParticipantsState> get participants =>
      _publisher.participants;
  ValueNotifier<CallScreenShareState> get screenShare => _publisher.screenShare;
  ValueNotifier<CallViewState> get view => _publisher.view;
  ValueNotifier<CallTimingState> get timing => _publisher.timing;

  /// A message to show once and forget. Set to null after showing it.
  final ValueNotifier<String?> toastError = ValueNotifier(null);

  /// Fires when any part of the call state changes.
  Listenable get stateChanged => _publisher.stateChanged;

  CallSnapshot get currentSnapshot => _publisher.current;

  Stream<CallSnapshot> get snapshots => _publisher.snapshots;

  /// The media room, for rendering video. Null outside a call.
  Room? get room => _roomService.room;

  ValueListenable<List<CallChatMessage>> get chatMessages =>
      _roomHandler.chatMessages;

  bool get isDisposed => _disposed;

  bool get isInSystemPip => view.value.isInSystemPip || _nativeBridge.isInPip;

  // ── Starting a call ────────────────────────────────────────────────────

  /// Begins listening for incoming calls and system events.
  void start() => _events.start();

  Future<void> startOutgoingCall({
    required Future<CallConnectionInfo> Function() fetchConnection,
    required String roomName,
    required String displayName,
    required bool isVideo,
    String? avatarUrl,
    bool isGroup = false,
  }) async {
    if (_disposed) return;
    return _outgoing.startOutgoingCall(
      fetchConnection: fetchConnection,
      roomName: roomName,
      displayName: displayName,
      isVideo: isVideo,
      avatarUrl: avatarUrl,
      isGroup: isGroup,
    );
  }

  Future<void> joinRoom({
    required CallConnectionInfo connectionInfo,
    required bool isVideo,
    required bool isGroup,
    String? callId,
    String? displayName,
    String? avatarUrl,
    bool acceptedViaSystemUi = false,
  }) async {
    if (_disposed) return;
    return _actions.joinRoom(
      connectionInfo: connectionInfo,
      isVideo: isVideo,
      isGroup: isGroup,
      callId: callId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      acceptedViaSystemUi: acceptedViaSystemUi,
    );
  }

  /// Shows an incoming call.
  ///
  /// Called for you when the system reports one; call it directly only if you
  /// are announcing a call the system does not know about.
  void setIncomingCall(CallHandle call) {
    if (_disposed) return;

    // A previous call's teardown may still be running. Tell it not to reset
    // the state we are about to set, or accepting this call finds an idle
    // session and bails out.
    invalidatePendingClear();

    _actions.currentCallId = call.callId;
    _actions.currentRoomName = call.roomName;
    session.value = CallSessionState(
      status: CallLifecycleState.incomingRinging,
      callId: call.callId,
      roomName: call.roomName,
      displayName: call.displayName,
      avatarUrl: call.avatarUrl,
      isVideo: call.isVideo,
      isGroup: call.isGroup,
    );
    view.value = view.value.copyWith(isOverlayExpanded: true);
  }

  /// Joins a call that is already running — one the user picked from a list of
  /// active calls rather than one that rang.
  Future<void> joinExistingCall(CallHandle call) async {
    if (_disposed) return;
    setIncomingCall(call);
    await acceptIncomingCall();
  }

  Future<void> acceptIncomingCall() async {
    if (_disposed) return;
    invalidatePendingClear();
    return _actions.acceptIncomingCall();
  }

  // ── Ending a call ──────────────────────────────────────────────────────

  Future<void> declineCall() async {
    if (_disposed) return;
    await _actions.declineCall();
    await clear();
  }

  /// Ends the call the right way for whatever it currently is.
  ///
  /// One button, four different things: rejecting a call that is ringing,
  /// withdrawing one nobody answered, leaving a group without ending it, or
  /// ending a one-to-one call.
  Future<void> hangupCall() async {
    if (_disposed) return;

    final status = session.value.status;
    final isUnansweredOutgoing = status == CallLifecycleState.outgoingRinging ||
        (status == CallLifecycleState.connecting &&
            _actions.currentCallId != null &&
            room == null);

    if (status == CallLifecycleState.incomingRinging) {
      await _actions.declineCall();
    } else if (isUnansweredOutgoing) {
      await _actions.cancelOutgoingCall();
    } else if (session.value.isGroup &&
        status == CallLifecycleState.inCall &&
        session.value.activeParticipants > 2) {
      await _actions.leaveGroupCall();
    } else {
      await _actions.hangupCall();
    }

    await clear();
  }

  // ── During a call ──────────────────────────────────────────────────────

  Future<void> toggleMute() => _mediaControls.toggleMute();
  Future<void> toggleVideo() => _mediaControls.toggleVideo();
  Future<void> toggleScreenShare() => _mediaControls.toggleScreenShare();
  Future<void> switchCamera() => _mediaControls.switchCamera();
  Future<void> setAudioRoute(CallAudioRoute route) =>
      _mediaControls.setAudioRoute(route);
  Future<void> cycleAudioRoute() => _mediaControls.cycleAudioRoute();
  void toggleViewMode() => _mediaControls.toggleViewMode();

  Future<void> sendChatMessage(String text, {required String localName}) =>
      _roomHandler.sendChatMessage(text, localName: localName);

  Future<bool> enterPip() => _nativeBridge.enterPip();
  Future<void> syncPipMode() => _events.syncPipMode();

  void setOverlayExpanded({required bool expanded}) {
    if (_disposed) return;
    view.value = view.value.copyWith(isOverlayExpanded: expanded);
  }

  void startAnswerGuard() => _timers.startAnswerGuard();
  void cancelAnswerGuard() => _timers.cancelAnswerGuard();

  /// Fails the call with a message the user can read.
  void onError(Object error) {
    if (_disposed) return;
    _transition(
      CallLifecycleState.failed,
      error: error is String ? error : _config.strings().couldNotConnect,
    );
  }

  // ── Internals ──────────────────────────────────────────────────────────

  void _transition(CallLifecycleState next, {String? error}) {
    _stateMachine.transition(next, error: error);

    if (next == CallLifecycleState.inCall) {
      _timers.startHeartbeat();
      final callId = _actions.currentCallId ?? _actions.currentRoomName;
      if (callId != null) unawaited(_native.systemUi.setConnected(callId));
      if (session.value.isVideo) {
        _nativeBridge
          ..setActiveVideoCall(active: true)
          ..syncPreferredVideoTrack();
      }
    } else if (next.isTerminal) {
      _timers.cancelHeartbeat();
      _nativeBridge.setActiveVideoCall(active: false);
      unawaited(_nativeBridge.closePip());
    }
  }

  Future<void> _endOnServer() async {
    final callId = _actions.currentCallId ??
        _actions.currentRoomName ??
        session.value.roomName;
    if (callId == null) return;
    try {
      await _config.signaling.endCall(callId);
    } catch (_) {}
  }

  /// Marks any in-flight [clear] as superseded.
  ///
  /// Teardown is bounded but not instant, and a new call can begin inside that
  /// window. Without this, the old teardown's final reset lands on the new
  /// call's state and wipes it.
  void invalidatePendingClear() => _clearSequence++;

  /// Tears the call down.
  ///
  /// Every step is best-effort and the whole thing is time-bounded: the call
  /// is over from the user's point of view the moment they hang up, and no
  /// amount of failed cleanup should keep them on a call screen.
  Future<void> clear() async {
    final sequence = ++_clearSequence;
    _timers.cancelAllTimers();

    try {
      await _mediaControls.cleanupScreenShare().catchError((Object _) {});
      await Future.wait([
        _roomHandler.unsubscribe().catchError((Object _) {}),
        _roomService.disconnect().catchError((Object _) {}),
        _native.systemUi.endAll().catchError((Object _) {}),
        _native.audio.deactivate().catchError((Object _) {}),
      ]).timeout(_config.timeouts.clear, onTimeout: () => const <void>[]);
    } finally {
      _actions.currentRoomName = null;
      _actions.currentCallId = null;
      _mediaControls.resetCameraPosition();
      _nativeBridge.setActiveVideoCall(active: false);

      // Skip the reset if a newer call has claimed the state in the meantime.
      if (sequence == _clearSequence) {
        _publisher.resetAll();
        _nativeBridge.syncActiveCallFlag();
      }
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _stateMachine.disposed = true;

    await clear();
    await _events.dispose();

    // Reset before disposing the notifiers, so listeners see the call end
    // rather than a disposed notifier.
    _publisher.resetAll();
    _nativeBridge.syncActiveCallFlag();

    _nativeBridge.dispose();
    await _publisher.dispose();
    _roomHandler.dispose();
    toastError.dispose();
  }
}
