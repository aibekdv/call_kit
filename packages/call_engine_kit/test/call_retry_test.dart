import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const retry = CallRetry(
    maxRetries: 3,
    baseDelay: Duration(milliseconds: 500),
  );

  test('returns the first success without waiting', () {
    fakeAsync((async) {
      var attempts = 0;
      Object? result;

      retry
          .call<String>(
            action: () async {
              attempts++;
              return 'ok';
            },
            shouldContinue: () => true,
          )
          .then((value) => result = value);
      async.flushMicrotasks();

      expect(attempts, 1);
      expect(result, 'ok');
    });
  });

  test('retries and eventually succeeds', () {
    fakeAsync((async) {
      var attempts = 0;
      Object? result;

      retry
          .call<String>(
            action: () async {
              attempts++;
              if (attempts < 3) throw Exception('flaky');
              return 'ok';
            },
            shouldContinue: () => true,
          )
          .then((value) => result = value);

      async.elapse(const Duration(seconds: 5));
      expect(attempts, 3);
      expect(result, 'ok');
    });
  });

  test('backs off exponentially', () {
    fakeAsync((async) {
      final delays = <int>[];
      var last = Duration.zero;

      retry
          .call<String>(
            action: () async {
              delays.add((async.elapsed - last).inMilliseconds);
              last = async.elapsed;
              throw Exception('always');
            },
            shouldContinue: () => true,
          )
          .catchError((Object _) => null);

      async.elapse(const Duration(seconds: 10));
      // First attempt is immediate, then 500, 1000, 2000.
      expect(delays, [0, 500, 1000, 2000]);
    });
  });

  test('rethrows once the attempts run out', () {
    fakeAsync((async) {
      Object? thrown;
      var attempts = 0;

      retry
          .call<String>(
        action: () async {
          attempts++;
          throw StateError('always');
        },
        shouldContinue: () => true,
      )
          .catchError((Object e) {
        thrown = e;
        return null;
      });

      async.elapse(const Duration(seconds: 10));
      expect(attempts, 4); // the first try plus three retries
      expect(thrown, isA<StateError>());
    });
  });

  test('gives up when the call is gone', () {
    fakeAsync((async) {
      var attempts = 0;
      var callAlive = true;
      Object? result = 'untouched';

      retry
          .call<String>(
            action: () async {
              attempts++;
              throw Exception('flaky');
            },
            // The user hung up while we were retrying; there is nothing left
            // to retry for.
            shouldContinue: () => callAlive,
          )
          .then((value) => result = value);

      async.elapse(const Duration(milliseconds: 600));
      callAlive = false;
      async.elapse(const Duration(seconds: 10));

      expect(attempts, 2);
      expect(result, isNull);
    });
  });

  test('reports every failed attempt', () {
    fakeAsync((async) {
      final seen = <int>[];

      retry
          .call<String>(
            action: () async => throw Exception('always'),
            shouldContinue: () => true,
            onError: (_, attempt) => seen.add(attempt),
          )
          .catchError((Object _) => null);

      async.elapse(const Duration(seconds: 10));
      expect(seen, [0, 1, 2, 3]);
    });
  });
}
