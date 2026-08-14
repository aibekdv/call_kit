import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:clock/clock.dart';
import 'package:call_engine_kit/overlay.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatCallDuration', () {
    test('shows minutes and seconds', () {
      expect(formatCallDuration(const Duration(seconds: 5)), '00:05');
      expect(formatCallDuration(const Duration(minutes: 12, seconds: 34)),
          '12:34');
    });

    test('adds hours only once there are any', () {
      expect(
        formatCallDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
      expect(formatCallDuration(const Duration(minutes: 59)), '59:00');
    });

    test('never shows a negative duration', () {
      expect(formatCallDuration(const Duration(seconds: -5)), '00:00');
    });
  });

  group('CallDurationTicker', () {
    late ValueNotifier<CallSessionState> session;
    late ValueNotifier<CallTimingState> timing;

    CallDurationTicker build() => CallDurationTicker(
          session: session,
          timing: timing,
          statusLabel: (status) => status.name,
        );

    setUp(() {
      session = ValueNotifier(CallSessionState.idle);
      timing = ValueNotifier(CallTimingState.initial);
    });

    test('shows the status while the call is not connected', () {
      final ticker = build();
      expect(ticker.value, 'idle');

      session.value = const CallSessionState(
        status: CallLifecycleState.outgoingRinging,
      );
      expect(ticker.value, 'outgoingRinging');
      ticker.dispose();
    });

    test('counts once the call connects', () {
      fakeAsync((async) {
        final ticker = build();
        final startedAt = clock.now();

        session.value =
            const CallSessionState(status: CallLifecycleState.inCall);
        timing.value = CallTimingState(startedAt: startedAt);

        async.elapse(const Duration(seconds: 5));
        expect(ticker.value, '00:05');

        async.elapse(const Duration(minutes: 1));
        expect(ticker.value, '01:05');
        ticker.dispose();
      });
    });

    test('goes back to a status when the call ends', () {
      fakeAsync((async) {
        final ticker = build();
        session.value =
            const CallSessionState(status: CallLifecycleState.inCall);
        timing.value = CallTimingState(startedAt: clock.now());
        async.elapse(const Duration(seconds: 3));

        session.value = const CallSessionState(
          status: CallLifecycleState.ended,
        );
        expect(ticker.value, 'ended');

        // And stops ticking, rather than counting a call nobody is on.
        async.elapse(const Duration(seconds: 10));
        expect(ticker.value, 'ended');
        ticker.dispose();
      });
    });

    test('keeps counting through a reconnect', () {
      fakeAsync((async) {
        final ticker = build();
        final startedAt = clock.now();
        session.value =
            const CallSessionState(status: CallLifecycleState.inCall);
        timing.value = CallTimingState(startedAt: startedAt);
        async.elapse(const Duration(seconds: 10));

        session.value = const CallSessionState(
          status: CallLifecycleState.reconnecting,
        );
        expect(ticker.value, 'reconnecting');

        session.value =
            const CallSessionState(status: CallLifecycleState.inCall);
        async.elapse(const Duration(seconds: 1));
        // The clock never restarted — the call is the same call.
        expect(ticker.value, '00:11');
        ticker.dispose();
      });
    });
  });
}
