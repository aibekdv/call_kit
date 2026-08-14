import 'package:call_engine_kit/src/engine/call_server_actions.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_signaling_client.dart';

void main() {
  late FakeSignalingClient signaling;
  late CallServerActions actions;

  setUp(() {
    signaling = FakeSignalingClient();
    actions = CallServerActions(signaling: signaling);
  });

  group('resolveCallId', () {
    test('prefers the server id', () {
      expect(actions.resolveCallId('314', 'call_314', 'room'), '314');
    });

    test('falls back to the room name', () {
      expect(actions.resolveCallId(null, 'call_314', 'room'), 'call_314');
    });

    test('falls back to the session room last', () {
      expect(actions.resolveCallId(null, null, 'room'), 'room');
    });

    test('is null when the call was never registered', () {
      expect(actions.resolveCallId(null, null, null), isNull);
    });
  });

  group('lifecycle requests', () {
    test('reach the signaling client', () async {
      await actions.end('1');
      await actions.decline('2');
      await actions.cancel('3');
      await actions.leave('4');
      await actions.heartbeat('5');

      expect(signaling.calls, [
        'end:1',
        'decline:2',
        'cancel:3',
        'leave:4',
        'heartbeat:5',
      ]);
    });

    test('are skipped without a call id', () async {
      await actions.end(null);
      await actions.decline(null);
      expect(signaling.calls, isEmpty);
    });

    test('swallow failures', () async {
      signaling.failEverything = true;
      // The call is already over locally; a failed request must not surface as
      // an exception and leave the user stuck on a dead call screen.
      await expectLater(actions.end('1'), completes);
      await expectLater(actions.heartbeat('1'), completes);
    });
  });
}
