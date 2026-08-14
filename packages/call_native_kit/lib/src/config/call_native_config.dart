import 'dart:convert';

import '../logging/call_logger.dart';
import '../storage/call_key_value_store.dart';
import 'call_native_branding.dart';
import 'call_native_strings.dart';
import 'call_native_timeouts.dart';
import 'call_push_field_names.dart';
import 'call_storage_keys.dart';

/// Everything the plugin needs to know about your app.
///
/// ## The background-isolate invariant
///
/// An incoming call push may arrive when your app is not running. It is
/// handled either natively (iOS PushKit) or in the FCM background isolate
/// (Android), and neither of those can see anything you set up in `main()`:
/// no dependency injection, no localization, no in-memory singletons.
///
/// So anything the background or native path needs must live in one of two
/// places — `Info.plist` / `<meta-data>`, or the store, written by
/// [CallNativeKit.configure]. That is why this class is serializable and why
/// [CallNativeKit.configure] persists it. Call `configure` again whenever the
/// locale changes, otherwise a call arriving while the app is dead shows the
/// previous language.
class CallNativeConfig {
  const CallNativeConfig({
    this.strings = const CallNativeStrings.english(),
    this.branding = const CallNativeBranding(),
    this.timeouts = const CallNativeTimeouts(),
    this.storageKeys = const CallStorageKeys(),
    this.pushFields = const CallPushFieldNames(),
    this.logger = const SilentCallLogger(),
    this.store = const SharedPreferencesCallStore(),
  });

  final CallNativeStrings strings;
  final CallNativeBranding branding;
  final CallNativeTimeouts timeouts;
  final CallStorageKeys storageKeys;
  final CallPushFieldNames pushFields;

  /// Not persisted — rehydrated configs fall back to [SilentCallLogger].
  final CallLogger logger;

  /// Not persisted — rehydrated configs fall back to
  /// [SharedPreferencesCallStore].
  final CallKeyValueStore store;

  CallNativeConfig copyWith({
    CallNativeStrings? strings,
    CallNativeBranding? branding,
    CallNativeTimeouts? timeouts,
    CallStorageKeys? storageKeys,
    CallPushFieldNames? pushFields,
    CallLogger? logger,
    CallKeyValueStore? store,
  }) =>
      CallNativeConfig(
        strings: strings ?? this.strings,
        branding: branding ?? this.branding,
        timeouts: timeouts ?? this.timeouts,
        storageKeys: storageKeys ?? this.storageKeys,
        pushFields: pushFields ?? this.pushFields,
        logger: logger ?? this.logger,
        store: store ?? this.store,
      );

  Map<String, Object?> toJson() => {
        'strings': strings.toJson(),
        'branding': branding.toJson(),
        'timeouts': timeouts.toJson(),
        'storageKeys': storageKeys.toJson(),
        'pushFields': pushFields.toJson(),
      };

  factory CallNativeConfig.fromJson(
    Map<String, Object?> json, {
    CallLogger logger = const SilentCallLogger(),
    CallKeyValueStore store = const SharedPreferencesCallStore(),
  }) {
    Map<String, Object?> section(String key) {
      final raw = json[key];
      return raw is Map ? raw.cast<String, Object?>() : const {};
    }

    return CallNativeConfig(
      strings: CallNativeStrings.fromJson(section('strings')),
      branding: CallNativeBranding.fromJson(section('branding')),
      timeouts: CallNativeTimeouts.fromJson(section('timeouts')),
      storageKeys: CallStorageKeys.fromJson(section('storageKeys')),
      pushFields: CallPushFieldNames.fromJson(section('pushFields')),
      logger: logger,
      store: store,
    );
  }

  String encode() => jsonEncode(toJson());

  /// Restores a config persisted by [CallNativeKit.configure].
  ///
  /// Returns `null` when nothing was persisted — which is the normal state on
  /// the very first push after install, before the app has ever run.
  static Future<CallNativeConfig?> restore({
    CallKeyValueStore store = const SharedPreferencesCallStore(),
    CallStorageKeys keys = const CallStorageKeys(),
    CallLogger logger = const SilentCallLogger(),
  }) async {
    final raw = await store.getString(keys.persistedConfig);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return CallNativeConfig.fromJson(
        decoded.cast<String, Object?>(),
        logger: logger,
        store: store,
      );
    } catch (e, st) {
      logger.recordError(e, st, reason: 'CallNativeConfig.restore failed');
      return null;
    }
  }
}
