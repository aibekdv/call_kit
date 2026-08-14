import 'package:call_engine_kit/src/engine/expiring_event_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime.utc(2026, 8, 12, 9);

  test('accepts a key once', () {
    final cache = ExpiringEventCache();
    expect(cache.putIfNew('a', now: start), isTrue);
    expect(cache.putIfNew('a', now: start), isFalse);
  });

  test('keeps different keys apart', () {
    final cache = ExpiringEventCache();
    expect(cache.putIfNew('a', now: start), isTrue);
    expect(cache.putIfNew('b', now: start), isTrue);
  });

  test('forgets a key once it expires', () {
    final cache = ExpiringEventCache(ttl: const Duration(minutes: 5));
    cache.putIfNew('a', now: start);
    expect(
      cache.putIfNew('a', now: start.add(const Duration(minutes: 6))),
      isTrue,
    );
  });

  test('still remembers inside the window', () {
    final cache = ExpiringEventCache(ttl: const Duration(minutes: 5));
    cache.putIfNew('a', now: start);
    expect(
      cache.putIfNew('a', now: start.add(const Duration(minutes: 4))),
      isFalse,
    );
  });

  test('drops the oldest keys past the cap', () {
    // A long call with a chatty server must not grow this without bound.
    final cache = ExpiringEventCache(maxSize: 3);
    for (var i = 0; i < 5; i++) {
      cache.putIfNew('key$i', now: start.add(Duration(seconds: i)));
    }
    expect(cache.putIfNew('key0', now: start.add(const Duration(seconds: 5))),
        isTrue);
    expect(cache.putIfNew('key4', now: start.add(const Duration(seconds: 5))),
        isFalse);
  });

  test('clear forgets everything', () {
    final cache = ExpiringEventCache()..putIfNew('a', now: start);
    cache.clear();
    expect(cache.putIfNew('a', now: start), isTrue);
  });
}
