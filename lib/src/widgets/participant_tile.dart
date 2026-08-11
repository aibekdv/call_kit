/// A tile widget that displays a single participant's video or avatar
/// with status overlays.
library;

import 'package:flutter/material.dart';

import '../models/call_participant.dart';
import '../models/call_strings.dart';
import '../models/call_theme.dart';
import '../models/call_type.dart';
import 'call_avatar.dart';
import 'signal_strength_icon.dart';
import 'speaking_indicator.dart';
import 'video_surface.dart';

/// Displays a single call participant as a tile with layered overlays.
///
/// Shows the participant's live [CallParticipant.videoWidget] when available
/// and the camera is on, otherwise falls back to a circular avatar.
///
/// Overlays include a bottom gradient with name + speaking indicator,
/// mute icon, signal strength, screen-share badge, and an animated
/// speaking border.
class ParticipantTile extends StatelessWidget {
  /// The participant whose data drives this tile.
  final CallParticipant participant;

  /// The visual theme applied to the tile.
  final CallTheme theme;

  /// Localised strings.
  final CallStrings strings;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Creates a [ParticipantTile].
  const ParticipantTile({
    super.key,
    required this.participant,
    required this.theme,
    required this.strings,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = participant;
    final showVideo = p.videoWidget != null && !p.isCameraOff;

    return Semantics(
      label: '${p.displayName}'
          '${p.isMuted ? ', ${strings.muted}' : ''}'
          '${p.isSpeaking ? ', ${strings.speaking}' : ''}',
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1: Video or avatar fallback
              if (showVideo)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: VideoSurface(child: p.videoWidget!),
                  ),
                )
              else
                ColoredBox(
                  color: theme.barBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CallAvatar(
                          displayName: p.displayName,
                          avatarUrl: p.avatarUrl,
                          radius: 24,
                          theme: theme,
                          id: p.id,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.displayName,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // Layer 3: Bottom gradient (only when video is showing)
              if (showVideo)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x99000000)],
                      ),
                    ),
                  ),
                ),

              // Layer 4: Bottom-left — name + speaking indicator (only when video is showing)
              if (showVideo)
                Positioned(
                  left: 8,
                  right: p.isMuted ? 28 : 8,
                  bottom: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          p.displayName,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SpeakingIndicator(
                        color: theme.speakingColor,
                        visible: p.isSpeaking,
                        maxHeight: 12,
                        minHeight: 3,
                        barWidth: 2.5,
                      ),
                    ],
                  ),
                ),

              // Layer 5: Bottom-right — mic off
              if (p.isMuted)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Icon(
                    Icons.mic_off,
                    size: 14,
                    color: theme.textPrimary.withValues(alpha: 0.54),
                  ),
                ),

              // Layer 6: Top-left — signal strength (only when degraded)
              if (p.signalStrength != SignalStrength.excellent)
                Positioned(
                  left: 6,
                  top: 6,
                  child: SignalStrengthIcon(
                    strength: p.signalStrength,
                    size: 12,
                  ),
                ),

              // Layer 7: Top-right — screen share
              if (p.isScreenSharing)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Icon(
                    Icons.screen_share,
                    size: 14,
                    color: theme.textPrimary.withValues(alpha: 0.7),
                  ),
                ),

              // Layer 8: Animated speaking border (isolated StatefulWidget)
              _SpeakingBorderOverlay(
                isSpeaking: p.isSpeaking,
                color: theme.speakingColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An isolated widget that owns its own [AnimationController] for the
/// speaking-border pulse animation. This prevents the parent
/// [ParticipantTile] from needing to be a [StatefulWidget] and avoids
/// rebuilding the entire tile stack when only the border animates.
class _SpeakingBorderOverlay extends StatefulWidget {
  final bool isSpeaking;
  final Color color;

  const _SpeakingBorderOverlay({
    required this.isSpeaking,
    required this.color,
  });

  @override
  State<_SpeakingBorderOverlay> createState() => _SpeakingBorderOverlayState();
}

class _SpeakingBorderOverlayState extends State<_SpeakingBorderOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _opacity;

  void _ensureController() {
    if (_controller != null) return;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.isSpeaking) {
      _ensureController();
      _controller!.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _SpeakingBorderOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking) {
      _ensureController();
      if (!_controller!.isAnimating) {
        _controller!.repeat(reverse: true);
      }
    } else if (_controller != null && _controller!.isAnimating) {
      _controller!.stop();
      _controller!.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSpeaking) return const SizedBox.shrink();
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SpeakingBorderPainter(
          animation: _opacity!,
          color: widget.color,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

class _SpeakingBorderPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final double strokeWidth;

  _SpeakingBorderPainter({
    required this.animation,
    required this.color,
    required this.strokeWidth,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_SpeakingBorderPainter old) =>
      color != old.color || strokeWidth != old.strokeWidth;
}
