/// A LiveKit-backed audio and video call engine for Flutter.
///
/// The engine runs a call — state machine, timers, media controls, screen
/// share, picture-in-picture, reconnection — and knows nothing about your
/// backend. Implement [CallSignalingClient], or start from
/// [RestCallSignalingClient] if your API is shaped like the one this was
/// extracted from.
///
/// Native call UI comes from `call_native_kit`, which this package re-exports
/// where it is part of the engine's own surface.
library;

export 'package:call_native_kit/call_native_kit.dart'
    show
        CallHandle,
        CallLogger,
        CallNativeConfig,
        CallNativeKit,
        CallNativeStrings,
        ConsoleCallLogger,
        IncomingCallPush,
        SilentCallLogger;

export 'src/adapters/rest_call_signaling_client.dart'
    show CallHttpTransport, RestCallFieldNames, RestCallSignalingClient;
export 'src/config/call_engine_strings.dart'
    show CallEngineStrings, CallEngineStringsResolver;
export 'src/config/call_timeouts.dart' show CallTimeouts;
export 'src/domain/entities/call_audio_route.dart'
    show CallAudioRoute, CallViewMode;
export 'src/domain/entities/call_chat_message.dart' show CallChatMessage;
export 'src/domain/entities/call_lifecycle_state.dart' show CallLifecycleState;
export 'src/domain/entities/call_media_state.dart' show CallMediaState;
export 'src/domain/entities/call_participants_state.dart'
    show CallParticipantsState;
export 'src/domain/entities/call_screen_share_state.dart'
    show CallScreenShareState;
export 'src/domain/entities/call_session_state.dart' show CallSessionState;
export 'src/domain/entities/call_snapshot.dart' show CallSnapshot;
export 'src/domain/entities/call_timing_state.dart' show CallTimingState;
export 'src/domain/entities/call_view_state.dart' show CallViewState;
export 'src/domain/models/call_connection_info.dart' show CallConnectionInfo;
export 'src/domain/models/call_initiation_request.dart'
    show CallInitiationRequest;
export 'src/domain/models/call_signaling_exception.dart'
    show CallSignalingErrorKind, CallSignalingException;
export 'src/domain/models/call_status_info.dart'
    show CallLiveStatus, CallStatusInfo;
export 'src/engine/call_chat_controller.dart' show CallChatController;
export 'src/engine/call_media_controls.dart' show CallMediaControls;
export 'src/engine/call_retry.dart' show CallRetry;
export 'src/engine/call_room_event_handler.dart' show CallRoomEventHandler;
export 'src/engine/call_snapshot_publisher.dart' show CallSnapshotPublisher;
export 'src/engine/call_state_machine.dart' show CallStateMachine;
export 'src/engine/call_timer_manager.dart' show CallTimerManager;
export 'src/engine/live_kit_room_service.dart'
    show CallRoomOptions, LiveKitRoomService;
export 'src/engine/participants_state_reducer.dart'
    show ParticipantsStateReducer;
export 'src/engine/screen_share_controller.dart' show ScreenShareController;
export 'src/engine/screen_share_event_handler.dart'
    show ScreenShareEventHandler;
export 'src/ports/call_permissions_delegate.dart'
    show
        AlwaysGrantedPermissions,
        CallPermissionsDelegate,
        PermissionHandlerDelegate;
export 'src/ports/call_room_service.dart'
    show CallRoomEvent, CallRoomLifecycle, CallRoomService;
export 'src/ports/call_signaling_client.dart' show CallSignalingClient;
