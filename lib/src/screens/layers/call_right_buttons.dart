/// Right-side floating action buttons for the call screen.
library;

import 'package:flutter/material.dart';

import '../../models/call_dimensions.dart';
import '../../models/call_strings.dart';
import '../../models/call_theme.dart';

/// A vertical column of floating action buttons shown on the right edge.
///
/// Each button is shown only when its corresponding callback is provided.
class CallRightButtons extends StatelessWidget {
  /// The height this column occupies for the given set of buttons.
  ///
  /// Kept for the layer's own use; hosts reach the same number through
  /// [CallDimensions.rightButtonsHeight], which they can import.
  static double heightFor({
    required bool hasAdd,
    required bool hasEffects,
    CallDimensions dimensions = const CallDimensions(),
  }) =>
      dimensions.rightButtonsHeight(hasAdd: hasAdd, hasEffects: hasEffects);

  final CallTheme theme;
  final CallDimensions dimensions;
  final CallStrings strings;
  final VoidCallback? onAddParticipant;
  final VoidCallback? onEffects;
  final VoidCallback onResetHideTimer;

  const CallRightButtons({
    super.key,
    required this.theme,
    this.dimensions = const CallDimensions(),
    required this.strings,
    this.onAddParticipant,
    this.onEffects,
    required this.onResetHideTimer,
  });

  @override
  Widget build(BuildContext context) {
    final d = dimensions.rightButtons;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onAddParticipant != null) ...[
          _buildSideButton(
            icon: Icons.person_add,
            onTap: onAddParticipant!,
            tooltip: strings.addParticipant,
          ),
          if (onEffects != null) SizedBox(height: dimensions.scaled(d.spacing)),
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
          width: dimensions.scaled(dimensions.rightButtons.buttonSize),
          height: dimensions.scaled(dimensions.rightButtons.buttonSize),
          decoration: BoxDecoration(
            color: theme.buttonBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: theme.textPrimary,
            size: dimensions.scaled(dimensions.rightButtons.iconSize),
          ),
        ),
      ),
    );
  }
}
