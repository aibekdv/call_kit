/// Keys the plugin owns in the key-value store.
///
/// Split by platform on purpose:
///
/// * **Android** — call pushes are handled in the Dart background isolate, so
///   these keys are read and written only from Dart. Native Kotlin never
///   touches them.
/// * **iOS** — call pushes never reach Dart (PushKit is native, and the host
///   `AppDelegate` intercepts the FCM variant before Firebase forwards it), so
///   the active-call flag and the burst markers live in `UserDefaults` under
///   `dev.aibekdv.call_native_kit.*` and Dart reaches them over the method
///   channel. Nothing mirrors `shared_preferences`' `flutter.` prefix.
class CallStorageKeys {
  const CallStorageKeys({this.prefix = 'call_native_kit.'});

  /// Namespace for every key below. Change it only if it collides with
  /// something the host app already stores.
  final String prefix;

  /// `true` while a call is connected. Read by the background isolate to drop
  /// a second incoming push instead of stacking two system call screens.
  String get activeCall => '${prefix}activeCall';

  /// Id of the last call whose system UI was shown — burst suppression.
  String get lastShownCallId => '${prefix}lastShownCallId';

  /// When [lastShownCallId] was shown, as epoch milliseconds.
  String get lastShownCallAt => '${prefix}lastShownCallAt';

  /// Serialized `CallNativeConfig`, so the background isolate can rehydrate it.
  String get persistedConfig => '${prefix}config';

  Map<String, Object?> toJson() => {'prefix': prefix};

  factory CallStorageKeys.fromJson(Map<String, Object?> json) =>
      CallStorageKeys(
        prefix: json['prefix'] as String? ?? const CallStorageKeys().prefix,
      );
}
