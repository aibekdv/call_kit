/// Right-side floating action buttons for the call screen.
library;

import 'package:flutter/material.dart';

import '../../models/call_strings.dart';
import '../../models/call_theme.dart';

/// A vertical column of floating action buttons shown on the right edge.
///
/// Each button is shown only when its corresponding callback is provided.
class CallRightButtons extends StatelessWidget {
  static const double _buttonSize = 48;
  static const double _spacing = 12;

  /// The height this column occupies for the given set of buttons.
  ///
  /// Used by [CallScreen] to keep the PiP clear of the side buttons.
  static double heightFor({required bool hasAdd, required bool hasEffects}) {
    var height = 0.0;
    if (hasAdd) height += _buttonSize;
    if (hasEffects) height += _buttonSize;
    if (hasAdd && hasEffects) height += _spacing;
    return height;
  }

  final CallTheme theme;
  final CallStrings strings;
  final VoidCallback? onAddParticipant;
  final VoidCallback? onEffects;
  final VoidCallback onResetHideTimer;

  const CallRightButtons({
    super.key,
    required this.theme,
    required this.strings,
    this.onAddParticipant,
    this.onEffects,
    required this.onResetHideTimer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onAddParticipant != null) ...[
          _buildSideButton(
            icon: Icons.person_add,
            onTap: onAddParticipant!,
            tooltip: strings.addParticipant,
          ),
          if (onEffects != null) const SizedBox(height: _spacing),
        ],
        if (onEffects != null)
          _buildSideButton(
            icon: Icons.auto_fix_high,
            onTap: onEffects!,
            tooltip: strings.effects,
          ),
      ],
    );
  }

  Widget _buildSideButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          onResetHideTimer();
          onTap();
        },
        child: Container(
          width: _buttonSize,
          height: _buttonSize,
          decoration: BoxDecoration(
            color: theme.buttonBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.textPrimary, size: 22),
        ),
      ),
    );
  }
}
