/// A panel listing all participants in a group call.
library;

import 'package:flutter/material.dart';

import '../models/call_dimensions.dart';
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

  /// The sizing configuration. Defaults to the kit's native metrics.
  final CallDimensions dimensions;

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
    this.dimensions = const CallDimensions(),
    required this.strings,
    this.onMuteParticipant,
    this.onMuteAll,
    this.onRemoveParticipant,
    this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final d = dimensions.participantsPanel;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.barBackground,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(dimensions.scaled(d.radius)),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              HandleBar(dimensions: dimensions),

              // Header
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: dimensions.scaled(d.headerHorizontal),
                  vertical: dimensions.scaled(d.headerVertical),
                ),
                child: Row(
                  children: [
                    Text(
                      '${strings.participants} '
                      '(${participants.length})',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: dimensions.scaled(d.titleFontSize),
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
                            fontSize: dimensions.scaled(d.muteAllFontSize),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.textPrimary,
                        size: dimensions.scaled(d.closeIconSize),
                      ),
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
                    left: dimensions.scaled(d.inviteHorizontal),
                    right: dimensions.scaled(d.inviteHorizontal),
                    bottom: MediaQuery.paddingOf(context).bottom +
                        dimensions.scaled(d.bottomPadding),
                    top: dimensions.scaled(d.inviteTop),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: dimensions.scaled(d.inviteButtonHeight),
                    child: ElevatedButton.icon(
                      onPressed: onInvite,
                      icon: Icon(
                        Icons.add,
                        size: dimensions.scaled(d.inviteIconSize),
                      ),
                      label: Text(strings.invite),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.speakingColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            dimensions.scaled(d.inviteRadius),
                          ),
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
    final d = dimensions.participantsPanel;
    final icons = <Widget>[
      if (p.isMuted)
        Icon(Icons.mic_off,
            size: dimensions.scaled(d.rowIconSize),
            color: theme.textPrimary.withValues(alpha: 0.38)),
      if (p.isScreenSharing)
        Icon(Icons.screen_share,
            size: dimensions.scaled(d.rowIconSize), color: Colors.blue[300]),
      if (p.isHost)
        Icon(Icons.workspace_premium,
            size: dimensions.scaled(d.rowHostIconSize), color: Colors.amber),
    ];

    return GestureDetector(
      onLongPress: isLocalHost && !p.isLocalUser
          ? () => _showHostActions(context, p)
          : null,
      child: Container(
        height: dimensions.scaled(d.rowHeight),
        padding: EdgeInsets.symmetric(
          horizontal: dimensions.scaled(d.rowHorizontal),
        ),
        child: Row(
          children: [
            // Avatar
            CallAvatar(
              displayName: p.displayName,
              avatarUrl: p.avatarUrl,
              radius: dimensions.scaled(d.rowAvatarRadius),
              theme: theme,
              id: p.id,
              fontSize: dimensions.scaled(d.rowAvatarFontSize),
            ),
            SizedBox(width: dimensions.scaled(d.rowAvatarGap)),

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
                      fontSize: dimensions.scaled(d.rowNameFontSize),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (p.isSpeaking)
                    Text(
                      strings.speaking,
                      style: TextStyle(
                        color: theme.speakingColor,
                        fontSize: dimensions.scaled(d.rowStatusFontSize),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (p.isMuted)
                    Text(
                      strings.muted,
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.38),
                        fontSize: dimensions.scaled(d.rowStatusFontSize),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Status icons
            if (icons.isNotEmpty) ...[
              SizedBox(width: dimensions.scaled(d.rowIconGap)),
              Wrap(
                spacing: dimensions.scaled(d.rowIconGap),
                children: icons,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showHostActions(BuildContext context, CallParticipant participant) {
    final d = dimensions.participantsPanel;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.barBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(dimensions.scaled(d.radius)),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom +
              dimensions.scaled(d.bottomPadding),
          top: dimensions.scaled(d.hostActionsTop),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HandleBar(
              dimensions: dimensions,
              margin: EdgeInsets.only(
                bottom: dimensions.scaled(d.hostActionsHandleGap),
              ),
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
