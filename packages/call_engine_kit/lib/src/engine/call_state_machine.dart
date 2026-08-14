import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import '../domain/entities/call_lifecycle_state.dart';
import '../domain/entities/call_session_state.dart';
import '../domain/entities/call_timing_state.dart';
import '../ports/call_logger.dart';

/// Guards which lifecycle transitions may happen.
///
/// A call has several sources of truth racing each other — the user, the
/// signalling server, the media server and the system call UI can all report
/// an outcome, and not always in order. Without this, a late "connecting" from
/// a slow join can drag a call that already ended back to life.
class CallStateMachine {
  CallStateMachine({
    required ValueNotifier<CallSessionState> session,
    required ValueNotifier<CallTimingState> timing,
    required VoidCallback onCancelAllTimers,
    CallLogger logger = const SilentCallLogger(),
  })  : _session = session,
        _timing = timing,
        _onCancelAllTimers = onCancelAllTimers,
        _logger = logger;

  final ValueNotifier<CallSessionState> _session;
  final ValueNotifier<CallTimingState> _timing;
  final VoidCallback _onCancelAllTimers;
  final CallLogger _logger;

  bool disposed = false;

  /// What may follow what.
  ///
  /// Every state is listed, including the terminal ones with nothing after
  /// them. Ending is handled separately in [permits] — a call can end from
  /// anywhere, at any time, and refusing that would strand it.
  static const Map<CallLifecycleState, Set<CallLifecycleState>> allowed = {
    CallLifecycleState.idle: {
      CallLifecycleState.outgoingRinging,
      CallLifecycleState.incomingRinging,
    },
    CallLifecycleState.outgoingRinging: {CallLifecycleState.connecting},
    CallLifecycleState.incomingRinging: {CallLifecycleState.connecting},
    CallLifecycleState.connecting: {
      CallLifecycleState.inCall,
      CallLifecycleState.reconnecting,
    },
    CallLifecycleState.inCall: {CallLifecycleState.reconnecting},
    CallLifecycleState.reconnecting: {
      CallLifecycleState.inCall,
      CallLifecycleState.connecting,
    },
    // Nothing follows a call that is over. A late "connecting" from a join
    // that finally completed must not drag a hung-up call back to life — the
    // engine starts a fresh call from `idle` instead.
    CallLifecycleState.ended: {},
    CallLifecycleState.failed: {},
  };

  /// Whether [current] may be followed by [next].
  static bool permits(CallLifecycleState current, CallLifecycleState next) =>
      next.isTerminal || (allowed[current]?.contains(next) ?? false);

  /// Moves to [next] if the transition is legal.
  ///
  /// Passing [error] also re-emits when the status is unchanged, so a second
  /// failure with a different message is not swallowed.
  void transition(CallLifecycleState next, {String? error}) {
    if (disposed) return;

    final current = _session.value;
    if (current.status == next && error == null) return;

    if (!permits(current.status, next)) {
      _logger.log('blocked ${current.status.name} -> ${next.name}');
      return;
    }

    if (next.isTerminal) _onCancelAllTimers();

    // Stamped once, on the first arrival in the call: the duration the user
    // sees should count talking, not ringing, and a reconnect must not reset
    // it to zero.
    final startedAt =
        next == CallLifecycleState.inCall && _timing.value.startedAt == null
            ? clock.now()
            : _timing.value.startedAt;

    _session.value = current.copyWith(status: next, error: error);
    _timing.value = _timing.value.copyWith(startedAt: startedAt);

    _logger.log('${current.status.name} -> ${next.name}');
  }

  /// Whether [next] is a step backwards from [current].
  ///
  /// Used to ignore stale updates that arrive out of order — a `connecting`
  /// landing after `inCall` describes a moment that has already passed.
  static bool isBackward(CallLifecycleState current, CallLifecycleState next) =>
      _rank(next) < _rank(current);

  static int _rank(CallLifecycleState state) => switch (state) {
        CallLifecycleState.idle => 0,
        CallLifecycleState.incomingRinging ||
        CallLifecycleState.outgoingRinging =>
          1,
        CallLifecycleState.connecting || CallLifecycleState.reconnecting => 2,
        CallLifecycleState.inCall => 3,
        CallLifecycleState.ended || CallLifecycleState.failed => 4,
      };
}
