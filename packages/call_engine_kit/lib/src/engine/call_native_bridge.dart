import 'package:call_native_kit/call_native_kit.dart' show CallNativeKit;
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' show Room;

import '../domain/entities/call_lifecycle_state.dart';
import '../domain/entities/call_participants_state.dart';
import '../domain/entities/call_session_state.dart';
import '../helpers/remote_video_track_finder.dart';

/// Keeps the operating system in step with the call.
///
/// Two things the platform needs told, both of which are invisible bugs when
/// they drift: whether a call is running at all, and which video track
/// picture-in-picture should render.
class CallNativeBridge {
  CallNativeBridge({
    required this.session,
    required this.participants,
    required Room? Function() roomGetter,
    CallNativeKit? native,
  })  : _roomGetter = roomGetter,
        _native = native ?? CallNativeKit.instance;

  final ValueNotifier<CallSessionState> session;
  final ValueNotifier<CallParticipantsState> participants;
  final Room? Function() _roomGetter;
  final CallNativeKit _native;

  bool _disposed = false;
  bool _lastReportedActive = false;

  void start() => session.addListener(syncActiveCallFlag);

  void dispose() {
    _disposed = true;
    session.removeListener(syncActiveCallFlag);
  }

  /// Reports whether a call is running.
  ///
  /// Push handlers read this to decide whether to ring. Get it wrong in one
  /// direction and a second call stacks another full-screen call screen over
  /// the first; wrong in the other and the phone stops ringing entirely.
  void syncActiveCallFlag() {
    final active = session.value.hasActiveCall;
    if (active == _lastReportedActive) return;
    _lastReportedActive = active;
    _native.setActiveCall(active: active);
  }

  /// Picks the track iOS picture-in-picture renders.
  ///
  /// Passing `null` detaches rather than leaving the previous choice: native
  /// never guesses, and a stale attachment is how a screen share ends up in
  /// the little window.
  void syncPreferredVideoTrack() {
    if (_disposed) return;
    if (!session.value.isVideo) return;
    if (session.value.status != CallLifecycleState.inCall) return;

    final room = _roomGetter();
    if (room == null) return;

    final best = findBestRemoteVideoTrack(
      room,
      preferIdentity: participants.value.activeSpeakerIdentity,
    );
    _native.pip.attachTrack(trackId: best?.mediaStreamTrack.id);
  }

  void setActiveVideoCall({required bool active}) =>
      _native.pip.setActiveVideoCall(active: active);

  Future<bool> enterPip() => _native.pip.enterPip();

  Future<void> closePip() => _native.pip.closePip();

  bool get isInPip => _native.pip.isInPip;
}
