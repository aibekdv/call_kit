import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The timers are the part of a call that used to be untestable: every
/// duration was a `const` in the class, so covering them meant waiting forty
/// real seconds. With `CallTimeouts` injected, `fake_async` covers the whole
/// table in milliseconds.
void main() {
  const timeouts = CallTimeouts(
    answerGuard: Duration(seconds: 15),
    connecting: Duration(seconds: 30),
    ringing: Duration(seconds: 40),
    reconnect: Duration(seconds: 45),
    heartbeat: Duration(seconds: 30),
    outgoingCloseDelay: Duration(seconds: 3),
  );

  late ValueNotifier<CallSessionState> session;
  late List<CallLifecycleState> transitions;
  late List<String?> errors;
  late int clears;
  late int endCalls;
  late int heartbeats;
  late CallTimerManager timers;

  CallTimerManager build() => CallTimerManager(
        session: session,
        timeouts: timeouts,
        strings: () => const CallEngineStrings.english(),
        onTransition: (next, {String? error}) {
          transitions.add(next);
          errors.add(error);
          session.value = session.value.copyWith(status: next, error: error);
        },
        onClear: () async => clears++,
        onEndCall: () async => endCalls++,
        onHeartbeat: () async => heartbeats++,
      );

  setUp(() {
    session = ValueNotifier(CallSessionState.idle);
    transitions = [];
    errors = [];
    clears = 0;
    endCalls = 0;
    heartbeats = 0;
    timers = build();
  });

  void status(CallLifecycleState value) {
    session.value = session.value.copyWith(status: value);
  }

  group('answer guard', () {
    test('is raised while an accept is in flight', () {
      fakeAsync((async) {
        timers.startAnswerGuard();
        expect(timers.isAnswering, isTrue);
        async.elapse(const Duration(seconds: 14));
        expect(timers.isAnswering, isTrue);
        async.elapse(const Duration(seconds: 2));
        expect(timers.isAnswering, isFalse);
      });
    });

    test('drops as soon as it is cancelled', () {
      timers.startAnswerGuard();
      timers.cancelAnswerGuard();
      expect(timers.isAnswering, isFalse);
    });
  });

  group('ringing timeout', () {
    test('ends an unanswered incoming call', () {
      fakeAsync((async) {
        status(CallLifecycleState.incomingRinging);
        timers.startRingingTimeout();
        async.elapse(const Duration(seconds: 41));
        expect(transitions, [CallLifecycleState.ended]);
        expect(clears, 1);
      });
    });

    test('holds the caller a moment longer than the callee', () {
      fakeAsync((async) {
        status(CallLifecycleState.outgoingRinging);
        timers.startRingingTimeout();

        async.elapse(const Duration(seconds: 41));
        // The cancellation reaches the callee by push; closing first would
        // look like we were still ringing someone we had given up on.
        expect(transitions, isEmpty);

        async.elapse(const Duration(seconds: 4));
        expect(transitions, [CallLifecycleState.ended]);
      });
    });

    test('does nothing once the call was answered', () {
      fakeAsync((async) {
        status(CallLifecycleState.incomingRinging);
        timers.startRingingTimeout();
        status(CallLifecycleState.inCall);
        async.elapse(const Duration(seconds: 60));
        expect(transitions, isEmpty);
      });
    });

    test('stands down during the caller-side delay if the call connects', () {
      fakeAsync((async) {
        status(CallLifecycleState.outgoingRinging);
        timers.startRingingTimeout();
        async.elapse(const Duration(seconds: 41));
        status(CallLifecycleState.connecting);
        async.elapse(const Duration(seconds: 5));
        expect(transitions, isEmpty);
      });
    });

    test('can be cancelled', () {
      fakeAsync((async) {
        status(CallLifecycleState.incomingRinging);
        timers.startRingingTimeout();
        timers.cancelRingingTimeout();
        async.elapse(const Duration(seconds: 60));
        expect(transitions, isEmpty);
      });
    });
  });

  group('connecting timeout', () {
    test('fails a join that never completes', () {
      fakeAsync((async) {
        status(CallLifecycleState.connecting);
        timers.startConnectingTimeout();
        async.elapse(const Duration(seconds: 31));
        expect(transitions, [CallLifecycleState.failed]);
        expect(errors.single, const CallEngineStrings.english().noAnswer);
        expect(clears, 1);
        expect(endCalls, 0);
      });
    });

    test('tells the server when asked to', () {
      fakeAsync((async) {
        status(CallLifecycleState.connecting);
        timers.startConnectingTimeout(notifyServer: true);
        async.elapse(const Duration(seconds: 31));
        // Otherwise the callee's phone keeps ringing for a call the caller
        // has already abandoned.
        expect(endCalls, 1);
      });
    });

    test('does nothing once connected', () {
      fakeAsync((async) {
        status(CallLifecycleState.connecting);
        timers.startConnectingTimeout();
        status(CallLifecycleState.inCall);
        async.elapse(const Duration(seconds: 60));
        expect(transitions, isEmpty);
      });
    });
  });

  group('reconnect timeout', () {
    test('gives up on a reconnect that never lands', () {
      fakeAsync((async) {
        status(CallLifecycleState.reconnecting);
        timers.startReconnectTimeout();
        async.elapse(const Duration(seconds: 46));
        expect(transitions, [CallLifecycleState.failed]);
        expect(
            errors.single, const CallEngineStrings.english().reconnectFailed);
        expect(endCalls, 1);
        expect(clears, 1);
      });
    });

    test('does nothing if media comes back', () {
      fakeAsync((async) {
        status(CallLifecycleState.reconnecting);
        timers.startReconnectTimeout();
        status(CallLifecycleState.inCall);
        async.elapse(const Duration(seconds: 60));
        expect(transitions, isEmpty);
      });
    });
  });

  group('heartbeat', () {
    test('repeats while the call is up', () {
      fakeAsync((async) {
        status(CallLifecycleState.inCall);
        timers.startHeartbeat();
        async.elapse(const Duration(seconds: 95));
        expect(heartbeats, 3);
      });
    });

    test('stays quiet outside the call', () {
      fakeAsync((async) {
        status(CallLifecycleState.connecting);
        timers.startHeartbeat();
        async.elapse(const Duration(seconds: 95));
        expect(heartbeats, 0);
      });
    });

    test('survives a failure', () {
      fakeAsync((async) {
        var attempts = 0;
        timers = CallTimerManager(
          session: session,
          timeouts: timeouts,
          strings: () => const CallEngineStrings.english(),
          onTransition: (next, {String? error}) {},
          onClear: () async {},
          onEndCall: () async {},
          onHeartbeat: () async {
            attempts++;
            throw Exception('offline');
          },
        );
        status(CallLifecycleState.inCall);
        timers.startHeartbeat();
        async.elapse(const Duration(seconds: 95));
        // A missed ping is not worth ending a working call over.
        expect(attempts, 3);
      });
    });

    test('stops when cancelled', () {
      fakeAsync((async) {
        status(CallLifecycleState.inCall);
        timers.startHeartbeat();
        async.elapse(const Duration(seconds: 31));
        timers.cancelHeartbeat();
        async.elapse(const Duration(seconds: 60));
        expect(heartbeats, 1);
      });
    });
  });

  test('cancelAllTimers silences everything', () {
    fakeAsync((async) {
      status(CallLifecycleState.incomingRinging);
      timers
        ..startAnswerGuard()
        ..startRingingTimeout()
        ..startConnectingTimeout()
        ..startReconnectTimeout()
        ..startHeartbeat();

      timers.cancelAllTimers();
      async.elapse(const Duration(minutes: 5));

      expect(transitions, isEmpty);
      expect(heartbeats, 0);
      expect(timers.isAnswering, isFalse);
    });
  });
}
