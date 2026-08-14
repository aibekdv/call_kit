import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CallSessionState', () {
    test('has an active call while it is going on', () {
      for (final status in [
        CallLifecycleState.outgoingRinging,
        CallLifecycleState.incomingRinging,
        CallLifecycleState.connecting,
        CallLifecycleState.inCall,
        CallLifecycleState.reconnecting,
      ]) {
        expect(
          CallSessionState(status: status).hasActiveCall,
          isTrue,
          reason: status.name,
        );
      }
    });

    test('has none before or after', () {
      for (final status in [
        CallLifecycleState.idle,
        CallLifecycleState.ended,
        CallLifecycleState.failed,
      ]) {
        expect(
          CallSessionState(status: status).hasActiveCall,
          isFalse,
          reason: status.name,
        );
      }
    });

    test('copyWith leaves untouched fields alone', () {
      const original = CallSessionState(
        status: CallLifecycleState.inCall,
        callId: '314',
        displayName: 'Aibek',
        error: 'previous',
      );
      final updated =
          original.copyWith(status: CallLifecycleState.reconnecting);

      expect(updated.callId, '314');
      expect(updated.displayName, 'Aibek');
      expect(updated.error, 'previous');
    });

    test('copyWith can clear a nullable field', () {
      // The whole reason for the sentinel: null has to mean "clear this",
      // not "leave it".
      const original = CallSessionState(
        status: CallLifecycleState.failed,
        error: 'no answer',
      );
      expect(original.copyWith(error: null).error, isNull);
    });

    test('compares by value', () {
      expect(
        const CallSessionState(status: CallLifecycleState.inCall, callId: '1'),
        const CallSessionState(status: CallLifecycleState.inCall, callId: '1'),
      );
      expect(
        const CallSessionState(status: CallLifecycleState.inCall, callId: '1'),
        isNot(
          const CallSessionState(
            status: CallLifecycleState.inCall,
            callId: '2',
          ),
        ),
      );
    });
  });

  group('CallLifecycleState', () {
    test('knows which states are terminal', () {
      expect(CallLifecycleState.ended.isTerminal, isTrue);
      expect(CallLifecycleState.failed.isTerminal, isTrue);
      expect(CallLifecycleState.inCall.isTerminal, isFalse);
    });

    test('knows which states are ringing', () {
      expect(CallLifecycleState.incomingRinging.isRinging, isTrue);
      expect(CallLifecycleState.outgoingRinging.isRinging, isTrue);
      expect(CallLifecycleState.connecting.isRinging, isFalse);
    });
  });

  group('CallMediaState', () {
    test('reports the speaker from the route', () {
      expect(
        const CallMediaState(audioRoute: CallAudioRoute.speaker).isSpeakerOn,
        isTrue,
      );
      expect(CallMediaState.initial.isSpeakerOn, isFalse);
    });
  });

  group('CallParticipantsState', () {
    test('falls back to the identity when no name is known', () {
      const state = CallParticipantsState(
        identities: ['u1', 'u2'],
        names: {'u1': 'Aibek'},
      );
      expect(state.nameOf('u1'), 'Aibek');
      expect(state.nameOf('u2'), 'u2');
    });

    test('copyWith can clear the active speaker', () {
      const state = CallParticipantsState(activeSpeakerIdentity: 'u1');
      expect(state.copyWith(activeSpeakerIdentity: null).activeSpeakerIdentity,
          isNull);
    });
  });

  group('CallTimingState', () {
    test('has no duration before the call connected', () {
      expect(CallTimingState.initial.durationAt(DateTime.utc(2026)), isNull);
    });

    test('measures from the start', () {
      final state = CallTimingState(startedAt: DateTime.utc(2026, 1, 1, 12));
      expect(
        state.durationAt(DateTime.utc(2026, 1, 1, 12, 1, 30)),
        const Duration(minutes: 1, seconds: 30),
      );
    });
  });

  group('CallSnapshot', () {
    test('compares by value across every part', () {
      const a = CallSnapshot();
      const b = CallSnapshot();
      expect(a, b);

      final c = a.copyWith(
        session: const CallSessionState(status: CallLifecycleState.inCall),
      );
      expect(c, isNot(a));
    });

    test('copyWith can clear the room', () {
      const snapshot = CallSnapshot();
      expect(snapshot.copyWith(clearRoom: true).room, isNull);
    });

    test('a media change alone makes a new snapshot', () {
      // Six notifiers feed one snapshot; a change in any of them has to be
      // visible or the stream silently drops updates.
      const base = CallSnapshot();
      final muted = base.copyWith(
        media: const CallMediaState(isMuted: true),
      );
      expect(muted, isNot(base));
    });
  });
}
