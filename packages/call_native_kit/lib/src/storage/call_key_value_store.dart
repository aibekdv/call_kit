import 'package:shared_preferences/shared_preferences.dart';

/// The small amount of state the plugin has to survive a process death:
/// the active-call flag, the burst-suppression markers and the persisted
/// config.
///
/// Implement it if your app already owns a storage abstraction. Whatever you
/// use must be readable from the FCM background isolate.
abstract interface class CallKeyValueStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);

  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);

  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);

  Future<void> remove(String key);
}

/// Default implementation on `shared_preferences`.
///
/// Reads with `reload()` because the writer may be another isolate: the FCM
/// background handler and the UI isolate hold separate in-memory caches.
class SharedPreferencesCallStore implements CallKeyValueStore {
  const SharedPreferencesCallStore();

  Future<SharedPreferences> _prefs({bool fresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (fresh) {
      await prefs.reload();
    }
    return prefs;
  }

  @override
  Future<String?> getString(String key) async =>
      (await _prefs(fresh: true)).getString(key);

  @override
  Future<void> setString(String key, String value) async =>
      (await _prefs()).setString(key, value);

  @override
  Future<bool?> getBool(String key) async =>
      (await _prefs(fresh: true)).getBool(key);

  @override
  Future<void> setBool(String key, bool value) async =>
      (await _prefs()).setBool(key, value);

  @override
  Future<int?> getInt(String key) async =>
      (await _prefs(fresh: true)).getInt(key);

  @override
  Future<void> setInt(String key, int value) async =>
      (await _prefs()).setInt(key, value);

  @override
  Future<void> remove(String key) async => (await _prefs()).remove(key);
}

/// In-memory store for tests and for the example app.
class InMemoryCallStore implements CallKeyValueStore {
  final Map<String, Object?> _values = {};

  Map<String, Object?> get values => Map.unmodifiable(_values);

  @override
  Future<String?> getString(String key) async => _values[key] as String?;

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<bool?> getBool(String key) async => _values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;

  @override
  Future<int?> getInt(String key) async => _values[key] as int?;

  @override
  Future<void> setInt(String key, int value) async => _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);
}
