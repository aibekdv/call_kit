import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' show Helper;
import 'package:livekit_client/livekit_client.dart';

import '../config/call_engine_strings.dart';
import '../domain/entities/call_lifecycle_state.dart';
import '../domain/entities/call_screen_share_state.dart';
import '../domain/entities/call_session_state.dart';
import '../ports/call_logger.dart';
import '../ports/call_room_service.dart';

/// Starting and stopping screen share.
///
/// The two platforms take very different routes to the same thing, and both
/// have a step that will fail silently if skipped — hence the shape of this
/// class.
class ScreenShareController {
  ScreenShareController({
    required ValueNotifier<CallSessionState> session,
    required ValueNotifier<CallScreenShareState> screenShare,
    required CallRoomService roomService,
    required CallEngineStringsResolver strings,
    VoidCallback? onBlocked,
    CallLogger logger = const SilentCallLogger(),
  })  : _session = session,
        _screenShare = screenShare,
        _roomService = roomService,
        _strings = strings,
        _onBlocked = onBlocked,
        _logger = logger;

  final ValueNotifier<CallSessionState> _session;
  final ValueNotifier<CallScreenShareState> _screenShare;
  final CallRoomService _roomService;
  final CallEngineStringsResolver _strings;
  final VoidCallback? _onBlocked;
  final CallLogger _logger;

  bool _toggling = false;

  Room? get _room => _roomService.room;

  Future<void> toggle() async {
    if (_toggling) return;

    final local = _room?.localParticipant;
    if (local == null) return;
    if (_session.value.status != CallLifecycleState.inCall) return;

    final enable = !_screenShare.value.isLocalSharing;
    if (enable && _screenShare.value.isActive) {
      // Somebody else already has the screen; two shares at once is a layout
      // nobody wants to look at.
      _onBlocked?.call();
      return;
    }

    _toggling = true;
    try {
      await (Platform.isIOS
          ? _toggleIos(local, enable)
          : _toggleAndroid(local, enable));
    } catch (e, st) {
      _logger.recordError(e, st, reason: 'toggle screen share');
    } finally {
      _toggling = false;
    }
  }

  Future<void> _toggleIos(LocalParticipant local, bool enable) async {
    if (enable) {
      // Shows the system broadcast picker. Publication completes later, out of
      // band, so there is nothing to verify here — the room event is what
      // confirms it started.
      await local.setScreenShareEnabled(
        true,
        screenShareCaptureOptions: const ScreenShareCaptureOptions(
          useiOSBroadcastExtension: true,
        ),
      );
    } else {
      // Unpublishing closes the socket, which stops the broadcast extension.
      await local.setScreenShareEnabled(false);
    }
  }

  Future<void> _toggleAndroid(LocalParticipant local, bool enable) async {
    if (enable) {
      // Android 14 wants the MediaProjection consent *before* a foreground
      // service starts, not after.
      if (!await Helper.requestCapturePermission()) return;
      await _startForegroundService();
    }

    await local.setScreenShareEnabled(enable, captureScreenAudio: true);

    // The system dialog can be dismissed, and that comes back as success with
    // nothing actually published.
    if (local.isScreenShareEnabled() != enable) {
      _logger.log('screen share cancelled by the user');
      if (enable) await _stopForegroundService();
      return;
    }

    _applyLocalState(local, enable);
    if (!enable) await _stopForegroundService();
  }

  /// Stops sharing before the room disconnects.
  ///
  /// Order matters: disconnecting first leaves the iOS broadcast extension
  /// running and the Android foreground-service notification stuck in the
  /// shade, both telling the user their screen is still being shared.
  Future<void> cleanup() async {
    if (!_screenShare.value.isLocalSharing && !_screenShare.value.isActive) {
      return;
    }

    final local = _room?.localParticipant;
    if (local != null && local.isScreenShareEnabled()) {
      try {
        // Bounded: teardown must not hang on a dead network.
        await local
            .setScreenShareEnabled(false)
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        _logger.log('stopping screen share failed: $e');
      }
    }

    _screenShare.value = CallScreenShareState.inactive;
    if (Platform.isAndroid) await _stopForegroundService();
  }

  void _applyLocalState(LocalParticipant local, bool enabled) {
    if (enabled) {
      _screenShare.value = _screenShare.value.copyWith(
        isLocalSharing: true,
        isActive: true,
        participantIdentity: local.identity,
      );
      return;
    }

    final next = _room?.remoteParticipants.values
        .where((participant) => participant.isScreenShareEnabled())
        .firstOrNull;
    _screenShare.value = _screenShare.value.copyWith(
      isLocalSharing: false,
      isActive: next != null,
      participantIdentity: next?.identity,
    );
  }

  /// Android keeps capturing only while a visible foreground service says so.
  Future<void> _startForegroundService() async {
    final strings = _strings();
    final initialized = await FlutterBackground.initialize(
      androidConfig: FlutterBackgroundAndroidConfig(
        notificationTitle: strings.screenShareNotificationTitle,
        notificationText: strings.screenShareNotificationText,
        notificationImportance: AndroidNotificationImportance.normal,
      ),
    );
    if (initialized && !FlutterBackground.isBackgroundExecutionEnabled) {
      await FlutterBackground.enableBackgroundExecution();
    }
  }

  Future<void> _stopForegroundService() async {
    try {
      if (FlutterBackground.isBackgroundExecutionEnabled) {
        await FlutterBackground.disableBackgroundExecution();
      }
    } catch (_) {}
  }
}
