import 'package:flutter/services.dart';

/// Method channels shared with the native side.
///
/// Two channels, not one: the picture-in-picture channel is bound to the
/// Activity on Android, while the main channel also lives in the background
/// FlutterEngine that FCM spins up. Keeping them apart is what stops the
/// background engine from stealing picture-in-picture callbacks from the UI.
abstract final class CallNativeChannels {
  static const String mainName = 'dev.aibekdv.call_native_kit';
  static const String pipName = 'dev.aibekdv.call_native_kit/pip';

  static const MethodChannel main = MethodChannel(mainName);
  static const MethodChannel pip = MethodChannel(pipName);
}

/// Methods invoked on the native side over [CallNativeChannels.main].
abstract final class CallNativeMethods {
  static const configure = 'configure';
  static const initialize = 'initialize';
  static const savePendingCall = 'savePendingCall';
  static const getPendingAcceptedCall = 'getPendingAcceptedCall';
  static const clearPendingCall = 'clearPendingCall';
  static const markPendingCallAccepted = 'markPendingCallAccepted';
  static const setActiveCall = 'setActiveCall';
  static const shouldSuppressPush = 'shouldSuppressPush';
  static const markPushShown = 'markPushShown';
  static const simulateSystemAccept = 'simulateSystemAccept';
  static const getVoipPushToken = 'getVoipPushToken';
  static const activateAudio = 'activateAudio';
  static const deactivateAudio = 'deactivateAudio';
  static const awaitAudioSessionActive = 'awaitAudioSessionActive';
  static const audioDiagnostics = 'audioDiagnostics';
  static const computeCallUuids = 'computeCallUuids';
}

/// Methods invoked on the native side over [CallNativeChannels.pip].
abstract final class CallPipMethods {
  static const setActiveVideoCall = 'setActiveVideoCall';
  static const enterPip = 'enterPip';
  static const closePip = 'closePip';
  static const isInPip = 'isInPip';
  static const attachTrack = 'attachTrack';
}

/// Callbacks the native side invokes on Dart.
abstract final class CallNativeCallbacks {
  static const onVoipPushToken = 'onVoipPushToken';
  static const onPipModeChanged = 'onPipModeChanged';
  static const onPipAction = 'onPipAction';
  static const onPipAttachmentFailed = 'onPipAttachmentFailed';
}
