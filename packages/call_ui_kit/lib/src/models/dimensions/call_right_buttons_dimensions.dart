/// Size tokens for the call screen's side button column.
library;

import 'package:flutter/foundation.dart';

/// The metrics of the add-participant and effects buttons stacked against the
/// right edge of the call screen.
///
/// Every field defaults to the kit's original value, so
/// `const CallRightButtonsDimensions()` reproduces the layout the package
/// shipped before sizes became configurable. All of them are multiplied by
/// `CallDimensions.scale`.
///
/// The column's overall height depends on which buttons are present; ask
/// `CallDimensions.rightButtonsHeight` for it.
@immutable
class CallRightButtonsDimensions {
  /// Diameter of a side button.
  final double buttonSize;

  /// Vertical gap between two side buttons.
  final double spacing;

  /// Glyph size inside a side button.
  final double iconSize;

  /// Vertical gap between the top bar and the first side button.
  final double gapFromTopBar;

  /// Gap between the column and the right screen edge.
  final double insetFromEdge;

  /// Creates the side button metrics, each defaulting to the kit's original
  /// value.
  const CallRightButtonsDimensions({
    this.buttonSize = 48,
    this.spacing = 12,
    this.iconSize = 22,
    this.gapFromTopBar = 20,
    this.insetFromEdge = 12,
  });

  /// Returns a copy of these metrics with the given fields replaced.
  CallRightButtonsDimensions copyWith({
    double? buttonSize,
    double? spacing,
    double? iconSize,
    double? gapFromTopBar,
    double? insetFromEdge,
  }) {
    return CallRightButtonsDimensions(
      buttonSize: buttonSize ?? this.buttonSize,
      spacing: spacing ?? this.spacing,
      iconSize: iconSize ?? this.iconSize,
      gapFromTopBar: gapFromTopBar ?? this.gapFromTopBar,
      insetFromEdge: insetFromEdge ?? this.insetFromEdge,
    );
  }

  List<Object?> get _props => [
        buttonSize,
        spacing,
        iconSize,
        gapFromTopBar,
        insetFromEdge,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallRightButtonsDimensions &&
          runtimeType == other.runtimeType &&
          listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() => 'CallRightButtonsDimensions(buttonSize: $buttonSize)';
}
