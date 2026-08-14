/// A four-bar signal strength indicator icon.
library;

import 'package:flutter/material.dart';

import '../models/call_type.dart';

/// Renders a signal strength icon composed of four bars of increasing height.
///
/// The number of "lit" (coloured) bars and their colour depend on the
/// [strength] level:
///
/// - [SignalStrength.excellent] -- all 4 bars, green.
/// - [SignalStrength.good] -- 3 bars, yellow-green.
/// - [SignalStrength.poor] -- 2 bars, orange.
/// - [SignalStrength.none] -- 1 bar, red.
///
/// Unlit bars are rendered with a 30 % opacity version of the active colour.
///
/// ```dart
/// SignalStrengthIcon(
///   strength: participant.signalStrength,
///   size: 16,
/// )
/// ```
class SignalStrengthIcon extends StatelessWidget {
  /// The signal strength level to visualise.
  final SignalStrength strength;

  /// The overall logical-pixel size of the icon. Bars are scaled relative
  /// to this value.
  final double size;

  /// An optional override colour for the lit bars. When `null`, the colour
  /// is derived automatically from [strength].
  final Color? color;

  /// Creates a [SignalStrengthIcon].
  const SignalStrengthIcon({
    super.key,
    required this.strength,
    this.size = 16,
    this.color,
  });

  int get _litBars {
    return switch (strength) {
      SignalStrength.excellent => 4,
      SignalStrength.good => 3,
      SignalStrength.poor => 2,
      SignalStrength.none => 1,
    };
  }

  Color get _activeColor {
    if (color != null) return color!;
    return switch (strength) {
      SignalStrength.excellent => const Color(0xFF4CAF50),
      SignalStrength.good => const Color(0xFF8BC34A),
      SignalStrength.poor => const Color(0xFFFF9800),
      SignalStrength.none => const Color(0xFFF44336),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Signal: ${strength.name}',
      child: CustomPaint(
        size: Size(size, size),
        painter: _SignalBarsPainter(
          litBars: _litBars,
          activeColor: _activeColor,
          size: size,
        ),
      ),
    );
  }
}

class _SignalBarsPainter extends CustomPainter {
  final int litBars;
  final Color activeColor;
  final double size;

  const _SignalBarsPainter({
    required this.litBars,
    required this.activeColor,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final barWidth = size / 6;
    final gap = size / 12;
    final dimColor = activeColor.withValues(alpha: 0.3);
    final radius = Radius.circular(barWidth / 2);
    final litPaint = Paint()..color = activeColor;
    final dimPaint = Paint()..color = dimColor;

    for (var i = 0; i < 4; i++) {
      final barHeight = size * (0.25 + 0.25 * i);
      final left = i * (barWidth + gap) + (size - 4 * barWidth - 3 * gap) / 2;
      final top = size - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        radius,
      );
      canvas.drawRRect(rect, i < litBars ? litPaint : dimPaint);
    }
  }

  @override
  bool shouldRepaint(_SignalBarsPainter old) =>
      litBars != old.litBars || activeColor != old.activeColor;
}
