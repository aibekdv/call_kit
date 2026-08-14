import 'dart:async';
import 'dart:math';

import 'package:call_ui_kit/call_ui_kit.dart';
import 'package:flutter/material.dart';

class GroupAudioCallDemo extends StatefulWidget {
  const GroupAudioCallDemo({super.key});

  @override
  State<GroupAudioCallDemo> createState() => _GroupAudioCallDemoState();
}

class _GroupAudioCallDemoState extends State<GroupAudioCallDemo> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isScreenSharing = false;

  Timer? _speakingTimer;
  final _random = Random();

  late List<CallParticipant> _participants = [
    const CallParticipant(
      id: '2',
      displayName: 'Sarah Johnson',
      avatarUrl: 'https://i.pravatar.cc/300?img=1',
    ),
    const CallParticipant(
      id: '3',
      displayName: 'Alex Rivera',
      avatarUrl: 'https://i.pravatar.cc/300?img=3',
      isMuted: true,
    ),
    const CallParticipant(
      id: '4',
      displayName: 'Priya Sharma',
      avatarUrl: 'https://i.pravatar.cc/300?img=5',
    ),
    const CallParticipant(
      id: '5',
      displayName: 'Marcus Chen',
      avatarUrl: 'https://i.pravatar.cc/300?img=7',
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
      callerName: 'Family Group',
      isGroupCall: true,
      callType: CallType.audio,
      localParticipant: const CallParticipant(
        id: 'local',
        displayName: 'You',
        isLocalUser: true,
        isHost: true,
      ),
      participants: _participants,
      isMuted: _isMuted,
      isSpeakerOn: _isSpeakerOn,
      isScreenSharing: _isScreenSharing,
      callStatusText: '05:32',
      onEndCall: () => Navigator.pop(context),
      onToggleMute: () => setState(() => _isMuted = !_isMuted),
      onToggleSpeaker: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
      onAddParticipant: () => debugPrint('Add participant'),
      onStopScreenShare: () => setState(() => _isScreenSharing = false),
      onMuteParticipant: (p) => debugPrint('Mute ${p.displayName}'),
      onRemoveParticipant: (p) => debugPrint('Remove ${p.displayName}'),
      moreSheetBuilder: (context, theme) => _AudioGroupMoreSheet(
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// More sheet content
// ---------------------------------------------------------------------------

class _AudioGroupMoreSheet extends StatelessWidget {
  final CallTheme theme;
  final bool isScreenSharing;
  final VoidCallback onToggleScreenShare;
  final VoidCallback onShowParticipants;

  const _AudioGroupMoreSheet({
    required this.theme,
    required this.isScreenSharing,
    required this.onToggleScreenShare,
    required this.onShowParticipants,
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
              'Participants',
              style: TextStyle(color: theme.textPrimary),
            ),
            trailing: Icon(
              Icons.people,
              color: theme.textPrimary.withValues(alpha: 0.7),
            ),
            onTap: onShowParticipants,
          ),
        ],
      ),
    );
  }
}
