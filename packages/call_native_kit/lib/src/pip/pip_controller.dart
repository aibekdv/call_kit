import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../channels.dart';
import '../events/call_native_event.dart';
import '../logging/call_logger.dart';

/// Picture-in-picture, on both platforms, behind one API.
///
/// The two platforms are genuinely different and the difference leaks:
///
/// * **Android** renders your own Flutter tree into the picture-in-picture
///   window. You keep drawing; you just get much less room. Because the
///   window is the app, a mode change can be missed, so [queryIsInPip] exists
///   as a pull model to re-sync — call it when the window metrics change.
/// * **iOS** renders a native `AVPictureInPictureController`, fed one WebRTC
///   video track. Nothing of your Flutter tree is visible, so you must say
///   which track to show via [attachTrack].
class PipController {
  PipController({CallLogger logger = const SilentCallLogger()})
      : _logger = logger;

  final CallLogger _logger;

  final StreamController<bool> _modeChanges =
      StreamController<bool>.broadcast();
  final StreamController<PipAction> _actions =
      StreamController<PipAction>.broadcast();
  final StreamController<PipAttachmentFailed> _failures =
      StreamController<PipAttachmentFailed>.broadcast();

  bool _isInPip = false;

  /// Last known picture-in-picture state.
  bool get isInPip => _isInPip;

  Stream<bool> get modeChanges => _modeChanges.stream;
  Stream<PipAction> get actions => _actions.stream;

  /// Emits when iOS could not attach the requested track — a black window
  /// instead of a silent one.
  Stream<PipAttachmentFailed> get attachmentFailures => _failures.stream;

  bool get _supported => Platform.isAndroid || Platform.isIOS;

  void start() {
    CallNativeChannels.pip.setMethodCallHandler(_onNativeCall);
  }

  Future<Object?> _onNativeCall(MethodCall call) async {
    switch (call.method) {
      case CallNativeCallbacks.onPipModeChanged:
        _setMode(call.arguments as bool? ?? false);
      case CallNativeCallbacks.onPipAction:
        final raw = call.arguments as String?;
        final action = switch (raw) {
          'mute' => PipAction.mute,
          'hangup' => PipAction.hangup,
          _ => null,
        };
        if (action != null) _actions.add(action);
      case CallNativeCallbacks.onPipAttachmentFailed:
        final args = call.arguments;
        final map = args is Map ? args : const {};
        _failures.add(
          PipAttachmentFailed(
            trackId: map['trackId'] as String?,
            reason: map['reason'] as String?,
          ),
        );
      default:
        _logger.log('unhandled pip call ${call.method}');
    }
    return null;
  }

  void _setMode(bool isInPip) {
    _isInPip = isInPip;
    _modeChanges.add(isInPip);
  }

  /// Tells the system a video call is running.
  ///
  /// On Android API 31+ this also arms auto-enter, so the window shrinks when
  /// the user swipes home instead of the call being backgrounded.
  Future<void> setActiveVideoCall({
    required bool active,
    int aspectWidth = 9,
    int aspectHeight = 16,
  }) async {
    if (!_supported) return;
    try {
      await CallNativeChannels.pip
          .invokeMethod<void>(CallPipMethods.setActiveVideoCall, {
        'active': active,
        'aspectWidth': aspectWidth,
        'aspectHeight': aspectHeight,
      });
    } catch (e, st) {
      _logger.recordError(e, st, reason: 'setActiveVideoCall');
    }
  }

  Future<bool> enterPip({int aspectWidth = 9, int aspectHeight = 16}) async {
    if (!_supported) return false;
    try {
      final entered = await CallNativeChannels.pip
              .invokeMethod<bool>(CallPipMethods.enterPip, {
            'aspectWidth': aspectWidth,
            'aspectHeight': aspectHeight,
          }) ??
          false;
      // Android draws the Flutter tree inside the picture-in-picture window,
      // so a missed native callback leaves the full app UI rendered in a
      // thumbnail. Mark the mode immediately rather than waiting for it.
      if (entered && Platform.isAndroid) _setMode(true);
      return entered;
    } catch (e, st) {
      _logger.recordError(e, st, reason: 'enterPip');
      return false;
    }
  }

  /// Asks the Activity for its real state. Android only; `null` elsewhere.
  Future<bool?> queryIsInPip() async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await CallNativeChannels.pip.invokeMethod<bool>(
        CallPipMethods.isInPip,
      );
      if (result != null) _setMode(result);
      return result;
    } catch (e, st) {
      _logger.recordError(e, st, reason: 'queryIsInPip');
      return null;
    }
  }

  /// Chooses which remote video track the iOS window renders.
  ///
  /// Pass `null` to detach. Native never guesses a track on its own: when it
  /// did, it latched onto whatever was published last and happily rendered a
  /// screen share into what the user expected to be a face.
  Future<void> attachTrack({String? trackId}) async {
    if (!Platform.isIOS) return;
    try {
      await CallNativeChannels.pip.invokeMethod<void>(
        CallPipMethods.attachTrack,
        {'trackId': trackId ?? ''},
      );
    } catch (e, st) {
      _logger.recordError(e, st, reason: 'attachTrack');
    }
  }

  Future<void> closePip() async {
    if (!_supported || !_isInPip) return;
    try {
      await CallNativeChannels.pip.invokeMethod<void>(CallPipMethods.closePip);
    } catch (e, st) {
      _logger.recordError(e, st, reason: 'closePip');
    }
  }

  Future<void> dispose() async {
    CallNativeChannels.pip.setMethodCallHandler(null);
    await _modeChanges.close();
    await _actions.close();
    await _failures.close();
  }
}
