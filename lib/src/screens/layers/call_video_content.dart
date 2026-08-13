/// The main video / avatar content layer for the call screen.
library;

import 'package:flutter/material.dart';

import '../../models/call_dimensions.dart';
import '../../models/call_participant.dart';
import '../../models/call_strings.dart';
import '../../models/call_theme.dart';
import '../../utils/group_call_layout_resolver.dart';
import '../../widgets/call_avatar.dart';
import '../../widgets/participant_tile.dart';
import '../../widgets/thumbnail_row.dart';
import '../../widgets/video_surface.dart';

/// Renders the appropriate video layout based on call type and participant count.
///
/// For personal calls: shows remote video or an avatar fallback.
/// For group calls: resolves layout via [GroupCallLayoutResolver] and renders
/// grid, speaker view, or screen-share view accordingly.
class CallVideoContent extends StatelessWidget {
  final CallTheme theme;
  final CallDimensions dimensions;
  final CallStrings strings;
  final bool isGroupCall;
  final String callerName;
  final String? callerAvatarUrl;
  final List<CallParticipant> participants;
  final CallParticipant localParticipant;

  /// Pre-computed list of all participants (remote + local).
  /// When provided, avoids re-creating the list on every build.
  final List<CallParticipant>? allParticipants;

  final Widget? remoteVideoWidget;
  final Widget? screenShareWidget;
  final bool isCameraOff;
  final bool isScreenSharing;
  final VoidCallback? onStopScreenShare;
  final VoidCallback onShowParticipantsPanel;

  const CallVideoContent({
    super.key,
    required this.theme,
    this.dimensions = const CallDimensions(),
    required this.strings,
    required this.isGroupCall,
    required this.callerName,
    this.callerAvatarUrl,
    required this.participants,
    required this.localParticipant,
    this.allParticipants,
    this.remoteVideoWidget,
    this.screenShareWidget,
    required this.isCameraOff,
    this.isScreenSharing = false,
    this.onStopScreenShare,
    required this.onShowParticipantsPanel,
  });

  @override
  Widget build(BuildContext context) {
    if (!isGroupCall) {
      return _buildPersonalCallContent();
    }

    final all = allParticipants ?? [...participants, localParticipant];
    final totalCount = all.length;
    final hasScreenShare = screenShareWidget != null;
    final layout = GroupCallLayoutResolver.resolve(
      totalCount: totalCount,
      hasScreenShare: hasScreenShare,
    );

    Widget content;
    switch (layout) {
      case GroupCallLayoutMode.fullScreenPip:
        return _buildPersonalCallContent();
      case GroupCallLayoutMode.grid2x2:
        content = _buildGrid(2, 2, all);
      case GroupCallLayoutMode.grid2x3:
        content = _buildGrid(2, 3, all);
      case GroupCallLayoutMode.speakerView:
        content = _buildSpeakerView();
      case GroupCallLayoutMode.screenShare:
        content = _buildScreenShareView(all);
    }

    return content;
  }

  Widget _buildPersonalCallContent() {
    final d = dimensions.videoContent;

    // Screen sharing active — show WhatsApp-style layout with thumbnails.
    if (screenShareWidget != null || isScreenSharing) {
      return _buildPersonalScreenShareView();
    }

    final hasRemoteVideo = remoteVideoWidget != null;

    if (isGroupCall && participants.isNotEmpty) {
      final remote = participants.first;
      if (remote.videoWidget != null && !remote.isCameraOff) {
        return VideoSurface(child: remote.videoWidget!);
      }
    }

    if (hasRemoteVideo) {
      return VideoSurface(child: remoteVideoWidget!);
    }

    return ColoredBox(
      color: theme.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CallAvatar(
              displayName: callerName,
              avatarUrl: callerAvatarUrl,
              radius: dimensions.scaled(d.personalAvatarRadius),
              theme: theme,
              backgroundColor: theme.buttonBackground,
              fontSize: dimensions.scaled(d.personalAvatarRadius) *
                  2 *
                  d.personalAvatarFontRatio,
            ),
            SizedBox(height: dimensions.scaled(d.personalAvatarNameGap)),
            Text(
              callerName,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: dimensions.scaled(d.personalNameFontSize),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalScreenShareView() {
    final thumbnailParticipants = <CallParticipant>[
      if (participants.isNotEmpty) participants.first,
      localParticipant,
    ];

    return Column(
      children: [
        Expanded(
          child: isScreenSharing
              ? _buildLocalSharingInfo()
              : screenShareWidget != null
                  ? VideoSurface(
                      backgroundColor: const Color(0xFF0A0A0A),
                      child: screenShareWidget!,
                    )
                  : const ColoredBox(color: Color(0xFF0A0A0A)),
        ),
        ThumbnailRow(
          participants: thumbnailParticipants,
          theme: theme,
          dimensions: dimensions,
          strings: strings,
        ),
      ],
    );
  }

  Widget _buildLocalSharingInfo() {
    final d = dimensions.videoContent;

    return ColoredBox(
      color: theme.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.screen_share,
              color: theme.textPrimary,
              size: dimensions.scaled(d.sharingIconSize),
            ),
            SizedBox(height: dimensions.scaled(d.sharingIconGap)),
            Text(
              strings.youAreSharingYourScreen,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: dimensions.scaled(d.sharingLabelFontSize),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onStopScreenShare != null) ...[
              SizedBox(height: dimensions.scaled(d.sharingLabelButtonGap)),
              GestureDetector(
                onTap: onStopScreenShare,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: dimensions.scaled(d.sharingStopHorizontal),
                    vertical: dimensions.scaled(d.sharingStopVertical),
                  ),
                  decoration: BoxDecoration(
                    color: theme.endCallColor,
                    borderRadius: BorderRadius.circular(
                      dimensions.scaled(d.sharingStopRadius),
                    ),
                  ),
                  child: Text(
                    strings.stopScreenSharing,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: dimensions.scaled(d.sharingStopFontSize),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(int columns, int maxRows, List<CallParticipant> all) {
    final count = all.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final visibleCount = count.clamp(0, columns * maxRows);
        final rows = (visibleCount / columns).ceil().clamp(1, maxRows);
        final tileHeight = constraints.maxHeight / rows;
        final colWidth = constraints.maxWidth / columns;

        return Stack(
          children: [
            for (var index = 0; index < visibleCount; index++)
              _buildGridTile(
                all[index],
                index: index,
                columns: columns,
                count: count,
                colWidth: colWidth,
                tileHeight: tileHeight,
                fullWidth: constraints.maxWidth,
              ),
          ],
        );
      },
    );
  }

  Widget _buildGridTile(
    CallParticipant p, {
    required int index,
    required int columns,
    required int count,
    required double colWidth,
    required double tileHeight,
    required double fullWidth,
  }) {
    final spanFullWidth = columns == 2 && count == 3 && index == 0;
    final tileWidth = spanFullWidth ? fullWidth : colWidth;

    final int col;
    final int row;
    if (spanFullWidth) {
      col = 0;
      row = 0;
    } else if (columns == 2 && count == 3 && index > 0) {
      col = index - 1;
      row = 1;
    } else {
      col = index % columns;
      row = index ~/ columns;
    }

    return AnimatedPositioned(
      key: ValueKey(p.id),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      left: col * colWidth,
      top: row * tileHeight,
      width: tileWidth - dimensions.videoContent.gridGutter,
      height: tileHeight - dimensions.videoContent.gridGutter,
      child: Padding(
        padding: EdgeInsets.all(dimensions.videoContent.gridGutter),
        child: ParticipantTile(
          key: ValueKey(p.id),
          participant: p,
          theme: theme,
          dimensions: dimensions,
          strings: strings,
        ),
      ),
    );
  }

  Widget _buildSpeakerView() {
    CallParticipant? activeSpeaker;
    for (final p in participants) {
      if (p.isSpeaking) {
        activeSpeaker = p;
        break;
      }
    }
    activeSpeaker ??= participants.isNotEmpty ? participants.first : null;

    final thumbnailParticipants = <CallParticipant>[
      for (final p in participants)
        if (p.id != activeSpeaker?.id) p,
      localParticipant,
    ];

    return Column(
      children: [
        Expanded(
          flex: 65,
          child: activeSpeaker != null
              ? ParticipantTile(
                  participant: activeSpeaker,
                  theme: theme,
                  dimensions: dimensions,
                  strings: strings,
                )
              : Container(color: theme.background),
        ),
        ThumbnailRow(
          participants: thumbnailParticipants,
          theme: theme,
          dimensions: dimensions,
          strings: strings,
          maxVisible: 6,
          onShowMore: onShowParticipantsPanel,
        ),
      ],
    );
  }

  Widget _buildScreenShareView(List<CallParticipant> allParticipants) {
    final thumbnailParticipants = allParticipants;

    return Column(
      children: [
        Expanded(
          flex: 65,
          child: screenShareWidget != null
              ? VideoSurface(
                  backgroundColor: const Color(0xFF0A0A0A),
                  child: screenShareWidget!,
                )
              : const ColoredBox(color: Color(0xFF0A0A0A)),
        ),
        ThumbnailRow(
          participants: thumbnailParticipants,
          theme: theme,
          dimensions: dimensions,
          strings: strings,
          maxVisible: 6,
          onShowMore: onShowParticipantsPanel,
        ),
      ],
    );
  }
}
