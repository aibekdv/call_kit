/// A horizontal scrollable row of participant thumbnail tiles.
library;

import 'package:flutter/material.dart';

import '../models/call_participant.dart';
import '../models/call_strings.dart';
import '../models/call_theme.dart';
import 'participant_tile.dart';

/// Displays a horizontal scrollable row of [ParticipantTile] thumbnails.
///
/// Used in speaker view and screen-share view to show non-featured
/// participants.  When [maxVisible] is set and the list exceeds that count,
/// a "+N more" tile is appended.
class ThumbnailRow extends StatelessWidget {
  final List<CallParticipant> participants;
  final CallTheme theme;
  final CallStrings strings;

  /// Maximum number of thumbnails before showing a "+N more" tile.
  /// When null, all participants are shown.
  final int? maxVisible;

  /// Called when the "+N more" tile is tapped.
  final VoidCallback? onShowMore;

  const ThumbnailRow({
    super.key,
    required this.participants,
    required this.theme,
    required this.strings,
    this.maxVisible,
    this.onShowMore,
  });

  @override
  Widget build(BuildContext context) {
    final hasOverflow = maxVisible != null && participants.length > maxVisible!;
    final itemCount = hasOverflow ? maxVisible! + 1 : participants.length;

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // "+N more" tile
          if (hasOverflow && index == maxVisible) {
            final remaining = participants.length - maxVisible!;
            return GestureDetector(
              onTap: onShowMore,
              child: Container(
                key: const ValueKey('_more'),
                width: 70,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: theme.buttonBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    strings.moreParticipants(remaining),
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }

          final p = participants[index];
          return Container(
            key: ValueKey(p.id),
            width: 70,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ParticipantTile(
                  participant: p,
                  theme: theme,
                  strings: strings,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
