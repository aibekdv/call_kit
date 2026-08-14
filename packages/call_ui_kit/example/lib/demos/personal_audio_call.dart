import 'package:call_ui_kit/call_ui_kit.dart';
import 'package:flutter/material.dart';

class PersonalAudioCallDemo extends StatefulWidget {
  const PersonalAudioCallDemo({super.key});

  @override
  State<PersonalAudioCallDemo> createState() => _PersonalAudioCallDemoState();
}

class _PersonalAudioCallDemoState extends State<PersonalAudioCallDemo> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isScreenSharing = false;

  @override
  Widget build(BuildContext context) {
    return CallScreen(
      callerName: 'Sarah Johnson',
      callType: CallType.audio,
      localParticipant: const CallParticipant(
        id: 'local',
        displayName: 'You',
        isLocalUser: true,
      ),
      isMuted: _isMuted,
      isSpeakerOn: _isSpeakerOn,
      isScreenSharing: _isScreenSharing,
      callStatusText: '02:45',
      onEndCall: () => Navigator.pop(context),
      onToggleMute: () => setState(() => _isMuted = !_isMuted),
      onToggleSpeaker: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
      onToggleScreenShare: () =>
          setState(() => _isScreenSharing = !_isScreenSharing),
      onStopScreenShare: () => setState(() => _isScreenSharing = false),
      onMinimize: () => debugPrint('Minimize'),
    );
  }
}
