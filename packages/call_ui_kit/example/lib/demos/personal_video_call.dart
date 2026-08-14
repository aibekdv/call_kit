import 'dart:async';

import 'package:call_ui_kit/call_ui_kit.dart';
import 'package:flutter/material.dart';

class PersonalVideoCallDemo extends StatefulWidget {
  const PersonalVideoCallDemo({super.key});

  @override
  State<PersonalVideoCallDemo> createState() => _PersonalVideoCallDemoState();
}

class _PersonalVideoCallDemoState extends State<PersonalVideoCallDemo> {
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isScreenSharing = false;
  bool _isFrontCamera = true;

  var _connectionState = CallConnectionState.connected;

  /// Incremented whenever the media renderers are recreated.
  ///
  /// Real applications recreate their `RTCVideoRenderer` (or equivalent) on a
  /// reconnect. Keying the video widgets by this counter tells Flutter to
  /// mount the new renderer instead of reusing the element that still points
  /// at the old, disposed one.
  int _rendererGeneration = 0;

  /// The video widgets are built once per renderer generation and held here,
  /// not constructed inside `build`. A fresh instance on every rebuild would
  /// force the kit to rebuild every video surface — which, with a call timer
  /// ticking once a second, means rebuilding them for the whole call.
  late Widget _localVideo;
  late Widget _remoteVideo;

  /// The call duration is pushed through a listenable rather than `setState`,
  /// so a tick rebuilds only the status line in the top bar.
  final ValueNotifier<String> _callStatus = ValueNotifier('00:00');
  final Stopwatch _elapsed = Stopwatch();

  Timer? _reconnectTimer;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _rebuildVideoWidgets();
    _elapsed.start();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final seconds = _elapsed.elapsed.inSeconds;
      _callStatus.value = '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
          '${(seconds % 60).toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _tickTimer?.cancel();
    _callStatus.dispose();
    super.dispose();
  }

  /// Replace the bodies with real renderer widgets from your WebRTC plugin.
  /// The key is what matters: it must change when a renderer is recreated,
  /// otherwise Flutter reuses the element and keeps the dead texture.
  void _rebuildVideoWidgets() {
    _localVideo = ColoredBox(
      key: ValueKey('local-$_rendererGeneration'),
      color: _isFrontCamera ? Colors.blueGrey : Colors.brown,
    );
    _remoteVideo = ColoredBox(
      key: ValueKey('remote-$_rendererGeneration'),
      color: Colors.teal,
    );
  }

  /// Stands in for a dropped connection: the renderers are torn down, the call
  /// reports "Reconnecting…", and a fresh generation of renderers comes back.
  void _simulateReconnect() {
    _reconnectTimer?.cancel();
    setState(() => _connectionState = CallConnectionState.reconnecting);

    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _rendererGeneration++;
        _rebuildVideoWidgets();
        _connectionState = CallConnectionState.connected;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallScreen(
      callerName: 'Alex Rivera',
      callerAvatarUrl: 'https://i.pravatar.cc/300?img=3',
      callType: CallType.video,
      localParticipant: const CallParticipant(
        id: 'local',
        displayName: 'You',
        isLocalUser: true,
      ),
      localVideoWidget: _localVideo,
      remoteVideoWidget: _remoteVideo,
      isMuted: _isMuted,
      isCameraOff: _isCameraOff,
      isSpeakerOn: _isSpeakerOn,
      isScreenSharing: _isScreenSharing,
      connectionState: _connectionState,
      callStatusListenable: _callStatus,
      onEndCall: () => Navigator.pop(context),
      onToggleMute: () => setState(() => _isMuted = !_isMuted),
      onToggleCamera: () => setState(() => _isCameraOff = !_isCameraOff),
      onToggleSpeaker: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
      onFlipCamera: () => setState(() {
        _isFrontCamera = !_isFrontCamera;
        _rebuildVideoWidgets();
      }),
      onStopScreenShare: () => setState(() => _isScreenSharing = false),
      moreSheetBuilder: (context, theme) => _MoreSheetContent(
        theme: theme,
        isScreenSharing: _isScreenSharing,
        onToggleScreenShare: () {
          Navigator.pop(context);
          setState(() => _isScreenSharing = !_isScreenSharing);
        },
        onSimulateReconnect: () {
          Navigator.pop(context);
          _simulateReconnect();
        },
        onSendMessage: () {
          Navigator.pop(context);
          debugPrint('Send message');
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// More sheet content
// ---------------------------------------------------------------------------

class _MoreSheetContent extends StatelessWidget {
  final CallTheme theme;
  final bool isScreenSharing;
  final VoidCallback onToggleScreenShare;
  final VoidCallback onSimulateReconnect;
  final VoidCallback onSendMessage;

  const _MoreSheetContent({
    required this.theme,
    required this.isScreenSharing,
    required this.onToggleScreenShare,
    required this.onSimulateReconnect,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.buttonBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              isScreenSharing ? 'Stop Screen Share' : 'Share Screen',
              style: TextStyle(color: theme.textPrimary),
            ),
            trailing: Icon(
              isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
              color: theme.textPrimary.withValues(alpha: 0.7),
            ),
            onTap: onToggleScreenShare,
          ),
          ListTile(
            title: Text(
              'Simulate Reconnect',
              style: TextStyle(color: theme.textPrimary),
            ),
            trailing: Icon(
              Icons.sync_problem,
              color: theme.textPrimary.withValues(alpha: 0.7),
            ),
            onTap: onSimulateReconnect,
          ),
          ListTile(
            title: Text(
              'Send Message',
              style: TextStyle(color: theme.textPrimary),
            ),
            trailing: Icon(
              Icons.message,
              color: theme.textPrimary.withValues(alpha: 0.7),
            ),
            onTap: onSendMessage,
          ),
        ],
      ),
    );
  }
}
