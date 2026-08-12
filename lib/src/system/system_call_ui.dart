import 'dart:async';
import 'dart:io';

import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../channels.dart';
import '../config/call_native_config.dart';
import '../events/call_native_event.dart';
import '../models/call_handle.dart';
import 'call_ui_platform.dart';
import 'call_uuid.dart';
import 'system_call_params.dart';

/// The real system call UI, on top of `flutter_callkit_incoming`.
///
/// Wrapping it is the point: nothing above this class imports
/// `flutter_callkit_incoming`, so it can be swapped for a hand-written
/// `ConnectionService` later without touching a single caller.
class SystemCallUi implements CallUiPlatform {
  SystemCallUi({required CallNativeConfig Function() config})
      : _config = config;

  final CallNativeConfig Function() _config;

  final Set<String> _recentProgrammaticEnds = {};
  StreamSubscription<CallEvent?>? _eventSub;
  final StreamController<SystemCallAction> _actions =
      StreamController<SystemCallAction>.broadcast();

  /// Android only: whether the notification permission has already been
  /// requested this process. Asking on every incoming call is noise.
  bool _permissionsRequested = false;

  @override
  Stream<SystemCallAction> get actions {
    _ensureListening();
    return _actions.stream;
  }

  void _ensureListening() {
    _eventSub ??= FlutterCallkitIncoming.onEvent.listen(
      _onSystemEvent,
      onError: (Object e, StackTrace st) =>
          _config().logger.recordError(e, st, reason: 'system call UI stream'),
    );
  }

  void _onSystemEvent(CallEvent? event) {
    if (event == null) return;
    final action = _toAction(event);
    if (action == null) return;
    _config()
        .logger
        .log('system action ${action.kind.name} ${action.systemUuid}');
    _actions.add(action);
  }

  SystemCallAction? _toAction(CallEvent event) => switch (event) {
        CallEventActionCallIncoming(:final callKitParams) => _fromParams(
            SystemCallActionKind.incoming,
            callKitParams,
          ),
        CallEventActionCallStart(:final callKitParams) => _fromParams(
            SystemCallActionKind.start,
            callKitParams,
          ),
        CallEventActionCallAccept(:final callKitParams) => _fromParams(
            SystemCallActionKind.accept,
            callKitParams,
          ),
        CallEventActionCallDecline(:final callKitParams) => _fromParams(
            SystemCallActionKind.decline,
            callKitParams,
          ),
        CallEventActionCallEnded(:final callKitParams) => _fromParams(
            SystemCallActionKind.ended,
            callKitParams,
          ),
        CallEventActionCallTimeout(:final id) => SystemCallAction(
            kind: SystemCallActionKind.timeout,
            systemUuid: id,
          ),
        CallEventActionCallCallback(:final id) => SystemCallAction(
            kind: SystemCallActionKind.callback,
            systemUuid: id,
          ),
        CallEventActionCallToggleMute(:final id, :final isMuted) =>
          SystemCallAction(
            kind: SystemCallActionKind.toggleMute,
            systemUuid: id,
            isMuted: isMuted,
          ),
        CallEventActionCallToggleHold(:final id, :final isOnHold) =>
          SystemCallAction(
            kind: SystemCallActionKind.toggleHold,
            systemUuid: id,
            isOnHold: isOnHold,
          ),
        CallEventActionCallToggleAudioSession(:final isActive) =>
          SystemCallAction(
            kind: SystemCallActionKind.toggleAudioSession,
            isAudioSessionActive: isActive,
          ),
        _ => null,
      };

  SystemCallAction _fromParams(
          SystemCallActionKind kind, CallKitParams params) =>
      SystemCallAction(
        kind: kind,
        systemUuid: params.id,
        call: CallHandle.fromSystemExtra(params.extra),
      );

  @override
  Future<void> showIncoming(CallHandle call) async {
    final config = _config();
    config.logger.log('showIncoming ${call.callId}');

    if (Platform.isAndroid && !_permissionsRequested) {
      _permissionsRequested = true;
      await _requestAndroidPermissions(config);
    }

    await FlutterCallkitIncoming.showCallkitIncoming(
      buildSystemCallParams(call, config),
    );
  }

  Future<void> _requestAndroidPermissions(CallNativeConfig config) async {
    try {
      await FlutterCallkitIncoming.requestNotificationPermission({
        'title': config.strings.notificationPermissionTitle,
        'rationaleMessagePermission':
            config.strings.notificationPermissionRationale,
        'postNotificationMessageRequired':
            config.strings.notificationPermissionSettings,
      });
      await FlutterCallkitIncoming.requestFullIntentPermission();
    } catch (e, st) {
      config.logger.recordError(e, st, reason: 'android call permissions');
    }
  }

  @override
  Future<void> startOutgoing(CallHandle call) async {
    final config = _config();
    config.logger.log('startOutgoing ${call.callId}');
    try {
      await FlutterCallkitIncoming.startCall(
        buildSystemCallParams(call, config),
      );
    } catch (e, st) {
      config.logger.recordError(e, st, reason: 'startOutgoing');
    }
  }

  @override
  Future<void> setConnected(String callId) async {
    final uuid = systemCallUuid(callId);
    try {
      await FlutterCallkitIncoming.setCallConnected(uuid);
    } catch (e, st) {
      _config().logger.recordError(e, st, reason: 'setConnected');
    }
  }

  @override
  Future<void> transitionToOngoing(CallHandle call) async {
    final config = _config();
    if (!Platform.isAndroid) {
      await setConnected(call.callId);
      return;
    }

    // Android: setCallConnected neither dismisses the incoming notification
    // nor starts the ongoing foreground service. The only way in is to make
    // the plugin believe the user pressed Accept.
    final result = await simulateSystemAccept(call.callId);
    if (result == SimulateAcceptResult.ok) return;

    config.logger.log(
      'transitionToOngoing fell back to setConnected: ${result.name}',
    );
    await setConnected(call.callId);
  }

  /// Makes Android's system call UI behave as if the user pressed Accept.
  ///
  /// See [SimulateAcceptResult] for why this exists and how it can break.
  Future<SimulateAcceptResult> simulateSystemAccept(String callId) async {
    if (!Platform.isAndroid) return SimulateAcceptResult.notAndroid;
    try {
      final raw = await CallNativeChannels.main
          .invokeMethod<String>(CallNativeMethods.simulateSystemAccept, {
        'callId': callId,
      });
      return SimulateAcceptResult.values.firstWhere(
        (value) => value.name == raw,
        orElse: () => SimulateAcceptResult.broadcastFailed,
      );
    } catch (e, st) {
      _config().logger.recordError(e, st, reason: 'simulateSystemAccept');
      return SimulateAcceptResult.broadcastFailed;
    }
  }

  @override
  Future<void> end(String callId) async {
    final uuid = systemCallUuid(callId);
    _markProgrammaticEnd(uuid);
    try {
      await FlutterCallkitIncoming.endCall(uuid);
    } catch (e, st) {
      _config().logger.recordError(e, st, reason: 'end');
    }
  }

  @override
  Future<void> endAll() async {
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e, st) {
      _config().logger.recordError(e, st, reason: 'endAll');
    }
  }

  void _markProgrammaticEnd(String uuid) {
    _recentProgrammaticEnds.add(uuid);
    Future<void>.delayed(
      _config().timeouts.programmaticEndWindow,
      () => _recentProgrammaticEnds.remove(uuid),
    );
  }

  @override
  bool wasRecentlyEndedProgrammatically(String systemCallUuid) =>
      _recentProgrammaticEnds.contains(systemCallUuid);

  @override
  Future<List<CallHandle>> activeCalls() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      return calls
          .map((params) => CallHandle.fromSystemExtra(params.extra))
          .whereType<CallHandle>()
          .toList(growable: false);
    } catch (e, st) {
      _config().logger.recordError(e, st, reason: 'activeCalls');
      return const [];
    }
  }

  Future<void> dispose() async {
    await _eventSub?.cancel();
    _eventSub = null;
    await _actions.close();
  }
}
