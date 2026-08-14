import 'package:call_ui_kit/call_ui_kit.dart';
import 'package:flutter/material.dart';

class GroupScreenShareDemo extends StatefulWidget {
  const GroupScreenShareDemo({super.key});

  @override
  State<GroupScreenShareDemo> createState() => _GroupScreenShareDemoState();
}

class _GroupScreenShareDemoState extends State<GroupScreenShareDemo> {
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;

  static const _participants = [
    CallParticipant(
      id: '2',
      displayName: 'Alex Rivera',
      avatarUrl: 'https://i.pravatar.cc/300?img=3',
      isScreenSharing: true,
    ),
    CallParticipant(
      id: '3',
      displayName: 'Priya Sharma',
      avatarUrl: 'https://i.pravatar.cc/300?img=5',
    ),
    CallParticipant(
      id: '4',
      displayName: 'Marcus Chen',
      avatarUrl: 'https://i.pravatar.cc/300?img=7',
      isMuted: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CallScreen(
      callerName: 'Design Review',
      isGroupCall: true,
      callType: CallType.video,
      localParticipant: const CallParticipant(
        id: 'local',
        displayName: 'You',
        isLocalUser: true,
      ),
      participants: _participants,
      // Replace with the real screen share widget from your streaming plugin
      screenShareWidget: Container(
        color: const Color(0xFF1A1A2E),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.screen_share, color: Colors.white54, size: 64),
              SizedBox(height: 16),
              Text(
                'Screen Share Content',
                style: TextStyle(color: Colors.white70, fontSize: 20),
              ),
            ],
          ),
        ),
      ),
      isMuted: _isMuted,
      isCameraOff: _isCameraOff,
      isSpeakerOn: _isSpeakerOn,
      callStatusText: '08:15',
      onEndCall: () => Navigator.pop(context),
      onToggleMute: () => setState(() => _isMuted = !_isMuted),
      onToggleCamera: () => setState(() => _isCameraOff = !_isCameraOff),
      onToggleSpeaker: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
      onFlipCamera: () => debugPrint('Flip camera'),
    );
  }
}
