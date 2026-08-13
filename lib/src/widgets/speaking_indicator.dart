/// A three-bar animated speaking indicator.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Displays three vertical bars that animate in a sine-wave pattern to
/// indicate that a participant is actively speaking.
///
/// Uses a single animation controller with phase offsets to create a
/// staggered wave effect across the three bars. The indicator fades
/// in/out based on [visible].
///
/// ```dart
/// SpeakingIndicator(
///   color: theme.speakingBorderColor,
///   visible: participant.isSpeaking,
/// )
/// ```
class SpeakingIndicator extends StatefulWidget {
  /// The colour applied to all three bars.
  final Color color;

  /// The maximum height each bar animates to, in logical pixels.
  final double maxHeight;

  /// The minimum height each bar animates from, in logical pixels.
  final double minHeight;

  /// The width of each individual bar, in logical pixels.
  final double barWidth;

  /// The spacing between two bars, in logical pixels.
  final double gap;

  /// The full cycle duration for the sine animation.
  final Duration duration;

  /// Whether the indicator is visible. When `false`, it fades out.
  final bool visible;

  /// Creates a [SpeakingIndicator].
  const SpeakingIndicator({
    super.key,
    required this.color,
    this.maxHeight = 14,
    this.minHeight = 4,
    this.barWidth = 3,
    this.gap = 2,
    this.duration = const Duration(milliseconds: 700),
    this.visible = true,
  });

  @override
  State<SpeakingIndicator> createState() => _SpeakingIndicatorState();
}

class _SpeakingIndicatorState extends State<SpeakingIndicator>
    with SingleTickerProviderStateMixin {
  static const _barCount = 3;
  // Phase offsets: 120ms / 700ms ≈ 0.171 per bar
  static const _phaseOffsets = [0.0, 0.171, 0.343];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.visible) _controller.repeat();
  }

  @override
  void didUpdateWidget(SpeakingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth =
        widget.barWidth * _barCount + widget.gap * (_barCount - 1);
    return AnimatedOpacity(
      opacity: widget.visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(totalWidth, widget.maxHeight),
          painter: _SpeakingBarsPainter(
            animation: _controller,
            color: widget.color,
            barWidth: widget.barWidth,
            gap: widget.gap,
            maxHeight: widget.maxHeight,
            minHeight: widget.minHeight,
            phaseOffsets: _phaseOffsets,
          ),
        ),
      ),
    );
  }
}

class _SpeakingBarsPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final double barWidth;
  final double gap;
  final double maxHeight;
  final double minHeight;
  final List<double> phaseOffsets;

  _SpeakingBarsPainter({
    required this.animation,
    required this.color,
    required this.barWidth,
    required this.gap,
    required this.maxHeight,
    required this.minHeight,
    required this.phaseOffsets,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final radius = Radius.circular(barWidth / 2);

    for (var i = 0; i < phaseOffsets.length; i++) {
      final sineValue =
          math.sin((animation.value + phaseOffsets[i]) * 2 * math.pi);
      final normalized = (sineValue + 1) / 2;
      final barHeight = minHeight + (maxHeight - minHeight) * normalized;
      final left = i * (barWidth + gap);
      final top = size.height - barHeight;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, barHeight),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpeakingBarsPainter oldDelegate) =>
      color != oldDelegate.color ||
      barWidth != oldDelegate.barWidth ||
      gap != oldDelegate.gap ||
      maxHeight != oldDelegate.maxHeight ||
      minHeight != oldDelegate.minHeight;
}
