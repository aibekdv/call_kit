import 'dart:async';
import 'dart:math';

import 'package:call_ui_kit/call_ui_kit.dart';
import 'package:flutter/material.dart';

class GroupVideoCallDemo extends StatefulWidget {
  const GroupVideoCallDemo({super.key});

  @override
  State<GroupVideoCallDemo> createState() => _GroupVideoCallDemoState();
}

class _GroupVideoCallDemoState extends State<GroupVideoCallDemo> {
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isScreenSharing = false;

  Timer? _speakingTimer;
  final _random = Random();

  late List<CallParticipant> _participants = [
    const CallParticipant(
      id: '2',
      displayName: 'Alex Rivera',
      avatarUrl: 'https://i.pravatar.cc/300?img=3',
    ),
    const CallParticipant(
      id: '3',
      displayName: 'Priya Sharma',
      avatarUrl: 'https://i.pravatar.cc/300?img=5',
      isMuted: true,
    ),
    const CallParticipant(
      id: '4',
      displayName: 'Marcus Chen',
      avatarUrl: 'https://i.pravatar.cc/300?img=7',
    ),
    const CallParticipant(
      id: '5',
      displayName: 'Elena Volkov',
      avatarUrl: 'https://i.pravatar.cc/300?img=9',
      isCameraOff: true,
    ),
    const CallParticipant(
      id: '6',
      displayName: 'James Wilson',
      avatarUrl: 'https://i.pravatar.cc/300?img=11',
    ),
    const CallParticipant(
      id: '7',
      displayName: 'Yuki Tanaka',
      avatarUrl: 'https://i.pravatar.cc/300?img=13',
      isMuted: true,
    ),
    const CallParticipant(
      id: '8',
      displayName: 'Fatima Al-Rashid',
      avatarUrl: 'https://i.pravatar.cc/300?img=15',
    ),
  ];

  // ── Lifecycle ──

  @override
  void initState() {
    super.initState();
    _startRandomSpeaking();
  }

  @override
  void dispose() {
    _speakingTimer?.cancel();
    super.dispose();
  }

  /// Simulates random participants speaking every 3 seconds.
  void _startRandomSpeaking() {
    _speakingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final idx = _random.nextInt(_participants.length);
      setState(() {
        _participants = [
          for (int i = 0; i < _participants.length; i++)
            _participants[i].copyWith(isSpeaking: i == idx),
        ];
      });
    });
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return CallScreen(
      callerName: 'Team Meeting',
      isGroupCall: true,
      callType: CallType.video,
      localParticipant: const CallParticipant(
        id: 'local',
        displayName: 'You',
        isLocalUser: true,
        isHost: true,
      ),
      participants: _participants,
      isMuted: _isMuted,
      isCameraOff: _isCameraOff,
      isSpeakerOn: _isSpeakerOn,
      isScreenSharing: _isScreenSharing,
      callStatusText: '12:07',
      onEndCall: () => Navigator.pop(context),
      onToggleMute: () => setState(() => _isMuted = !_isMuted),
      onToggleCamera: () => setState(() => _isCameraOff = !_isCameraOff),
      onToggleSpeaker: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
      onFlipCamera: () => debugPrint('Flip camera'),
      onAddParticipant: () => debugPrint('Add participant'),
      onStopScreenShare: () => setState(() => _isScreenSharing = false),
      onMuteParticipant: (p) => debugPrint('Mute ${p.displayName}'),
      onRemoveParticipant: (p) => debugPrint('Remove ${p.displayName}'),
      moreSheetBuilder: (context, theme) => _GroupMoreSheet(
        theme: theme,
        isScreenSharing: _isScreenSharing,
        onToggleScreenShare: () {
          Navigator.pop(context);
          setState(() => _isScreenSharing = !_isScreenSharing);
        },
        onShowParticipants: () {
          Navigator.pop(context);
          debugPrint('Show participants');
        },
        onShareLink: () {
          Navigator.pop(context);
          debugPrint('Share link');
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// More sheet content for group call
// ---------------------------------------------------------------------------

class _GroupMoreSheet extends StatelessWidget {
  final CallTheme theme;
  final bool isScreenSharing;
  final VoidCallback onToggleScreenShare;
  final VoidCallback onShowParticipants;
  final VoidCallback onShareLink;

  const _GroupMoreSheet({
    required this.theme,
    required this.isScreenSharing,
    required this.onToggleScreenShare,
    required this.onShowParticipants,
    required this.onShareLink,
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
          _tile(
            title: isScreenSharing ? 'Stop Screen Share' : 'Share Screen',
            icon: isScreenSharing
                ? Icons.stop_screen_share
                : Icons.mobile_screen_share,
            onTap: onToggleScreenShare,
          ),
          _tile(
            title: 'Participants',
            icon: Icons.people,
            onTap: onShowParticipants,
          ),
          _tile(
            title: 'Share Call Link',
            icon: Icons.link,
            onTap: onShareLink,
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title, style: TextStyle(color: theme.textPrimary)),
      trailing: Icon(icon, color: theme.textPrimary.withValues(alpha: 0.7)),
      onTap: onTap,
    );
  }
}
