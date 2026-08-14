import 'package:call_native_kit/call_native_kit.dart';
import 'package:flutter_test/flutter_test.dart';

/// The cross-language contract for cold-start recovery.
///
/// A call accepted on the lock screen while the app was dead is written by
/// native code — `PendingCallStore.save` in Kotlin, `CallStore.savePendingCall`
/// in Swift — and read back here. Nothing checks that the two sides agree
/// except this test and a human, and the failure is the worst kind: the user
/// taps Accept, the app launches, and nothing happens.
///
/// The payloads below are the exact shapes those two functions write. Change
/// one and this test should be what tells you.
void main() {
  /// What `PendingCallStore.save` writes on Android: `CallHandle.toJson`
  /// plus `savedAt` and `isAccepted`.
  Map<String, Object?> androidPayload({bool isAccepted = true}) => {
        'callId': '314',
        'roomName': 'call_314',
        'displayName': 'Aibek',
        'isVideo': true,
        'isGroup': false,
        'savedAt': DateTime.utc(2026, 8, 12, 9).millisecondsSinceEpoch,
        'isAccepted': isAccepted,
      };

  /// What `CallStore.savePendingCall` writes on iOS: the same, plus the
  /// CallKit `uuid` it also keeps for its own use.
  Map<String, Object?> iosPayload() => {
        ...androidPayload(),
        'avatarUrl': 'https://example.com/a.png',
        'uuid': '70a24e9e-788b-54e1-bea4-aa4f004f7bbc',
      };

  test('reads what Android writes', () {
    final pending = PendingCall.fromJson(androidPayload())!;
    expect(pending.call.callId, '314');
    expect(pending.call.roomName, 'call_314');
    expect(pending.call.displayName, 'Aibek');
    expect(pending.call.isVideo, isTrue);
    expect(pending.isAccepted, isTrue);
    expect(pending.savedAt, DateTime.utc(2026, 8, 12, 9));
  });

  test('reads what iOS writes, extra keys and all', () {
    final pending = PendingCall.fromJson(iosPayload())!;
    expect(pending.call.callId, '314');
    expect(pending.call.avatarUrl, 'https://example.com/a.png');
    expect(pending.isAccepted, isTrue);
  });

  test('survives a round trip', () {
    final original = PendingCall.fromJson(androidPayload())!;
    final restored = PendingCall.fromJson(original.toJson())!;
    expect(restored.call.callId, original.call.callId);
    expect(restored.savedAt, original.savedAt);
    expect(restored.isAccepted, original.isAccepted);
  });

  test('is nothing without a call id', () {
    // Native writing a malformed record must not produce a half-built call the
    // engine then tries to join.
    expect(PendingCall.fromJson({'savedAt': 1, 'isAccepted': true}), isNull);
    expect(PendingCall.fromJson(null), isNull);
  });

  test('defaults to not accepted', () {
    final payload = androidPayload()..remove('isAccepted');
    expect(PendingCall.fromJson(payload)!.isAccepted, isFalse);
  });

  group('expiry', () {
    final savedAt = DateTime.utc(2026, 8, 12, 9);
    final pending = PendingCall(
      call: const CallHandle(
        callId: '314',
        roomName: 'call_314',
        displayName: 'Aibek',
        isVideo: true,
      ),
      savedAt: savedAt,
      isAccepted: true,
    );

    test('is fresh inside the window', () {
      expect(
        pending.isExpired(
          const Duration(seconds: 90),
          now: savedAt.add(const Duration(seconds: 60)),
        ),
        isFalse,
      );
    });

    test('is stale past it', () {
      // The engine drops an expired record rather than joining a call that
      // ended while the app was starting.
      expect(
        pending.isExpired(
          const Duration(seconds: 90),
          now: savedAt.add(const Duration(minutes: 5)),
        ),
        isTrue,
      );
    });
  });
}
