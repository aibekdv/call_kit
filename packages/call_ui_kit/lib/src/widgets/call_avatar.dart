/// Shared avatar widget used across the call UI.
library;

import 'package:flutter/material.dart';

import '../models/call_theme.dart';

/// A circle avatar that displays either a network image or a coloured
/// initial fallback.
///
/// - If [avatarUrl] is null or empty → shows coloured circle with initial.
/// - If [avatarUrl] is provided → loads the image; on error falls back
///   to the initial.
class CallAvatar extends StatelessWidget {
  /// The name used to derive the initial letter.
  final String displayName;

  /// Optional network URL for the avatar image.
  final String? avatarUrl;

  /// The avatar radius in logical pixels.
  final double radius;

  /// Visual theme providing fallback colours.
  final CallTheme theme;

  /// Optional override for the fallback background colour.
  /// When null, a colour is chosen from [avatarColors] based on [id].
  final Color? backgroundColor;

  /// An identifier used to pick a stable fallback colour.
  /// Falls back to [displayName.hashCode] when null.
  final String? id;

  /// Font size for the initial letter.  When null, defaults to `radius * 0.75`.
  final double? fontSize;

  const CallAvatar({
    super.key,
    required this.displayName,
    this.avatarUrl,
    required this.radius,
    required this.theme,
    this.backgroundColor,
    this.id,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final hasUrl = avatarUrl != null && avatarUrl!.isNotEmpty;

    if (hasUrl) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Builder(
            builder: (context) {
              final pixelSize =
                  (size * MediaQuery.devicePixelRatioOf(context)).round();
              return Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                cacheHeight: pixelSize,
                cacheWidth: pixelSize,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _buildInitialAvatar(),
              );
            },
          ),
        ),
      );
    }

    return _buildInitialAvatar();
  }

  Widget _buildInitialAvatar() {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final effectiveFontSize = fontSize ?? radius * 0.75;
    final hashSource = id ?? displayName;
    final colorIndex = hashSource.hashCode.abs() % avatarColors.length;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? avatarColors[colorIndex],
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: effectiveFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Palette used for initial-letter avatars.
  static const avatarColors = [
    Color(0xFF1ABC9C),
    Color(0xFF2ECC71),
    Color(0xFF3498DB),
    Color(0xFF9B59B6),
    Color(0xFFE67E22),
    Color(0xFFE74C3C),
    Color(0xFF16A085),
    Color(0xFFF39C12),
  ];
}
