import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the hand-over rules with no room attached, which is a real state:
/// events can still drain after a disconnect, and nothing here may throw when
/// they do.
void main() {
  late ValueNotifier<CallScreenShareState> state;
  late ScreenShareEventHandler handler;

  setUp(() {
    state = ValueNotifier(CallScreenShareState.inactive);
    handler = ScreenShareEventHandler(
      screenShare: state,
      roomGetter: () => null,
    );
  });

  test('a remote share becomes the active one', () {
    handler.onRemoteStarted('u1');
    expect(state.value.isActive, isTrue);
    expect(state.value.participantIdentity, 'u1');
    expect(state.value.isLocalSharing, isFalse);
  });

  test('a second sharer does not steal the screen', () {
    handler.onRemoteStarted('u1');
    handler.onRemoteStarted('u2');
    expect(state.value.participantIdentity, 'u1');
  });

  test('the share clears when the only sharer stops', () {
    handler.onRemoteStarted('u1');
    handler.onRemoteStopped('u1');
    expect(state.value.isActive, isFalse);
    expect(state.value.participantIdentity, isNull);
  });

  test('a local share marks itself as ours', () {
    handler.onLocalPublished();
    expect(state.value.isActive, isTrue);
    expect(state.value.isLocalSharing, isTrue);
  });

  test('stopping a local share clears it', () {
    handler.onLocalPublished();
    handler.onLocalUnpublished();
    expect(state.value.isLocalSharing, isFalse);
    expect(state.value.isActive, isFalse);
  });

  test('survives events arriving after the room is gone', () {
    handler
      ..onRemoteStarted('u1')
      ..onRemoteStopped('u1')
      ..onLocalPublished()
      ..onLocalUnpublished();
    expect(state.value, CallScreenShareState.inactive);
  });
}
