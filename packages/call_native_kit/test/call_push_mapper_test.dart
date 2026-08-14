import 'package:call_native_kit/call_native_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = DefaultCallPushMapper();

  Map<String, Object?> incoming([Map<String, Object?> overrides = const {}]) =>
      {
        'type': 'incoming_call',
        'call_id': '314',
        'call_type': 'video',
        'caller_name': 'Aibek',
        ...overrides,
      };

  group('isCallPush', () {
    test('accepts incoming and both cancellation spellings', () {
      for (final type in [
        'incoming_call',
        'cancelled_call',
        'call_cancelled'
      ]) {
        expect(mapper.isCallPush({'type': type}), isTrue, reason: type);
      }
    });

    test('is case-insensitive', () {
      expect(mapper.isCallPush({'type': 'INCOMING_CALL'}), isTrue);
    });

    test('rejects anything else', () {
      expect(mapper.isCallPush({'type': 'new_message'}), isFalse);
      expect(mapper.isCallPush(const {}), isFalse);
    });
  });

  group('parse', () {
    test('reads an incoming call', () {
      final push = mapper.parse(incoming()) as IncomingCallPush;
      expect(push.callId, '314');
      expect(push.callerName, 'Aibek');
      expect(push.isVideo, isTrue);
      expect(push.isGroup, isFalse);
    });

    test('treats a non-video call type as audio', () {
      final push =
          mapper.parse(incoming({'call_type': 'audio'})) as IncomingCallPush;
      expect(push.isVideo, isFalse);
    });

    test('accepts is_group as a bool and as a string', () {
      // FCM data payloads are string-typed on the wire but bool over a native
      // bridge, so both shapes reach this code in production.
      for (final raw in <Object>[true, 'true', 'TRUE']) {
        final push =
            mapper.parse(incoming({'is_group': raw})) as IncomingCallPush;
        expect(push.isGroup, isTrue, reason: '$raw');
      }
      for (final raw in <Object>[false, 'false', 'yes', 1]) {
        final push =
            mapper.parse(incoming({'is_group': raw})) as IncomingCallPush;
        expect(push.isGroup, isFalse, reason: '$raw');
      }
    });

    test('falls back to the template room name', () {
      final push = mapper.parse(incoming()) as IncomingCallPush;
      expect(push.roomName, 'call_314');
    });

    test('prefers an explicit room name', () {
      final push = mapper.parse(incoming({'livekit_room': 'room-abc'}))
          as IncomingCallPush;
      expect(push.roomName, 'room-abc');
    });

    test('ignores a blank room name', () {
      final push =
          mapper.parse(incoming({'livekit_room': '  '})) as IncomingCallPush;
      expect(push.roomName, 'call_314');
    });

    test('falls back for a missing caller name', () {
      final push =
          mapper.parse(incoming({'caller_name': null})) as IncomingCallPush;
      expect(push.callerName, 'Incoming call');
    });

    test('an explicit fallback name wins over the payload', () {
      final push = mapper.parse(incoming(), fallbackCallerName: 'Override')
          as IncomingCallPush;
      expect(push.callerName, 'Override');
    });

    test('normalizes both cancellation spellings', () {
      for (final type in ['cancelled_call', 'call_cancelled']) {
        final push = mapper.parse({
          'type': type,
          'call_id': '314',
          'reason': 'timeout',
        });
        expect(push, isA<CallCancelledPush>(), reason: type);
        expect((push! as CallCancelledPush).reason, 'timeout');
      }
    });

    test('returns null without a call id', () {
      expect(mapper.parse(incoming({'call_id': null})), isNull);
      expect(mapper.parse(incoming({'call_id': ''})), isNull);
    });

    test('returns null for a non-call push', () {
      expect(mapper.parse({'type': 'new_message', 'call_id': '1'}), isNull);
    });

    test('keeps the raw payload', () {
      final push =
          mapper.parse(incoming({'custom': 'value'})) as IncomingCallPush;
      expect(push.raw['custom'], 'value');
      expect(push.toHandle().extra['custom'], 'value');
    });

    test('parses timestamps as UTC', () {
      final push = mapper.parse(
        incoming({
          'created_at': '2026-08-12T09:00:00+03:00',
          'timeout_at': '2026-08-12T09:00:40+03:00',
        }),
      ) as IncomingCallPush;
      expect(push.createdAt!.isUtc, isTrue);
      expect(push.createdAt!.hour, 6);
      expect(push.timeoutAt!.isUtc, isTrue);
    });

    test('honours custom field names', () {
      const custom = DefaultCallPushMapper(
        fields: CallPushFieldNames(
          type: 'kind',
          callId: 'id',
          incomingTypes: {'ring'},
          roomNameTemplate: 'sfu-{callId}',
        ),
      );
      final push =
          custom.parse({'kind': 'ring', 'id': '7'}) as IncomingCallPush;
      expect(push.callId, '7');
      expect(push.roomName, 'sfu-7');
    });
  });

  group('isStale', () {
    final now = DateTime.utc(2026, 8, 12, 9, 0, 30);

    IncomingCallPush withTimes({String? createdAt, String? timeoutAt}) =>
        mapper.parse(
          incoming({'created_at': createdAt, 'timeout_at': timeoutAt}),
        )! as IncomingCallPush;

    test('timeout_at wins when present', () {
      expect(
        withTimes(timeoutAt: '2026-08-12T09:00:40Z').isStale(now: now),
        isFalse,
      );
      expect(
        withTimes(timeoutAt: '2026-08-12T09:00:20Z').isStale(now: now),
        isTrue,
      );
    });

    test('tolerates clock skew around the deadline', () {
      // Deadline three seconds ago, default skew five — still ringing.
      expect(
        withTimes(timeoutAt: '2026-08-12T09:00:27Z').isStale(now: now),
        isFalse,
      );
    });

    test('falls back to created_at plus the threshold', () {
      expect(
        withTimes(createdAt: '2026-08-12T09:00:00Z').isStale(now: now),
        isFalse,
      );
      expect(
        withTimes(createdAt: '2026-08-12T08:59:00Z').isStale(now: now),
        isTrue,
      );
    });

    test('is never stale without timestamps', () {
      // A server that sends none must not have every call dropped.
      expect(withTimes().isStale(now: now), isFalse);
    });
  });
}
