import 'package:call_ui_kit/call_ui_kit.dart';
import 'package:flutter/material.dart';

class AudioScreenShareDemo extends StatefulWidget {
  const AudioScreenShareDemo({super.key});

  @override
  State<AudioScreenShareDemo> createState() => _AudioScreenShareDemoState();
}

class _AudioScreenShareDemoState extends State<AudioScreenShareDemo> {
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isScreenSharing = true;

  @override
  Widget build(BuildContext context) {
    return CallScreen(
      callerName: 'Sarah Johnson',
      callerAvatarUrl: 'https://i.pravatar.cc/300?img=1',
      callType: CallType.audio,
      localParticipant: const CallParticipant(
        id: 'local',
        displayName: 'You',
        isLocalUser: true,
      ),
      isScreenSharing: _isScreenSharing,
      // Replace with the real screen share widget
      screenShareWidget: Container(
        color: const Color(0xFF1A1A2E),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.desktop_windows, color: Colors.white54, size: 64),
              SizedBox(height: 16),
              Text(
                'Your Screen',
                style: TextStyle(color: Colors.white70, fontSize: 20),
              ),
            ],
          ),
        ),
      ),
      isMuted: _isMuted,
      isSpeakerOn: _isSpeakerOn,
      callStatusText: '03:10',
      onEndCall: () => Navigator.pop(context),
      onToggleMute: () => setState(() => _isMuted = !_isMuted),
      onToggleSpeaker: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
      onStopScreenShare: () =>
          setState(() => _isScreenSharing = !_isScreenSharing),
      onMinimize: () => debugPrint('Minimize'),
    );
  }
}
