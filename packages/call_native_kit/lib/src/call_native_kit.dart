import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

import 'audio/call_audio_session.dart';
import 'channels.dart';
import 'config/call_native_config.dart';
import 'events/call_native_event.dart';
import 'models/call_handle.dart';
import 'models/call_push_message.dart';
import 'models/pending_call.dart';
import 'pip/pip_controller.dart';
import 'push/incoming_push_gate.dart';
import 'system/call_ui_platform.dart';
import 'system/call_uuid.dart';
import 'system/system_call_ui.dart';

/// Everything the operating system knows about your calls, behind one object.
///
/// ```dart
/// final calls = CallNativeKit.instance;
/// await calls.configure(CallNativeConfig(strings: myStrings));
/// await calls.initialize();
///
/// calls.events.listen((event) {
///   if (event is SystemCallActionReceived &&
///       event.action.kind == SystemCallActionKind.accept) {
///     joinCall(event.action.call!);
///   }
/// });
/// ```
///
/// A singleton because the things it owns are singletons: one CallKit
/// provider, one PushKit registry, one audio session, one
/// picture-in-picture window.
class CallNativeKit {
  CallNativeKit._();

  static final CallNativeKit instance = CallNativeKit._();

  CallNativeConfig _config = const CallNativeConfig();

  /// The active configuration. Defaults are English and unbranded until
  /// [configure] runs.
  CallNativeConfig get config => _config;

  late final SystemCallUi _systemUi = SystemCallUi(config: () => _config);
  late final PipController _pip = PipController(logger: _config.logger);
  late final CallAudioSession _audio = CallAudioSession(
    timeouts: () => _config.timeouts,
    logger: _config.logger,
  );
  late final IncomingPushGate _gate = IncomingPushGate(
    config: () => _config,
    isAnotherCallActive: () async {
      final probe = isAnotherCallActive;
      if (probe != null) return probe();
      return await _config.store.getBool(_config.storageKeys.activeCall) ??
          false;
    },
    isCallStillRinging: (callId) async {
      final probe = isCallStillRinging;
      return probe == null ? true : probe(callId);
    },
  );

  final StreamController<CallNativeEvent> _events =
      StreamController<CallNativeEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subs = [];
  bool _initialized = false;

  /// The system call UI. Use it to show, connect and end calls.
  CallUiPlatform get systemUi => _systemUi;

  /// Picture-in-picture on both platforms.
  PipController get pip => _pip;

  /// The WebRTC audio session. Read its documentation before calling
  /// [CallAudioSession.activate] — getting this wrong produces silent calls.
  CallAudioSession get audio => _audio;

  /// Every system, push and picture-in-picture event, in one stream.
  Stream<CallNativeEvent> get events => _events.stream;

  /// Asked before ringing. Return `true` while the user is already on a call.
  Future<bool> Function()? isAnotherCallActive;

  /// Asked before ringing, so an abandoned call does not wake the callee.
  Future<bool> Function(String callId)? isCallStillRinging;

  /// Whether this process already rang for [callId].
  ///
  /// Useful when a system `incoming` action arrives for a call the app never
  /// verified — for instance a PushKit call shown natively while Dart was
  /// still starting.
  bool wasVerified(String callId) => _gate.wasShown(callId);

  /// Installs [config] and persists it.
  ///
  /// Call it before [initialize], and again whenever the locale changes: a
  /// call that arrives while the app is dead is rendered from whatever was
  /// persisted last.
  Future<void> configure(CallNativeConfig config) async {
    _config = config;
    final encoded = config.encode();
    try {
      await config.store.setString(config.storageKeys.persistedConfig, encoded);
    } catch (e, st) {
      config.logger.recordError(e, st, reason: 'persist config');
    }
    try {
      await CallNativeChannels.main
          .invokeMethod<void>(CallNativeMethods.configure, {'config': encoded});
    } catch (e, st) {
      config.logger.recordError(e, st, reason: 'push config to native');
    }
  }

  /// Starts listening to the system. Safe to call more than once.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    CallNativeChannels.main.setMethodCallHandler(_onNativeCall);
    _pip.start();

    _subs.add(
      _systemUi.actions.listen(
        (action) => _events.add(SystemCallActionReceived(action: action)),
      ),
    );
    _subs.add(
      _pip.modeChanges.listen(
        (isInPip) => _events.add(PipModeChanged(isInPip: isInPip)),
      ),
    );
    _subs.add(
      _pip.actions.listen(
        (action) => _events.add(PipActionReceived(action: action)),
      ),
    );
    _subs.add(_pip.attachmentFailures.listen(_events.add));

    try {
      await CallNativeChannels.main.invokeMethod<void>(
        CallNativeMethods.initialize,
      );
    } catch (e, st) {
      _config.logger.recordError(e, st, reason: 'native initialize');
    }

    assert(() {
      unawaited(_assertCallUuidsAgree());
      return true;
    }());
  }

  /// Checks that Dart and native compute the same call UUIDs.
  ///
  /// They implement the algorithm separately — native has to, because a
  /// PushKit call is reported to CallKit before Dart exists — and a drift
  /// between them is invisible until the app cannot end a call it is in.
  /// Debug builds only.
  Future<void> _assertCallUuidsAgree() async {
    const samples = ['1', 'call_314', 'user-42@example.com'];
    try {
      final native = await CallNativeChannels.main
          .invokeListMethod<String>(CallNativeMethods.computeCallUuids, {
        'callIds': samples,
      });
      if (native == null) return; // Platform does not compute them.
      final ours = samples.map(systemCallUuid).toList();
      if (!const ListEquality<String>().equals(native, ours)) {
        _config.logger.recordError(
          StateError('call UUID drift: dart=$ours native=$native'),
          StackTrace.current,
          reason: 'systemCallUuid and CallUuid.swift disagree',
        );
        assert(false, 'call UUID drift: dart=$ours native=$native');
      }
    } catch (_) {
      // Old plugin build or unsupported platform — nothing to compare.
    }
  }

  Future<Object?> _onNativeCall(MethodCall call) async {
    switch (call.method) {
      case CallNativeCallbacks.onVoipPushToken:
        _events.add(
          VoipPushTokenUpdated(token: call.arguments as String? ?? ''),
        );
      default:
        _config.logger.log('unhandled native call ${call.method}');
    }
    return null;
  }

  /// Handles an incoming call push received while the app is running.
  ///
  /// Rings only when [IncomingPushGate] says so; the decision it made is
  /// returned so callers can log or test it.
  Future<PushGateDecision> handleIncomingPush(
    IncomingCallPush push, {
    DateTime? sentTime,
  }) async {
    final decision = await _gate.evaluate(push, sentTime: sentTime);
    _config.logger.log('incoming push ${push.callId}: ${decision.name}');
    if (decision != PushGateDecision.show) return decision;

    await _gate.markShown(push.callId);
    await _systemUi.showIncoming(push.toHandle());
    _events.add(IncomingCallReceived(push: push, eventId: push.callId));
    return decision;
  }

  /// Handles a cancellation push: stops ringing and tells the app.
  Future<void> handleCancelledPush(CallCancelledPush push) async {
    _config.logger.log('cancelled push ${push.callId}');
    _gate.forget(push.callId);
    await _systemUi.end(push.callId);
    _events.add(CallCancelledRemotely(push: push, eventId: push.callId));
  }

  /// Returns a call the user accepted while the app was not running, and
  /// clears it so it cannot be handled twice.
  ///
  /// Returns `null` when there is none or it has outlived
  /// `CallNativeTimeouts.pendingCallTtl`.
  Future<PendingCall?> takePendingAcceptedCall() async {
    try {
      final raw =
          await CallNativeChannels.main.invokeMapMethod<String, Object?>(
        CallNativeMethods.getPendingAcceptedCall,
      );
      final pending = PendingCall.fromJson(raw);
      if (pending == null) return null;
      if (pending.isExpired(_config.timeouts.pendingCallTtl)) {
        await clearPendingCall();
        return null;
      }
      await clearPendingCall();
      return pending;
    } catch (e, st) {
      _config.logger.recordError(e, st, reason: 'takePendingAcceptedCall');
      return null;
    }
  }

  Future<void> clearPendingCall() async {
    try {
      await CallNativeChannels.main.invokeMethod<void>(
        CallNativeMethods.clearPendingCall,
      );
    } catch (e, st) {
      _config.logger.recordError(e, st, reason: 'clearPendingCall');
    }
  }

  /// Records that a call is connected.
  ///
  /// Read by the background isolate to drop a second incoming push instead of
  /// stacking two full-screen call screens, and reset natively at cold start
  /// so a crash mid-call cannot leave it stuck on.
  Future<void> setActiveCall({required bool active}) async {
    if (_lastActiveCallState == active) return;
    _lastActiveCallState = active;
    try {
      await _config.store.setBool(_config.storageKeys.activeCall, active);
      await CallNativeChannels.main
          .invokeMethod<void>(CallNativeMethods.setActiveCall, {
        'active': active,
      });
    } catch (e, st) {
      _config.logger.recordError(e, st, reason: 'setActiveCall');
    }
  }

  bool? _lastActiveCallState;

  /// The iOS PushKit token, or `null` on Android and before registration.
  Future<String?> voipPushToken() async {
    try {
      return await CallNativeChannels.main.invokeMethod<String>(
        CallNativeMethods.getVoipPushToken,
      );
    } catch (e, st) {
      _config.logger.recordError(e, st, reason: 'voipPushToken');
      return null;
    }
  }

  /// Stores a call so it survives a cold start, before the system rings.
  ///
  /// Fails silently in the FCM background isolate, where plugin channels are
  /// only partly attached — that is expected and harmless: the native push
  /// path writes the same record on iOS, and Android recovers through
  /// [CallUiPlatform.activeCalls].
  Future<void> savePendingCall(CallHandle call) async {
    try {
      await CallNativeChannels.main.invokeMethod<void>(
        CallNativeMethods.savePendingCall,
        call.toJson(),
      );
    } catch (_) {
      // Expected in the background isolate. See doc comment.
    }
  }

  Future<void> dispose() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    CallNativeChannels.main.setMethodCallHandler(null);
    await _systemUi.dispose();
    await _pip.dispose();
    await _events.close();
    _initialized = false;
  }
}
