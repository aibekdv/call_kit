import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two languages this example ships, to show that neither package
/// localizes anything itself.
enum DemoLocale {
  en('English'),
  ru('Русский');

  const DemoLocale(this.label);

  final String label;
}

/// Who the user is on this device, and in what language.
///
/// A call needs two identities, so the example asks for one instead of
/// pretending to know it. Persisted, because the interesting failures happen
/// after the app is killed and restarted.
class AppSession extends ChangeNotifier {
  AppSession._(this._prefs)
      : _identity = _prefs.getString(_identityKey),
        _serverUrl = _prefs.getString(_serverKey) ?? '',
        _locale = DemoLocale.values.firstWhere(
          (value) => value.name == _prefs.getString(_localeKey),
          orElse: () => DemoLocale.en,
        );

  static const _identityKey = 'demo.identity';
  static const _serverKey = 'demo.serverUrl';
  static const _localeKey = 'demo.locale';

  static Future<AppSession> load() async =>
      AppSession._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  String? _identity;
  String _serverUrl;
  DemoLocale _locale;

  /// Null until the user has picked who they are.
  String? get identity => _identity;

  bool get isSignedIn => _identity != null;

  /// Overrides `--dart-define=LIVEKIT_URL`. Handy when the machine running
  /// the dev server changes address, which on a laptop it does.
  String get serverUrl => _serverUrl;

  DemoLocale get locale => _locale;

  String get displayName => _identity == null
      ? ''
      : _identity![0].toUpperCase() + _identity!.substring(1);

  Future<void> signIn(String identity, {String serverUrl = ''}) async {
    _identity = identity;
    _serverUrl = serverUrl;
    await _prefs.setString(_identityKey, identity);
    await _prefs.setString(_serverKey, serverUrl);
    notifyListeners();
  }

  Future<void> signOut() async {
    _identity = null;
    await _prefs.remove(_identityKey);
    notifyListeners();
  }

  Future<void> setLocale(DemoLocale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await _prefs.setString(_localeKey, locale.name);
    notifyListeners();
  }
}
