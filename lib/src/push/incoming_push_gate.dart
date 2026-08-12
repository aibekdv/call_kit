import '../config/call_native_config.dart';
import '../models/call_push_message.dart';

/// Why an incoming push was, or was not, turned into a ringing phone.
enum PushGateDecision {
  /// Show the system call UI.
  show,

  /// The server's own deadline says nobody is waiting any more.
  stalePayload,

  /// The push spent too long in transit — typical of a device coming back
  /// online and receiving a queued batch at once.
  staleDelivery,

  /// This process already showed this call.
  duplicate,

  /// The user is on another call.
  anotherCallActive,

  /// Another call rang moments ago. Servers routinely send the same call over
  /// two transports, and a batch of queued pushes would otherwise stack
  /// several full-screen call UIs on top of each other.
  burstSuppressed,

  /// The server says the call is no longer ringing.
  notRinging,
}

/// Decides whether an incoming push should ring.
///
/// One implementation for both entry points — the foreground facade and the
/// background isolate — because the two must agree. Every input is injected,
/// so the whole decision table is unit-testable without a device.
class IncomingPushGate {
  IncomingPushGate({
    required CallNativeConfig Function() config,
    this.isAnotherCallActive,
    this.isCallStillRinging,
  }) : _config = config;

  final CallNativeConfig Function() _config;

  /// Asked before ringing. Defaults to the persisted active-call flag, which
  /// is the only thing the background isolate can see.
  final Future<bool> Function()? isAnotherCallActive;

  /// Asked before ringing, so a call the caller already abandoned does not
  /// wake the callee. Skipped when `null`.
  final Future<bool> Function(String callId)? isCallStillRinging;

  final Set<String> _shownCallIds = {};
  static const _maxRememberedIds = 50;

  bool wasShown(String callId) => _shownCallIds.contains(callId);

  Future<PushGateDecision> evaluate(
    IncomingCallPush push, {
    DateTime? sentTime,
    DateTime? now,
  }) async {
    final config = _config();
    final at = (now ?? DateTime.now()).toUtc();

    // Cheapest checks first — a stale push must not cost a network round trip.
    if (push.isStale(timeouts: config.timeouts, now: at)) {
      return PushGateDecision.stalePayload;
    }
    if (sentTime != null &&
        at.difference(sentTime.toUtc()) > config.timeouts.pushStaleThreshold) {
      return PushGateDecision.staleDelivery;
    }
    if (_shownCallIds.contains(push.callId)) {
      return PushGateDecision.duplicate;
    }

    // Deliberately not remembered as "shown": once the current call ends, a
    // fresh push for the same id must still be able to ring.
    if (await _isAnotherCallActive(config)) {
      return PushGateDecision.anotherCallActive;
    }

    if (await _isBurst(config, push.callId, at)) {
      return PushGateDecision.burstSuppressed;
    }

    final stillRinging = isCallStillRinging;
    if (stillRinging != null && !await stillRinging(push.callId)) {
      return PushGateDecision.notRinging;
    }

    return PushGateDecision.show;
  }

  Future<bool> _isAnotherCallActive(CallNativeConfig config) async {
    final probe = isAnotherCallActive;
    if (probe != null) return probe();
    return await config.store.getBool(config.storageKeys.activeCall) ?? false;
  }

  Future<bool> _isBurst(
    CallNativeConfig config,
    String callId,
    DateTime now,
  ) async {
    final keys = config.storageKeys;
    final lastId = await config.store.getString(keys.lastShownCallId);
    final lastAtMs = await config.store.getInt(keys.lastShownCallAt);
    if (lastId == null || lastAtMs == null) return false;

    final since = now.millisecondsSinceEpoch - lastAtMs;
    return since >= 0 &&
        since < config.timeouts.burstSuppressionWindow.inMilliseconds;
  }

  /// Records that the system UI was shown, for both in-process and
  /// cross-isolate de-duplication.
  Future<void> markShown(String callId, {DateTime? now}) async {
    final config = _config();
    _shownCallIds.add(callId);
    if (_shownCallIds.length > _maxRememberedIds) {
      _shownCallIds.remove(_shownCallIds.first);
    }
    final at = (now ?? DateTime.now()).toUtc();
    await config.store.setString(config.storageKeys.lastShownCallId, callId);
    await config.store.setInt(
      config.storageKeys.lastShownCallAt,
      at.millisecondsSinceEpoch,
    );
  }

  void forget(String callId) => _shownCallIds.remove(callId);

  void reset() => _shownCallIds.clear();
}
