import 'package:call_ui_kit/call_ui_kit.dart';
import 'package:flutter/material.dart';

class OutgoingCallDemo extends StatefulWidget {
  const OutgoingCallDemo({super.key});

  @override
  State<OutgoingCallDemo> createState() => _OutgoingCallDemoState();
}

class _OutgoingCallDemoState extends State<OutgoingCallDemo> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  @override
  Widget build(BuildContext context) {
    return OutgoingCallScreen(
      callerName: 'Alex Rivera',
      callerAvatarUrl: 'https://i.pravatar.cc/300?img=3',
      callType: CallType.video,
      isMuted: _isMuted,
      isSpeakerOn: _isSpeakerOn,
      onEndCall: () {
        debugPrint('End call');
        Navigator.pop(context);
      },
      onToggleMute: () => setState(() => _isMuted = !_isMuted),
      onToggleSpeaker: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
      onMinimize: () => Navigator.pop(context),
    );
  }
}
