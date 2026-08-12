import 'package:call_native_kit/call_native_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 12, 9, 0, 30);

  late InMemoryCallStore store;
  late CallNativeConfig config;

  setUp(() {
    store = InMemoryCallStore();
    config = CallNativeConfig(store: store);
  });

  IncomingCallPush push({
    String callId = '314',
    String? createdAt,
    String? timeoutAt,
  }) =>
      const DefaultCallPushMapper().parse({
        'type': 'incoming_call',
        'call_id': callId,
        'call_type': 'audio',
        'caller_name': 'Aibek',
        'created_at': createdAt,
        'timeout_at': timeoutAt,
      })! as IncomingCallPush;

  IncomingPushGate gate({
    Future<bool> Function()? anotherActive,
    Future<bool> Function(String)? stillRinging,
  }) =>
      IncomingPushGate(
        config: () => config,
        isAnotherCallActive: anotherActive,
        isCallStillRinging: stillRinging,
      );

  test('rings a fresh push', () async {
    expect(
      await gate().evaluate(push(), now: now),
      PushGateDecision.show,
    );
  });

  test('drops a push the server already gave up on', () async {
    expect(
      await gate().evaluate(
        push(timeoutAt: '2026-08-12T09:00:00Z'),
        now: now,
      ),
      PushGateDecision.stalePayload,
    );
  });

  test('drops a push that spent too long in transit', () async {
    // The shape of a device coming back online and receiving a queued batch.
    expect(
      await gate().evaluate(
        push(),
        sentTime: now.subtract(const Duration(minutes: 5)),
        now: now,
      ),
      PushGateDecision.staleDelivery,
    );
  });

  test('accepts a push delivered within the threshold', () async {
    expect(
      await gate().evaluate(
        push(),
        sentTime: now.subtract(const Duration(seconds: 10)),
        now: now,
      ),
      PushGateDecision.show,
    );
  });

  test('drops a repeat of a call this process already rang', () async {
    final subject = gate();
    await subject.markShown('314', now: now);
    expect(
      await subject.evaluate(push(), now: now),
      PushGateDecision.duplicate,
    );
  });

  test('does not ring during another call', () async {
    expect(
      await gate(anotherActive: () async => true).evaluate(push(), now: now),
      PushGateDecision.anotherCallActive,
    );
  });

  test('falls back to the persisted active-call flag', () async {
    await store.setBool(config.storageKeys.activeCall, true);
    expect(
      await gate().evaluate(push(), now: now),
      PushGateDecision.anotherCallActive,
    );
  });

  test('an active call is not remembered as shown', () async {
    // Otherwise a legitimate retry after the current call ends is swallowed.
    final subject = gate(anotherActive: () async => true);
    await subject.evaluate(push(), now: now);
    expect(subject.wasShown('314'), isFalse);
  });

  test('suppresses a burst from another transport', () async {
    await gate()
        .markShown('999', now: now.subtract(const Duration(seconds: 1)));
    expect(
      await gate().evaluate(push(), now: now),
      PushGateDecision.burstSuppressed,
    );
  });

  test('rings again once the burst window has passed', () async {
    await gate()
        .markShown('999', now: now.subtract(const Duration(seconds: 6)));
    expect(await gate().evaluate(push(), now: now), PushGateDecision.show);
  });

  test('drops a call the server says stopped ringing', () async {
    expect(
      await gate(stillRinging: (_) async => false).evaluate(push(), now: now),
      PushGateDecision.notRinging,
    );
  });

  test('checks staleness before asking the server', () async {
    var asked = false;
    await gate(
      stillRinging: (_) async {
        asked = true;
        return true;
      },
    ).evaluate(push(timeoutAt: '2026-08-12T09:00:00Z'), now: now);
    expect(asked, isFalse, reason: 'a stale push must not cost a round trip');
  });

  test('markShown persists the cross-isolate markers', () async {
    await gate().markShown('314', now: now);
    expect(await store.getString(config.storageKeys.lastShownCallId), '314');
    expect(
      await store.getInt(config.storageKeys.lastShownCallAt),
      now.millisecondsSinceEpoch,
    );
  });

  test('forget lets a call ring again in this process', () async {
    final subject = gate();
    await subject.markShown('314', now: now);
    subject.forget('314');
    // Still inside the burst window from our own markShown.
    expect(
      await subject.evaluate(
        push(),
        now: now.add(const Duration(seconds: 6)),
      ),
      PushGateDecision.show,
    );
  });
}
