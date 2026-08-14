import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ValueNotifier<CallSessionState> session;
  late ValueNotifier<CallTimingState> timing;
  late int timersCancelled;
  late CallStateMachine machine;

  setUp(() {
    session = ValueNotifier(CallSessionState.idle);
    timing = ValueNotifier(CallTimingState.initial);
    timersCancelled = 0;
    machine = CallStateMachine(
      session: session,
      timing: timing,
      onCancelAllTimers: () => timersCancelled++,
    );
  });

  void start(CallLifecycleState status) {
    session.value = CallSessionState(status: status);
  }

  group('permits', () {
    test('allows the normal outgoing path', () {
      expect(
        CallStateMachine.permits(
          CallLifecycleState.idle,
          CallLifecycleState.outgoingRinging,
        ),
        isTrue,
      );
      expect(
        CallStateMachine.permits(
          CallLifecycleState.outgoingRinging,
          CallLifecycleState.connecting,
        ),
        isTrue,
      );
      expect(
        CallStateMachine.permits(
          CallLifecycleState.connecting,
          CallLifecycleState.inCall,
        ),
        isTrue,
      );
    });

    test('allows the normal incoming path', () {
      expect(
        CallStateMachine.permits(
          CallLifecycleState.idle,
          CallLifecycleState.incomingRinging,
        ),
        isTrue,
      );
      expect(
        CallStateMachine.permits(
          CallLifecycleState.incomingRinging,
          CallLifecycleState.connecting,
        ),
        isTrue,
      );
    });

    test('allows reconnecting in both directions', () {
      expect(
        CallStateMachine.permits(
          CallLifecycleState.inCall,
          CallLifecycleState.reconnecting,
        ),
        isTrue,
      );
      expect(
        CallStateMachine.permits(
          CallLifecycleState.reconnecting,
          CallLifecycleState.inCall,
        ),
        isTrue,
      );
      expect(
        CallStateMachine.permits(
          CallLifecycleState.reconnecting,
          CallLifecycleState.connecting,
        ),
        isTrue,
      );
    });

    test('a call may end from anywhere', () {
      for (final from in CallLifecycleState.values) {
        for (final to in [
          CallLifecycleState.ended,
          CallLifecycleState.failed,
        ]) {
          expect(
            CallStateMachine.permits(from, to),
            isTrue,
            reason: '${from.name} -> ${to.name}',
          );
        }
      }
    });

    test('refuses to skip ringing', () {
      expect(
        CallStateMachine.permits(
          CallLifecycleState.idle,
          CallLifecycleState.inCall,
        ),
        isFalse,
      );
    });

    test('refuses to go back to ringing from a connected call', () {
      expect(
        CallStateMachine.permits(
          CallLifecycleState.inCall,
          CallLifecycleState.connecting,
        ),
        isFalse,
      );
      expect(
        CallStateMachine.permits(
          CallLifecycleState.connecting,
          CallLifecycleState.outgoingRinging,
        ),
        isFalse,
      );
    });

    test('a terminal call cannot be revived', () {
      // A late "connecting" from a slow join must not resurrect a call the
      // user already hung up on.
      expect(
        CallStateMachine.permits(
          CallLifecycleState.ended,
          CallLifecycleState.connecting,
        ),
        isFalse,
      );
      expect(
        CallStateMachine.permits(
          CallLifecycleState.failed,
          CallLifecycleState.inCall,
        ),
        isFalse,
      );
    });
  });

  group('transition', () {
    test('applies a legal transition', () {
      machine.transition(CallLifecycleState.outgoingRinging);
      expect(session.value.status, CallLifecycleState.outgoingRinging);
    });

    test('ignores an illegal one', () {
      machine.transition(CallLifecycleState.inCall);
      expect(session.value.status, CallLifecycleState.idle);
    });

    test('ignores a repeat of the current status', () {
      var notified = 0;
      session.addListener(() => notified++);
      machine.transition(CallLifecycleState.idle);
      expect(notified, 0);
    });

    test('re-emits when a repeat carries an error', () {
      start(CallLifecycleState.failed);
      machine.transition(CallLifecycleState.failed, error: 'second reason');
      expect(session.value.error, 'second reason');
    });

    test('cancels every timer on a terminal state', () {
      start(CallLifecycleState.inCall);
      machine.transition(CallLifecycleState.ended);
      expect(timersCancelled, 1);
    });

    test('does not cancel timers on a non-terminal state', () {
      machine.transition(CallLifecycleState.outgoingRinging);
      expect(timersCancelled, 0);
    });

    test('stamps the start time on entering the call', () {
      start(CallLifecycleState.connecting);
      machine.transition(CallLifecycleState.inCall);
      expect(timing.value.startedAt, isNotNull);
    });

    test('a reconnect does not restart the clock', () {
      start(CallLifecycleState.connecting);
      machine.transition(CallLifecycleState.inCall);
      final first = timing.value.startedAt;

      machine.transition(CallLifecycleState.reconnecting);
      machine.transition(CallLifecycleState.inCall);

      expect(timing.value.startedAt, first);
    });

    test('does nothing once disposed', () {
      machine.disposed = true;
      machine.transition(CallLifecycleState.outgoingRinging);
      expect(session.value.status, CallLifecycleState.idle);
    });

    test('keeps the rest of the session intact', () {
      session.value = const CallSessionState(
        status: CallLifecycleState.idle,
        displayName: 'Aibek',
        isVideo: true,
      );
      machine.transition(CallLifecycleState.incomingRinging);
      expect(session.value.displayName, 'Aibek');
      expect(session.value.isVideo, isTrue);
    });
  });

  group('isBackward', () {
    test('a later stage is not backward', () {
      expect(
        CallStateMachine.isBackward(
          CallLifecycleState.connecting,
          CallLifecycleState.inCall,
        ),
        isFalse,
      );
    });

    test('an earlier stage is backward', () {
      expect(
        CallStateMachine.isBackward(
          CallLifecycleState.inCall,
          CallLifecycleState.connecting,
        ),
        isTrue,
      );
    });

    test('connecting and reconnecting rank the same', () {
      expect(
        CallStateMachine.isBackward(
          CallLifecycleState.reconnecting,
          CallLifecycleState.connecting,
        ),
        isFalse,
      );
    });

    test('nothing is backward from a terminal state', () {
      expect(
        CallStateMachine.isBackward(
          CallLifecycleState.idle,
          CallLifecycleState.ended,
        ),
        isFalse,
      );
    });
  });
}
