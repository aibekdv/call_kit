import 'package:call_ui_kit/call_ui_kit.dart';
import 'package:flutter/material.dart';

class PersonalScreenShareDemo extends StatefulWidget {
  const PersonalScreenShareDemo({super.key});

  @override
  State<PersonalScreenShareDemo> createState() =>
      _PersonalScreenShareDemoState();
}

class _PersonalScreenShareDemoState extends State<PersonalScreenShareDemo> {
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isLocalSharing = true;

  @override
  Widget build(BuildContext context) {
    return CallScreen(
      callerName: 'Alex Rivera',
      callerAvatarUrl: 'https://i.pravatar.cc/300?img=3',
      callType: CallType.video,
      localParticipant: CallParticipant(
        id: 'local',
        displayName: 'You',
        isLocalUser: true,
        videoWidget: Container(color: Colors.blueGrey),
      ),
      participants: [
        CallParticipant(
          id: '2',
          displayName: 'Alex Rivera',
          avatarUrl: 'https://i.pravatar.cc/300?img=3',
          videoWidget: Container(color: Colors.teal),
        ),
      ],
      localVideoWidget: Container(color: Colors.blueGrey),
      remoteVideoWidget: Container(color: Colors.teal),
      // When remote is sharing, provide screenShareWidget
      screenShareWidget: _isLocalSharing
          ? null
          : Container(
              color: const Color(0xFF1A1A2E),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.screen_share, color: Colors.white54, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Remote Screen Share Content',
                      style: TextStyle(color: Colors.white70, fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
      isScreenSharing: _isLocalSharing,
      isMuted: _isMuted,
      isCameraOff: _isCameraOff,
      isSpeakerOn: _isSpeakerOn,
      callStatusText: '06:42',
      onEndCall: () => Navigator.pop(context),
      onToggleMute: () => setState(() => _isMuted = !_isMuted),
      onToggleCamera: () => setState(() => _isCameraOff = !_isCameraOff),
      onToggleSpeaker: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
      onFlipCamera: () => debugPrint('Flip camera'),
      onStopScreenShare: () => setState(() => _isLocalSharing = false),
      moreSheetBuilder: (context, theme) => _MoreSheetContent(
        theme: theme,
        isLocalSharing: _isLocalSharing,
        onToggleMode: () {
          Navigator.pop(context);
          setState(() => _isLocalSharing = !_isLocalSharing);
        },
      ),
    );
  }
}

class _MoreSheetContent extends StatelessWidget {
  final CallTheme theme;
  final bool isLocalSharing;
  final VoidCallback onToggleMode;

  const _MoreSheetContent({
    required this.theme,
    required this.isLocalSharing,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.buttonBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          isLocalSharing
              ? 'Switch to Remote Sharing'
              : 'Switch to Local Sharing',
          style: TextStyle(color: theme.textPrimary),
        ),
        trailing: Icon(
          Icons.swap_horiz,
          color: theme.textPrimary.withValues(alpha: 0.7),
        ),
        onTap: onToggleMode,
      ),
    );
  }
}
