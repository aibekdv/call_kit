/// Visual theme configuration for the call UI.
library;

import 'package:flutter/material.dart';

/// Defines the colour palette for the call UI.
///
/// Controls all colours used across the call screen and its sub-widgets.
/// Use the [CallTheme.whatsApp] constructor for the default WhatsApp-style
/// dark theme.
///
/// Use [copyWith] to derive a customised variant from any preset.
class CallTheme {
  /// Main background colour of the call screen.
  final Color background;

  /// Background colour for the bottom controls bar.
  final Color barBackground;

  /// Background colour for individual circular buttons.
  final Color buttonBackground;

  /// Colour for the end-call button.
  final Color endCallColor;

  /// Colour used for speaking indicators and active-speaker borders.
  final Color speakingColor;

  /// Background colour of the speaker button when speaker is active.
  final Color speakerActiveBackground;

  /// Icon colour of the speaker button when speaker is active.
  final Color speakerActiveIconColor;

  /// Primary text colour (caller name, participant names).
  final Color textPrimary;

  /// Secondary text colour (status text, subtitles).
  final Color textSecondary;

  /// Divider colour used in bottom sheets and panels.
  final Color dividerColor;

  /// Colour for the accept-call button on the incoming call screen.
  final Color acceptCallColor;

  /// Creates a [CallTheme] with all colours specified.
  const CallTheme({
    required this.background,
    required this.barBackground,
    required this.buttonBackground,
    required this.endCallColor,
    required this.speakingColor,
    required this.speakerActiveBackground,
    required this.speakerActiveIconColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.dividerColor,
    required this.acceptCallColor,
  });

  /// WhatsApp-style dark theme matching the reference screenshots.
  const CallTheme.whatsApp()
      : background = const Color(0xFF000000),
        barBackground = const Color(0xFF1C1C1E),
        buttonBackground = const Color(0xFF2C2C2E),
        endCallColor = const Color(0xFFE53935),
        speakingColor = const Color(0xFF25D366),
        speakerActiveBackground = Colors.white,
        speakerActiveIconColor = Colors.black,
        textPrimary = Colors.white,
        textSecondary = const Color(0xFFAAAAAA),
        dividerColor = const Color(0xFF3A3A3C),
        acceptCallColor = const Color(0xFF25D366);

  /// Returns a copy of this theme with the given fields replaced.
  CallTheme copyWith({
    Color? background,
    Color? barBackground,
    Color? buttonBackground,
    Color? endCallColor,
    Color? speakingColor,
    Color? speakerActiveBackground,
    Color? speakerActiveIconColor,
    Color? textPrimary,
    Color? textSecondary,
    Color? dividerColor,
    Color? acceptCallColor,
  }) {
    return CallTheme(
      background: background ?? this.background,
      barBackground: barBackground ?? this.barBackground,
      buttonBackground: buttonBackground ?? this.buttonBackground,
      endCallColor: endCallColor ?? this.endCallColor,
      speakingColor: speakingColor ?? this.speakingColor,
      speakerActiveBackground:
          speakerActiveBackground ?? this.speakerActiveBackground,
      speakerActiveIconColor:
          speakerActiveIconColor ?? this.speakerActiveIconColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      dividerColor: dividerColor ?? this.dividerColor,
      acceptCallColor: acceptCallColor ?? this.acceptCallColor,
    );
  }

  @override
  String toString() => 'CallTheme(background: $background, '
      'endCallColor: $endCallColor, speakingColor: $speakingColor)';
}
