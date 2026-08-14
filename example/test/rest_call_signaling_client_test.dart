import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:call_kit_example/signaling/rest_call_signaling_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the client asked the network to do.
class _RecordingTransport {
  _RecordingTransport(this._responses);

  final Map<String, Map<String, Object?>> _responses;
  final List<String> calls = [];
  final List<Map<String, Object?>?> bodies = [];
  final Set<String> failing = {};

  Future<Map<String, Object?>?> call(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    calls.add('$method $path');
    bodies.add(body);
    if (failing.contains(path)) {
      throw CallSignalingException.http(statusCode: 500, message: 'boom');
    }
    return _responses[path];
  }
}

void main() {
  late _RecordingTransport transport;
  late RestCallSignalingClient client;

  setUp(() {
    transport = _RecordingTransport({
      '/calls': {'id': '314', 'livekitRoom': 'call_314'},
      '/calls/314/join': {'token': 'jwt', 'livekitHost': 'wss://sfu.test'},
      '/calls/314/status': {'status': 'RINGING', 'type': 'VIDEO'},
    });
    client = RestCallSignalingClient(transport: transport.call);
  });

  group('initiateCall', () {
    test('creates then joins', () async {
      final info = await client.initiateCall(
        const CallInitiationRequest(participantIds: ['42'], isVideo: true),
      );

      expect(transport.calls, ['POST /calls', 'POST /calls/314/join']);
      expect(info.token, 'jwt');
      expect(info.serverUrl, 'wss://sfu.test');
      expect(info.roomName, 'call_314');
      expect(info.callId, '314');
    });

    test('sends the call type and participants', () async {
      await client.initiateCall(
        const CallInitiationRequest(
          participantIds: ['42', '43'],
          isVideo: false,
          participantNames: {'42': 'Aibek'},
          externalId: 'room-7',
        ),
      );

      expect(transport.bodies.first, {
        'type': 'AUDIO',
        'participantIds': ['42', '43'],
        'participantNames': {'42': 'Aibek'},
        'externalId': 'room-7',
      });
    });

    test('sends the group title only for group calls', () async {
      await client.initiateCall(
        const CallInitiationRequest(
          participantIds: ['42'],
          isVideo: true,
          title: 'Standup',
        ),
      );
      expect(transport.bodies.first!.containsKey('groupTitle'), isFalse);

      transport.calls.clear();
      transport.bodies.clear();

      await client.initiateCall(
        const CallInitiationRequest(
          participantIds: ['42'],
          isVideo: true,
          isGroup: true,
          title: 'Standup',
        ),
      );
      expect(transport.bodies.first!['groupTitle'], 'Standup');
    });

    test('passes metadata through', () async {
      await client.initiateCall(
        const CallInitiationRequest(
          participantIds: ['42'],
          isVideo: true,
          metadata: {'source': 'chat'},
        ),
      );
      expect(transport.bodies.first!['source'], 'chat');
    });

    test('refuses an empty participant list', () async {
      await expectLater(
        client.initiateCall(
          const CallInitiationRequest(participantIds: [], isVideo: true),
        ),
        throwsA(
          isA<CallSignalingException>().having(
            (e) => e.kind,
            'kind',
            CallSignalingErrorKind.createFailed,
          ),
        ),
      );
      expect(transport.calls, isEmpty);
    });

    test('cancels the call if joining fails', () async {
      transport.failing.add('/calls/314/join');

      await expectLater(
        client.initiateCall(
          const CallInitiationRequest(participantIds: ['42'], isVideo: true),
        ),
        throwsA(isA<CallSignalingException>()),
      );

      // Without this the callee's phone rings for a call the caller will never
      // be on the other end of, and they get a missed call from nobody.
      expect(transport.calls.last, 'POST /calls/314/cancel');
    });

    test('reports a malformed create response', () async {
      transport = _RecordingTransport({
        '/calls': {'unexpected': true}
      });
      client = RestCallSignalingClient(transport: transport.call);

      await expectLater(
        client.initiateCall(
          const CallInitiationRequest(participantIds: ['42'], isVideo: true),
        ),
        throwsA(
          isA<CallSignalingException>().having(
            (e) => e.kind,
            'kind',
            CallSignalingErrorKind.createFailed,
          ),
        ),
      );
    });
  });

  group('joinCall', () {
    test('includes the device id when one is provided', () async {
      client = RestCallSignalingClient(
        transport: transport.call,
        deviceIdProvider: () async => 77,
      );
      await client.joinCall(callId: '314', roomName: 'call_314');
      expect(transport.bodies.single, {'deviceId': 77});
    });

    test('omits it otherwise', () async {
      await client.joinCall(callId: '314', roomName: 'call_314');
      expect(transport.bodies.single, isEmpty);
    });

    test('reports a malformed join response', () async {
      transport = _RecordingTransport({
        '/calls/314/join': {'token': 'jwt'}
      });
      client = RestCallSignalingClient(transport: transport.call);

      await expectLater(
        client.joinCall(callId: '314', roomName: 'call_314'),
        throwsA(
          isA<CallSignalingException>().having(
            (e) => e.kind,
            'kind',
            CallSignalingErrorKind.joinFailed,
          ),
        ),
      );
    });
  });

  group('lifecycle calls', () {
    test('hit the expected paths', () async {
      await client.endCall('314');
      await client.declineCall('314');
      await client.cancelCall('314');
      await client.leaveCall('314');
      await client.heartbeat('314');

      expect(transport.calls, [
        'POST /calls/314/end',
        'POST /calls/314/decline',
        'POST /calls/314/cancel',
        'POST /calls/314/leave',
        'POST /calls/314/heartbeat',
      ]);
    });
  });

  group('fetchStatus', () {
    test('maps a ringing call', () async {
      final status = await client.fetchStatus('314');
      expect(status!.status, CallLiveStatus.ringing);
      expect(status.isStillRinging, isTrue);
      expect(status.isVideo, isTrue);
    });

    test('maps an unknown status rather than failing', () async {
      transport = _RecordingTransport({
        '/calls/314/status': {'status': 'SOMETHING_NEW'},
      });
      client = RestCallSignalingClient(transport: transport.call);
      final status = await client.fetchStatus('314');
      expect(status!.status, CallLiveStatus.unknown);
    });

    test('treats a forgotten call as ended', () async {
      client = RestCallSignalingClient(
        transport: (method, path, {body}) async {
          throw CallSignalingException.http(statusCode: 404, message: 'gone');
        },
      );
      // A call the server no longer knows about is a call that stopped
      // ringing, which is an answer rather than a failure.
      final status = await client.fetchStatus('314');
      expect(status!.status, CallLiveStatus.ended);
    });
  });

  test('honours a different base path', () async {
    transport = _RecordingTransport({
      '/api/v2/voice': {'id': '9', 'livekitRoom': 'r9'},
      '/api/v2/voice/9/join': {'token': 't', 'livekitHost': 'wss://x'},
    });
    client = RestCallSignalingClient(
      transport: transport.call,
      basePath: '/api/v2/voice',
    );

    final info = await client.initiateCall(
      const CallInitiationRequest(participantIds: ['1'], isVideo: true),
    );

    expect(info.token, 't');
    expect(transport.calls.first, 'POST /api/v2/voice');
  });

  test('wraps an arbitrary transport failure', () async {
    client = RestCallSignalingClient(
      transport: (method, path, {body}) async =>
          throw StateError('socket closed'),
    );

    await expectLater(
      client.initiateCall(
        const CallInitiationRequest(participantIds: ['42'], isVideo: true),
      ),
      throwsA(isA<CallSignalingException>()),
    );
  });
}
