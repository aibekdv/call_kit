import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/call_engine_strings.dart';
import '../config/call_timeouts.dart';
import '../domain/entities/call_lifecycle_state.dart';
import '../domain/entities/call_session_state.dart';
import '../ports/call_logger.dart';

/// Every deadline in a call's life.
///
/// A call can stall at each stage with nothing to report it: the callee never
/// answers, the media server never accepts the join, a reconnect never
/// completes. Each timer here turns one of those silences into an outcome.
class CallTimerManager {
  CallTimerManager({
    required ValueNotifier<CallSessionState> session,
    required void Function(CallLifecycleState next, {String? error})
        onTransition,
    required Future<void> Function() onClear,
    required Future<void> Function() onEndCall,
    required Future<void> Function() onHeartbeat,
    required CallEngineStringsResolver strings,
    CallTimeouts timeouts = const CallTimeouts(),
    CallLogger logger = const SilentCallLogger(),
  })  : _session = session,
        _onTransition = onTransition,
        _onClear = onClear,
        _onEndCall = onEndCall,
        _onHeartbeat = onHeartbeat,
        _strings = strings,
        _timeouts = timeouts,
        _logger = logger;

  final ValueNotifier<CallSessionState> _session;
  final void Function(CallLifecycleState next, {String? error}) _onTransition;
  final Future<void> Function() _onClear;
  final Future<void> Function() _onEndCall;
  final Future<void> Function() _onHeartbeat;
  final CallEngineStringsResolver _strings;
  final CallTimeouts _timeouts;
  final CallLogger _logger;

  Timer? _connecting;
  Timer? _ringing;
  Timer? _reconnect;
  Timer? _answerGuard;
  Timer? _heartbeat;

  /// Whether an accept is in flight.
  ///
  /// Between the user pressing Accept and the app joining, the system has
  /// already stopped ringing and taken its UI away. Anything that would tear
  /// the call down in that window has to be ignored, or accepting a call
  /// occasionally hangs it up instead.
  bool isAnswering = false;

  void startAnswerGuard() {
    isAnswering = true;
    _answerGuard?.cancel();
    _answerGuard = Timer(_timeouts.answerGuard, () => isAnswering = false);
  }

  void cancelAnswerGuard() {
    _answerGuard?.cancel();
    _answerGuard = null;
    isAnswering = false;
  }

  /// Ends the call if nobody answers.
  void startRingingTimeout() {
    _ringing?.cancel();
    _ringing = Timer(_timeouts.ringing, () async {
      final status = _session.value.status;
      if (!status.isRinging) return;
      _logger.log('ringing timed out in ${status.name}');

      // Hold the caller's screen a moment longer than the callee's: the
      // cancellation reaches them by push, and closing first makes it look
      // like the callee is still being rung after we gave up.
      if (status == CallLifecycleState.outgoingRinging) {
        await Future<void>.delayed(_timeouts.outgoingCloseDelay);
        if (_session.value.status != CallLifecycleState.outgoingRinging) return;
      }

      _onTransition(CallLifecycleState.ended);
      await _onClear();
    });
  }

  /// Fails the call if the media room never accepts us.
  ///
  /// [notifyServer] for the outgoing side, which has a call on the server that
  /// would otherwise keep ringing the callee.
  void startConnectingTimeout({bool notifyServer = false}) {
    _connecting?.cancel();
    _connecting = Timer(_timeouts.connecting, () async {
      if (_session.value.status != CallLifecycleState.connecting) return;
      _logger.log('connecting timed out');
      _onTransition(CallLifecycleState.failed, error: _strings().noAnswer);
      if (notifyServer) await _onEndCall();
      await _onClear();
    });
  }

  /// Gives up on a reconnect that is not going to complete.
  void startReconnectTimeout() {
    _reconnect?.cancel();
    _reconnect = Timer(_timeouts.reconnect, () async {
      if (_session.value.status != CallLifecycleState.reconnecting) return;
      _logger.log('reconnect timed out');
      _onTransition(
        CallLifecycleState.failed,
        error: _strings().reconnectFailed,
      );
      await _onEndCall();
      await _onClear();
    });
  }

  /// Tells the server the call is still alive, so it can clean up after a
  /// participant whose device vanished.
  void startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(_timeouts.heartbeat, (_) async {
      if (_session.value.status != CallLifecycleState.inCall) return;
      try {
        await _onHeartbeat();
      } catch (e) {
        // A missed heartbeat is not worth failing a working call over.
        _logger.log('heartbeat failed: $e');
      }
    });
  }

  void cancelConnectingTimeout() {
    _connecting?.cancel();
    _connecting = null;
  }

  void cancelRingingTimeout() {
    _ringing?.cancel();
    _ringing = null;
  }

  void cancelReconnectTimeout() {
    _reconnect?.cancel();
    _reconnect = null;
  }

  void cancelHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  void cancelAllTimers() {
    cancelAnswerGuard();
    cancelConnectingTimeout();
    cancelRingingTimeout();
    cancelReconnectTimeout();
    cancelHeartbeat();
  }
}
