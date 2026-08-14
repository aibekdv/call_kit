/// Native call UI for Flutter.
///
/// CallKit and PushKit on iOS, full-screen incoming calls on Android,
/// picture-in-picture on both, and manual-mode control of the WebRTC audio
/// session — with no opinion about how your calls are signalled or carried.
///
/// Start from [CallNativeKit].
library;

export 'src/audio/call_audio_session.dart'
    show AudioSessionDiagnostics, CallAudioSession;
export 'src/call_native_kit.dart' show CallNativeKit;
export 'src/config/call_native_branding.dart' show CallNativeBranding;
export 'src/config/call_native_config.dart' show CallNativeConfig;
export 'src/config/call_native_strings.dart' show CallNativeStrings;
export 'src/config/call_native_timeouts.dart' show CallNativeTimeouts;
export 'src/config/call_push_field_names.dart' show CallPushFieldNames;
export 'src/config/call_storage_keys.dart' show CallStorageKeys;
export 'src/events/call_native_event.dart'
    show
        CallCancelledRemotely,
        CallNativeEvent,
        IncomingCallReceived,
        PipAction,
        PipActionReceived,
        PipAttachmentFailed,
        PipModeChanged,
        SystemCallAction,
        SystemCallActionKind,
        SystemCallActionReceived,
        VoipPushTokenUpdated;
export 'src/logging/call_logger.dart'
    show CallLogger, ConsoleCallLogger, SilentCallLogger;
export 'src/models/call_handle.dart' show CallHandle;
export 'src/models/call_push_message.dart'
    show CallCancelledPush, CallPushMessage, IncomingCallPush;
export 'src/models/pending_call.dart' show PendingCall;
export 'src/pip/pip_controller.dart' show PipController;
export 'src/push/background_call_push.dart' show handleBackgroundCallPush;
export 'src/push/call_push_mapper.dart'
    show CallPushMapper, DefaultCallPushMapper;
export 'src/push/incoming_push_gate.dart'
    show IncomingPushGate, PushGateDecision;
export 'src/storage/call_key_value_store.dart'
    show CallKeyValueStore, InMemoryCallStore, SharedPreferencesCallStore;
export 'src/system/call_ui_platform.dart'
    show CallUiPlatform, SimulateAcceptResult;
export 'src/system/call_uuid.dart' show systemCallUuid;
export 'src/system/system_call_ui.dart' show SystemCallUi;
