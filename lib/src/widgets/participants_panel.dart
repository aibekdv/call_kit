/// A panel listing all participants in a group call.
library;

import 'package:flutter/material.dart';

import '../models/call_participant.dart';
import '../models/call_strings.dart';
import '../models/call_theme.dart';
import 'call_avatar.dart';
import 'handle_bar.dart';

/// A draggable bottom sheet showing all participants in a group call.
///
/// Includes per-participant status indicators and host actions
/// (mute, remove) via long-press.
class ParticipantsPanel extends StatelessWidget {
  /// All current participants including the local user.
  final List<CallParticipant> participants;

  /// Whether the local user is the host.
  final bool isLocalHost;

  /// The visual theme.
  final CallTheme theme;

  /// Localised strings.
  final CallStrings strings;

  /// Called when the host mutes a participant.
  final void Function(CallParticipant)? onMuteParticipant;

  /// Called when the host taps "Mute all".
  ///
  /// When provided, this is called instead of invoking [onMuteParticipant]
  /// for each unmuted participant, allowing the host app to batch the
  /// state update into a single operation.
  final VoidCallback? onMuteAll;

  /// Called when the host removes a participant.
  final void Function(CallParticipant)? onRemoveParticipant;

  /// Called when the invite / add-participant button is tapped.
  /// When null, the invite button is hidden.
  final VoidCallback? onInvite;

  /// Creates a [ParticipantsPanel].
  const ParticipantsPanel({
    super.key,
    required this.participants,
    this.isLocalHost = false,
    required this.theme,
    required this.strings,
    this.onMuteParticipant,
    this.onMuteAll,
    this.onRemoveParticipant,
    this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.barBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle bar
              const HandleBar(),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${strings.participants} '
                      '(${participants.length})',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (isLocalHost)
                      TextButton(
                        onPressed: () {
                          if (onMuteAll != null) {
                            onMuteAll!();
                          } else {
                            for (final p in participants) {
                              if (!p.isLocalUser && !p.isMuted) {
                                onMuteParticipant?.call(p);
                              }
                            }
                          }
                        },
                        child: Text(
                          strings.muteAll,
                          style: TextStyle(
                            color: theme.endCallColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    IconButton(
                      icon:
                          Icon(Icons.close, color: theme.textPrimary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Participant list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final p = participants[index];
                    return KeyedSubtree(
                      key: ValueKey(p.id),
                      child: _buildParticipantRow(context, p),
                    );
                  },
                ),
              ),

              // Invite button (only when callback provided)
              if (onInvite != null)
                Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.paddingOf(context).bottom + 16,
                    top: 8,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: onInvite,
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(strings.invite),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.speakingColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipantRow(BuildContext context, CallParticipant p) {
    final icons = <Widget>[
      if (p.isMuted)
        Icon(Icons.mic_off,
            size: 18, color: theme.textPrimary.withValues(alpha: 0.38)),
      if (p.isScreenSharing)
        Icon(Icons.screen_share, size: 18, color: Colors.blue[300]),
      if (p.isHost)
        const Icon(Icons.workspace_premium, size: 16, color: Colors.amber),
    ];

    return GestureDetector(
      onLongPress: isLocalHost && !p.isLocalUser
          ? () => _showHostActions(context, p)
          : null,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Avatar
            CallAvatar(
              displayName: p.displayName,
              avatarUrl: p.avatarUrl,
              radius: 18,
              theme: theme,
              id: p.id,
              fontSize: 14,
            ),
            const SizedBox(width: 12),

            // Name + status
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.displayName,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (p.isSpeaking)
                    Text(
                      strings.speaking,
                      style: TextStyle(
                        color: theme.speakingColor,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (p.isMuted)
                    Text(
                      strings.muted,
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.38),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Status icons
            if (icons.isNotEmpty) ...[
              const SizedBox(width: 8),
              Wrap(
                spacing: 8,
                children: icons,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showHostActions(BuildContext context, CallParticipant participant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.barBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 16,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HandleBar(
              margin: EdgeInsets.only(bottom: 16),
            ),
            ListTile(
              leading: Icon(
                participant.isMuted ? Icons.mic : Icons.mic_off,
                color: theme.textPrimary,
              ),
              title: Text(
                participant.isMuted ? strings.unmute : strings.mute,
                style: TextStyle(color: theme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                onMuteParticipant?.call(participant);
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.remove_circle_outline, color: theme.endCallColor),
              title: Text(
                strings.removeFromCall,
                style: TextStyle(color: theme.endCallColor),
              ),
              onTap: () {
                Navigator.pop(context);
                onRemoveParticipant?.call(participant);
              },
            ),
          ],
        ),
      ),
    );
  }
}
