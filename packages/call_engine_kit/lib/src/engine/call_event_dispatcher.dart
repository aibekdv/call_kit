import 'dart:async';

import 'package:call_native_kit/call_native_kit.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../config/call_timeouts.dart';
import '../domain/entities/call_lifecycle_state.dart';
import '../domain/entities/call_session_state.dart';
import '../domain/entities/call_view_state.dart';
import '../ports/call_room_service.dart';
import 'call_timer_manager.dart';
import 'expiring_event_cache.dart';

/// Everything that happens to a call from outside it: the network coming and
/// going, the operating system's call UI, picture-in-picture, and the server
/// saying the call is over.
class CallEventDispatcher {
  CallEventDispatcher({
    required this.session,
    required this.view,
    required Connectivity connectivity,
    required CallRoomService roomService,
    required CallTimerManager timers,
    required this.onTransition,
    required this.onClear,
    required this.onAcceptIncoming,
    required this.onDecline,
    required this.onHangup,
    required this.onToggleMute,
    required this.onIncomingCall,
    required this.getCurrentRoomName,
    required this.getCurrentCallId,
    required this.isDisposed,
    CallNativeKit? native,
    CallTimeouts timeouts = const CallTimeouts(),
    void Function(CallHandle call)? onCallNotificationTapped,
    CallLogger logger = const SilentCallLogger(),
  })  : _connectivity = connectivity,
        _roomService = roomService,
        _timers = timers,
        _native = native ?? CallNativeKit.instance,
        _timeouts = timeouts,
        _onCallNotificationTapped = onCallNotificationTapped,
        _logger = logger;

  final ValueNotifier<CallSessionState> session;
  final ValueNotifier<CallViewState> view;

  final Connectivity _connectivity;
  final CallRoomService _roomService;
  final CallTimerManager _timers;
  final CallNativeKit _native;
  final CallTimeouts _timeouts;
  final void Function(CallHandle call)? _onCallNotificationTapped;
  final CallLogger _logger;

  final void Function(CallLifecycleState next, {String? error}) onTransition;
  final Future<void> Function() onClear;
  final Future<void> Function() onAcceptIncoming;
  final Future<void> Function() onDecline;
  final Future<void> Function() onHangup;
  final Future<void> Function() onToggleMute;
  final void Function(CallHandle call) onIncomingCall;
  final String? Function() getCurrentRoomName;
  final String? Function() getCurrentCallId;
  final bool Function() isDisposed;

  final ExpiringEventCache _seen = ExpiringEventCache();

  StreamSubscription<CallNativeEvent>? _nativeEvents;
  StreamSubscription<List<ConnectivityResult>>? _connectivityEvents;

  bool _started = false;
  bool _syncingPip = false;

  void start() {
    if (_started) return;
    _started = true;
    _nativeEvents = _native.events.listen(_onNativeEvent);
    _connectivityEvents = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  Future<void> _onNativeEvent(CallNativeEvent event) async {
    if (isDisposed()) return;

    switch (event) {
      case IncomingCallReceived(:final push):
        if (!_seen.putIfNew('incoming:${push.callId}')) return;
        onIncomingCall(push.toHandle());

      case CallCancelledRemotely(:final push):
        if (!_seen.putIfNew('cancelled:${push.callId}')) return;
        await _onRemoteEnded(push.callId, push.roomName);

      case SystemCallActionReceived(:final action):
        await _onSystemAction(action);

      case PipModeChanged(:final isInPip):
        _setPipMode(isInPip);

      case PipActionReceived(:final action):
        await switch (action) {
          PipAction.mute => onToggleMute(),
          PipAction.hangup => onHangup(),
        };

      case PipAttachmentFailed(:final trackId, :final reason):
        // Not fatal — the window shows a placeholder — but it is the shape a
        // flutter_webrtc upgrade takes, and silence here is how it gets missed.
        _logger.recordError(
          StateError('picture-in-picture could not attach $trackId: $reason'),
          StackTrace.current,
          reason: 'pip attachment failed',
        );

      case VoipPushTokenUpdated():
        // The host registers tokens with its own server.
        break;
    }
  }

  Future<void> _onSystemAction(SystemCallAction action) async {
    switch (action.kind) {
      case SystemCallActionKind.incoming:
        final call = action.call;
        if (call == null) return;
        if (!_seen.putIfNew('incoming:${call.callId}')) return;
        onIncomingCall(call);

      case SystemCallActionKind.accept:
        _timers.startAnswerGuard();
        await _native.clearPendingCall();
        await onAcceptIncoming();

      case SystemCallActionKind.decline:
        await onDecline();

      case SystemCallActionKind.ended:
        // Our own end() makes the system report one straight back at us.
        // Acting on that echo tears the call down twice.
        final uuid = action.systemUuid;
        if (uuid != null &&
            _native.systemUi.wasRecentlyEndedProgrammatically(uuid)) {
          return;
        }
        await onHangup();

      case SystemCallActionKind.timeout:
        // Only a call that is still ringing can time out; after an accept this
        // is the system tidying up behind itself.
        if (session.value.status != CallLifecycleState.incomingRinging) return;
        onTransition(CallLifecycleState.ended);
        await onClear();

      case SystemCallActionKind.callback:
        final call = action.call;
        if (call != null) _onCallNotificationTapped?.call(call);

      case SystemCallActionKind.toggleMute:
        await onToggleMute();

      case SystemCallActionKind.toggleHold:
      case SystemCallActionKind.start:
      case SystemCallActionKind.toggleAudioSession:
        break;
    }
  }

  /// Ends the call because the far side or the server said so.
  Future<void> _onRemoteEnded(String callId, String roomName) async {
    final matches = getCurrentCallId() == callId ||
        getCurrentRoomName() == roomName ||
        _roomService.roomName == roomName;
    if (!matches) return;

    // Still ringing: hold our screen so the callee's system call UI dismisses
    // first. Closing ours first looks like we hung up on someone still being
    // rung.
    if (session.value.status == CallLifecycleState.outgoingRinging) {
      await Future<void>.delayed(_timeouts.outgoingCloseDelay);
      if (isDisposed() ||
          session.value.status != CallLifecycleState.outgoingRinging) {
        return;
      }
    }

    onTransition(CallLifecycleState.ended);
    await onClear();
  }

  void _setPipMode(bool isInPip) {
    if (isDisposed() || view.value.isInSystemPip == isInPip) return;
    view.value = view.value.copyWith(isInSystemPip: isInPip);
  }

  /// Re-asks the platform whether we are in picture-in-picture.
  ///
  /// Android renders the Flutter tree inside the small window and can miss the
  /// push notification of the mode change; entering or leaving always changes
  /// the window metrics, which is the cue to call this.
  Future<void> syncPipMode() async {
    if (isDisposed() || _syncingPip) return;
    _syncingPip = true;
    try {
      final isInPip = await _native.pip.queryIsInPip();
      if (isInPip == null || isDisposed()) return;
      _setPipMode(isInPip);
    } finally {
      _syncingPip = false;
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final online = results.any((result) => result != ConnectivityResult.none);
    final status = session.value.status;

    if (!online) {
      if (status == CallLifecycleState.inCall ||
          status == CallLifecycleState.connecting) {
        onTransition(CallLifecycleState.reconnecting);
        _timers.startReconnectTimeout();
      }
      return;
    }

    // Back online: give the media SDK a fresh window to reconnect in rather
    // than letting the old deadline expire on a connection that is now fine.
    if (status == CallLifecycleState.reconnecting) {
      _timers.startReconnectTimeout();
    }
  }

  Future<void> dispose() async {
    await _nativeEvents?.cancel();
    await _connectivityEvents?.cancel();
    _nativeEvents = null;
    _connectivityEvents = null;
    _seen.clear();
    _started = false;
  }
}
