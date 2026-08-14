import 'package:call_ui_kit/call_ui_kit.dart' as ui;
import 'package:flutter/material.dart';

import '../call_engine.dart';
import '../domain/entities/call_lifecycle_state.dart';
import '../domain/entities/call_media_state.dart';
import '../domain/entities/call_session_state.dart';
import '../domain/entities/call_snapshot.dart';
import '../engine/call_controller.dart';
import 'call_duration_ticker.dart';
import 'call_participant_mapper.dart';

/// Puts the call on screen, over whatever the app is showing.
///
/// Mount it once, through `MaterialApp.builder`:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => CallOverlay(
///     engine: engine,
///     theme: const ui.CallTheme(),
///     child: child!,
///   ),
///   // ...
/// )
/// ```
///
/// `builder` rather than wrapping `MaterialApp` itself: this way the overlay
/// sits above every route while still living inside the app's `Directionality`,
/// `Localizations` and `Theme`. Placing it outside means rebuilding all of
/// those by hand, and getting one wrong fails only in release builds.
class CallOverlay extends StatefulWidget {
  const CallOverlay({
    required this.engine,
    required this.child,
    required this.theme,
    this.dimensions = const ui.CallDimensions(),
    this.strings,
    this.localUserName = 'You',
    this.localUserAvatarUrl,
    this.statusLabel,
    this.minimizedBuilder,
    this.onToast,
    super.key,
  });

  final CallEngine engine;
  final Widget child;

  final ui.CallTheme theme;
  final ui.CallDimensions dimensions;
  final ui.CallStrings? strings;

  /// Shown as the local participant's name.
  final String localUserName;
  final String? localUserAvatarUrl;

  /// The line under the caller's name while the call is not yet connected.
  /// Once it connects this is replaced by the running duration.
  final String Function(CallLifecycleState status)? statusLabel;

  /// What to show while the call is minimized.
  ///
  /// Without one, minimizing simply hides the call — the app is expected to
  /// offer its own way back. Return something tappable that calls
  /// `controller.setOverlayExpanded(expanded: true)`.
  final Widget Function(BuildContext context, CallSnapshot snapshot)?
      minimizedBuilder;

  /// Called for messages meant to be shown once — a screen share refused
  /// because somebody else is already sharing, a call that could not start.
  final void Function(String message)? onToast;

  @override
  State<CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends State<CallOverlay> with WidgetsBindingObserver {
  late final CallParticipantMapper _mapper = CallParticipantMapper();
  late final CallDurationTicker _status = CallDurationTicker(
    session: _controller.session,
    timing: _controller.timing,
    statusLabel: widget.statusLabel ?? _defaultStatusLabel,
  );

  CallController get _controller => widget.engine.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.toastError.addListener(_onToast);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.toastError.removeListener(_onToast);
    _status.dispose();
    _mapper.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Entering or leaving picture-in-picture always changes the window
    // metrics, and on Android the mode-change callback can be missed. This is
    // the reliable cue to re-ask.
    _controller.syncPipMode();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // An accept can land while the app is starting, before anything was
      // listening. Ask again now that it is.
      widget.engine.recoverPendingCall();
      return;
    }
    if (state == AppLifecycleState.paused) {
      final session = _controller.session.value;
      if (session.status == CallLifecycleState.inCall && session.isVideo) {
        _controller.enterPip();
      }
    }
  }

  void _onToast() {
    final message = _controller.toastError.value;
    if (message == null) return;
    _controller.toastError.value = null;
    final handler = widget.onToast;
    if (handler != null) {
      handler(message);
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  String _defaultStatusLabel(CallLifecycleState status) => switch (status) {
        CallLifecycleState.outgoingRinging => 'Calling…',
        CallLifecycleState.incomingRinging => 'Incoming call',
        CallLifecycleState.connecting => 'Connecting…',
        CallLifecycleState.reconnecting => 'Reconnecting…',
        CallLifecycleState.ended || CallLifecycleState.failed => 'Call ended',
        _ => '',
      };

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          widget.child,
          ValueListenableBuilder<CallSessionState>(
            valueListenable: _controller.session,
            builder: (context, session, _) {
              if (!session.hasActiveCall) return const SizedBox.shrink();
              if (!_controller.view.value.isOverlayExpanded) {
                return _buildMinimized(context);
              }
              return Positioned.fill(child: _buildCall(context, session));
            },
          ),
        ],
      );

  Widget _buildMinimized(BuildContext context) {
    final builder = widget.minimizedBuilder;
    if (builder == null) return const SizedBox.shrink();
    return builder(context, _controller.currentSnapshot);
  }

  Widget _buildCall(BuildContext context, CallSessionState session) =>
      switch (session.status) {
        CallLifecycleState.incomingRinging => _incoming(session),
        CallLifecycleState.outgoingRinging => _outgoing(session),
        _ => _inCall(session),
      };

  Widget _incoming(CallSessionState session) => ui.IncomingCallScreen(
        callerName: session.displayName ?? '',
        callerAvatarUrl: session.avatarUrl,
        callType: session.isVideo ? ui.CallType.video : ui.CallType.audio,
        theme: widget.theme,
        dimensions: widget.dimensions,
        strings: widget.strings,
        onAccept: _controller.acceptIncomingCall,
        onDecline: _controller.declineCall,
      );

  Widget _outgoing(CallSessionState session) =>
      ValueListenableBuilder<CallMediaState>(
        valueListenable: _controller.media,
        builder: (context, media, _) => ValueListenableBuilder<String>(
          valueListenable: _status,
          builder: (context, status, _) => ui.OutgoingCallScreen(
            callerName: session.displayName ?? '',
            callerAvatarUrl: session.avatarUrl,
            callType: session.isVideo ? ui.CallType.video : ui.CallType.audio,
            theme: widget.theme,
            dimensions: widget.dimensions,
            strings: widget.strings,
            callStatusText: status,
            isMuted: media.isMuted,
            isSpeakerOn: media.isSpeakerOn,
            onEndCall: _controller.hangupCall,
            onToggleMute: _controller.toggleMute,
            onToggleSpeaker: _controller.cycleAudioRoute,
            onMinimize: () => _controller.setOverlayExpanded(expanded: false),
          ),
        ),
      );

  /// Rebuilt from the aggregate snapshot rather than six nested builders: an
  /// in-call screen genuinely depends on all of it, and `CallSnapshot` compares
  /// by value, so an unrelated change does not rebuild the video surfaces.
  Widget _inCall(CallSessionState session) =>
      ValueListenableBuilder<CallSnapshot>(
        valueListenable: _SnapshotListenable(_controller),
        builder: (context, snapshot, _) {
          final room = snapshot.room;
          final participants = room == null
              ? const <ui.CallParticipant>[]
              : _mapper.remoteParticipants(room, snapshot.participants);

          return ui.CallScreen(
            callerName: session.displayName ?? '',
            callerAvatarUrl: session.avatarUrl,
            isGroupCall: session.isGroup,
            callType: session.isVideo ? ui.CallType.video : ui.CallType.audio,
            participants: participants,
            localParticipant: _mapper.localParticipant(
              room,
              snapshot.media,
              snapshot.participants,
              displayName: widget.localUserName,
              avatarUrl: widget.localUserAvatarUrl,
            ),
            screenShareWidget: _screenShareWidget(snapshot),
            isMuted: snapshot.media.isMuted,
            isCameraOff: !snapshot.media.isLocalVideoEnabled,
            isSpeakerOn: snapshot.media.isSpeakerOn,
            isScreenSharing: snapshot.screenShare.isLocalSharing,
            connectionState: _connectionState(session.status),
            theme: widget.theme,
            dimensions: widget.dimensions,
            strings: widget.strings,
            callStatusListenable: _status,
            onEndCall: _controller.hangupCall,
            onToggleMute: _controller.toggleMute,
            onToggleCamera: session.isVideo ? _controller.toggleVideo : null,
            onToggleSpeaker: _controller.cycleAudioRoute,
            onFlipCamera: session.isVideo ? _controller.switchCamera : null,
            onToggleScreenShare: _controller.toggleScreenShare,
            onStopScreenShare: snapshot.screenShare.isLocalSharing
                ? _controller.toggleScreenShare
                : null,
          );
        },
      );

  Widget? _screenShareWidget(CallSnapshot snapshot) {
    final room = snapshot.room;
    final share = snapshot.screenShare;
    if (room == null || !share.isActive || share.isLocalSharing) return null;
    return _mapper
        .screenSharer(room, snapshot.participants, share.participantIdentity)
        ?.screenShareWidget;
  }

  ui.CallConnectionState _connectionState(CallLifecycleState status) =>
      switch (status) {
        CallLifecycleState.inCall => ui.CallConnectionState.connected,
        CallLifecycleState.reconnecting => ui.CallConnectionState.reconnecting,
        _ => ui.CallConnectionState.connecting,
      };
}

/// Exposes the controller's merged state as a single [ValueListenable].
class _SnapshotListenable extends ValueNotifier<CallSnapshot> {
  _SnapshotListenable(this._controller) : super(_controller.currentSnapshot) {
    _controller.stateChanged.addListener(_sync);
  }

  final CallController _controller;

  void _sync() => value = _controller.currentSnapshot;

  @override
  void dispose() {
    _controller.stateChanged.removeListener(_sync);
    super.dispose();
  }
}
