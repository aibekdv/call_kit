import 'dart:io' show Platform;

import 'package:call_native_kit/call_native_kit.dart' show CallNativeKit;
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import '../config/call_engine_strings.dart';
import '../domain/entities/call_audio_route.dart';
import '../domain/entities/call_media_state.dart';
import '../domain/entities/call_screen_share_state.dart';
import '../domain/entities/call_session_state.dart';
import '../domain/entities/call_view_state.dart';
import '../ports/call_logger.dart';
import '../ports/call_permissions_delegate.dart';
import '../ports/call_room_service.dart';
import 'screen_share_controller.dart';

/// Microphone, camera and audio routing.
class CallMediaControls {
  CallMediaControls({
    required ValueNotifier<CallSessionState> session,
    required ValueNotifier<CallMediaState> media,
    required ValueNotifier<CallScreenShareState> screenShare,
    required ValueNotifier<CallViewState> view,
    required CallRoomService roomService,
    required CallPermissionsDelegate permissions,
    required CallEngineStringsResolver strings,
    CallNativeKit? native,
    VoidCallback? onScreenShareBlocked,
    CallLogger logger = const SilentCallLogger(),
  })  : _session = session,
        _media = media,
        _view = view,
        _roomService = roomService,
        _permissions = permissions,
        _strings = strings,
        _native = native ?? CallNativeKit.instance,
        _logger = logger,
        _screenShare = ScreenShareController(
          session: session,
          screenShare: screenShare,
          roomService: roomService,
          strings: strings,
          onBlocked: onScreenShareBlocked,
          logger: logger,
        );

  final ValueNotifier<CallSessionState> _session;
  final ValueNotifier<CallMediaState> _media;
  final ValueNotifier<CallViewState> _view;
  final CallRoomService _roomService;
  final CallPermissionsDelegate _permissions;
  final CallEngineStringsResolver _strings;
  final CallNativeKit _native;
  final CallLogger _logger;
  final ScreenShareController _screenShare;

  CameraPosition _cameraPosition = CameraPosition.front;

  /// Guards against a double tap producing two opposite toggles in flight.
  bool _togglingMute = false;
  bool _togglingVideo = false;

  Room? get _room => _roomService.room;
  LocalParticipant? get _local => _room?.localParticipant;

  /// Asks for what the call needs, and records a refusal in the session so the
  /// UI can offer a way into Settings instead of failing silently.
  Future<bool> requestPermissions({required bool isVideo}) async {
    final strings = _strings();
    try {
      if (!await _permissions.ensureMicrophone()) {
        return _denied(strings.microphoneAccessRequired);
      }
      if (isVideo && !await _permissions.ensureCamera()) {
        return _denied(strings.cameraAccessRequired);
      }
    } catch (e, st) {
      _logger.recordError(e, st, reason: 'request call permissions');
      return _denied(strings.permissionRequestFailed);
    }

    if (_session.value.permissionDenied) {
      _session.value = _session.value.copyWith(
        permissionDenied: false,
        error: null,
      );
    }
    return true;
  }

  bool _denied(String message) {
    _session.value = _session.value.copyWith(
      permissionDenied: true,
      error: message,
    );
    return false;
  }

  Future<void> toggleMute() async {
    if (_togglingMute) return;
    final local = _local;
    if (local == null) return;

    _togglingMute = true;
    final muted = !_media.value.isMuted;
    try {
      await local.setMicrophoneEnabled(!muted);
      _media.value = _media.value.copyWith(isMuted: muted);
    } catch (e) {
      _logger.log('toggleMute failed: $e');
      // Trust the track, not our intention — otherwise the button shows a
      // state the microphone is not in.
      _media.value = _media.value.copyWith(
        isMuted: local.audioTrackPublications.every(
          (publication) => publication.muted,
        ),
      );
    } finally {
      _togglingMute = false;
    }
  }

  Future<void> toggleVideo() async {
    if (_togglingVideo) return;
    final local = _local;
    if (local == null) return;

    _togglingVideo = true;
    final enabled = !_media.value.isLocalVideoEnabled;
    try {
      await local.setCameraEnabled(enabled);
      _media.value = _media.value.copyWith(isLocalVideoEnabled: enabled);
    } catch (e) {
      _logger.log('toggleVideo failed: $e');
      _media.value = _media.value.copyWith(
        isLocalVideoEnabled: local.videoTrackPublications.any(
          (publication) =>
              !publication.muted &&
              !publication.isScreenShare &&
              publication.track != null,
        ),
      );
    } finally {
      _togglingVideo = false;
    }
  }

  Future<void> toggleScreenShare() => _screenShare.toggle();

  Future<void> cleanupScreenShare() => _screenShare.cleanup();

  Future<void> switchCamera() async {
    final track = _local?.videoTrackPublications
        .where(
          (publication) => !publication.muted && publication.track != null,
        )
        .firstOrNull
        ?.track;
    if (track == null) return;

    _cameraPosition = _cameraPosition.switched();
    try {
      await track.setCameraPosition(_cameraPosition);
    } catch (e) {
      _logger.log('switchCamera failed: $e');
    }
  }

  /// Chooses where call audio comes out.
  ///
  /// The platform decides the rest: with the speaker not preferred, iOS and
  /// Android route to a connected Bluetooth headset if there is one and to the
  /// earpiece otherwise. So [CallAudioRoute.bluetooth] and
  /// [CallAudioRoute.earpiece] ask for the same thing — the distinction is
  /// what the UI shows, not a device the app picks.
  Future<void> setAudioRoute(CallAudioRoute route) async {
    try {
      await AudioManager.instance.setSpeakerOutputPreferred(
        route == CallAudioRoute.speaker,
      );
      _media.value = _media.value.copyWith(audioRoute: route);
    } catch (e) {
      _logger.log('setAudioRoute failed: $e');
    }
  }

  Future<void> cycleAudioRoute() => setAudioRoute(
        switch (_media.value.audioRoute) {
          CallAudioRoute.earpiece => CallAudioRoute.speaker,
          CallAudioRoute.speaker => CallAudioRoute.bluetooth,
          CallAudioRoute.bluetooth => CallAudioRoute.earpiece,
        },
      );

  /// Brings up audio for a call that is about to start.
  ///
  /// The branch is the whole point. On iOS, CallKit owns `AVAudioSession` for
  /// a call it presented and activates it itself; activating again from here
  /// makes the two fight and the call ends up silent while everything else
  /// reports healthy. So for a CallKit-accepted call we wait, and only
  /// otherwise activate.
  Future<void> initAudioForCall({
    required bool isVideo,
    bool acceptedViaSystemUi = false,
  }) async {
    if (Platform.isIOS && acceptedViaSystemUi) {
      // A false here means the delegate chain is broken; CallAudioSession
      // reports it, and the call proceeds rather than stalling.
      await _native.audio.awaitActive();
    } else {
      await _native.audio.activate(defaultToSpeaker: true);
    }
    await setAudioRoute(CallAudioRoute.speaker);
  }

  void toggleViewMode() {
    _view.value = _view.value.copyWith(
      viewMode: _view.value.viewMode == CallViewMode.grid
          ? CallViewMode.speaker
          : CallViewMode.grid,
    );
  }

  void resetCameraPosition() => _cameraPosition = CameraPosition.front;
}
