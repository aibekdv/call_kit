/// Remembers which events have already been handled.
///
/// The same call event can arrive twice — over a push and over the media
/// connection, or simply retried — and acting on it twice ends a call the
/// second time it is reported as ended.
class ExpiringEventCache {
  ExpiringEventCache({
    this.ttl = const Duration(minutes: 5),
    this.maxSize = 100,
  });

  final Duration ttl;
  final int maxSize;

  final Map<String, DateTime> _seen = {};

  /// Records [key] and returns whether it is new.
  bool putIfNew(String key, {DateTime? now}) {
    final at = now ?? DateTime.now();
    _prune(at);
    if (_seen.containsKey(key)) return false;
    _seen[key] = at;
    return true;
  }

  void _prune(DateTime now) {
    _seen.removeWhere((_, seenAt) => now.difference(seenAt) > ttl);
    // A hard cap as well as a TTL: a long call with a chatty server should not
    // grow this without bound.
    if (_seen.length <= maxSize) return;
    final ordered = _seen.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    for (final entry in ordered.take(_seen.length - maxSize)) {
      _seen.remove(entry.key);
    }
  }

  void clear() => _seen.clear();
}
