import 'package:call_native_kit/call_native_kit.dart';

import 'config/call_engine_config.dart';
import 'engine/call_controller.dart';
import 'ports/call_signaling_client.dart';

/// Calls, ready to use.
///
/// ```dart
/// final engine = await CallEngine.create(CallEngineConfig(
///   signaling: MySignaling(),
///   strings: () => const CallEngineStrings.english(),
/// ));
///
/// engine.controller.session.addListener(() {
///   // render the call
/// });
/// ```
///
/// Creating one registers for incoming calls, so do it once, at startup — not
/// per screen.
class CallEngine {
  CallEngine._(this.controller, this._config, this._native);

  /// Builds the engine and starts listening for calls.
  ///
  /// Also recovers a call the user accepted while the app was not running: the
  /// operating system launched the app for exactly that, and the call is
  /// joined before anything else happens.
  static Future<CallEngine> create(
    CallEngineConfig config, {
    CallNativeKit? native,
    CallNativeConfig? nativeConfig,
  }) async {
    final kit = native ?? CallNativeKit.instance;
    if (nativeConfig != null) await kit.configure(nativeConfig);
    await kit.initialize();

    // Answer the questions the push path asks before it rings.
    kit.isCallStillRinging = (callId) async {
      try {
        final status = await config.signaling.fetchStatus(callId);
        // No opinion from the server means no reason to drop the call.
        return status?.isStillRinging ?? true;
      } catch (_) {
        return true;
      }
    };

    final controller = CallController(config, native: kit)..start();
    kit.isAnotherCallActive =
        () async => controller.session.value.hasActiveCall;

    final engine = CallEngine._(controller, config, kit);
    await engine.recoverPendingCall();
    return engine;
  }

  /// The call itself: state to render, and actions to take.
  final CallController controller;

  final CallEngineConfig _config;
  final CallNativeKit _native;

  CallSignalingClient get signaling => _config.signaling;

  /// Joins a call the user accepted while the app was not running.
  ///
  /// Called once by [create]. Call it again when the app returns to the
  /// foreground with no call running — the accept can land while the app is
  /// starting, in which case the first attempt saw nothing.
  Future<bool> recoverPendingCall() async {
    if (controller.session.value.hasActiveCall) return false;

    final pending = await _native.takePendingAcceptedCall();
    if (pending != null) {
      await controller.joinExistingCall(pending.call);
      return true;
    }

    // Nothing stored, but the system may still be showing a call it accepted.
    final active = await _native.systemUi.activeCalls();
    if (active.isEmpty) return false;
    await controller.joinExistingCall(active.first);
    return true;
  }

  /// Handles a call push that arrived while the app is running.
  ///
  /// Returns what the gate decided, so a host can log why a call did or did
  /// not ring.
  Future<PushGateDecision> handleForegroundPush(
    Map<String, Object?> data, {
    DateTime? sentTime,
    CallPushMapper mapper = const DefaultCallPushMapper(),
  }) async {
    final push = mapper.parse(data);
    return switch (push) {
      IncomingCallPush() => _native.handleIncomingPush(
          push,
          sentTime: sentTime,
        ),
      CallCancelledPush() => _native
          .handleCancelledPush(push)
          .then((_) => PushGateDecision.notRinging),
      null => PushGateDecision.notRinging,
    };
  }

  Future<void> dispose() async {
    await controller.dispose();
    _native
      ..isCallStillRinging = null
      ..isAnotherCallActive = null;
  }
}
