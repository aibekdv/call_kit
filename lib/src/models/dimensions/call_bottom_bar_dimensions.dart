/// Size tokens for the call screen's bottom controls bar.
library;

import 'package:flutter/foundation.dart';

/// The metrics of the pill-shaped bar carrying mute, camera, speaker,
/// screen-share, more and end-call.
///
/// Every field defaults to the kit's original value, so
/// `const CallBottomBarDimensions()` reproduces the layout the package shipped
/// before sizes became configurable. All of them are multiplied by
/// `CallDimensions.scale`.
///
/// The bar's overall height is not a field — it is composed from
/// [bottomInset], [verticalPadding] and [endCallButtonSize] by
/// `CallDimensions.bottomBarHeight`, so it cannot drift when these change.
@immutable
class CallBottomBarDimensions {
  /// Diameter of a standard control button.
  final double buttonSize;

  /// Diameter of the end-call button, the largest in the bar.
  final double endCallButtonSize;

  /// Glyph size inside a standard control button.
  final double iconSize;

  /// Glyph size inside the end-call button.
  final double endCallIconSize;

  /// Gap between the bar and the left and right screen edges.
  final double horizontalInset;

  /// Horizontal padding inside the pill, before the first button.
  final double innerHorizontal;

  /// Vertical padding inside the pill, above and below the buttons.
  final double verticalPadding;

  /// Gap between the bar and the bottom screen edge, excluding safe area.
  final double bottomInset;

  /// Corner radius of the pill.
  final double barRadius;

  /// Creates the bottom bar metrics, each defaulting to the kit's original
  /// value.
  const CallBottomBarDimensions({
    this.buttonSize = 50,
    this.endCallButtonSize = 58,
    this.iconSize = 22,
    this.endCallIconSize = 26,
    this.horizontalInset = 12,
    this.innerHorizontal = 8,
    this.verticalPadding = 12,
    this.bottomInset = 20,
    this.barRadius = 40,
  });

  /// Returns a copy of these metrics with the given fields replaced.
  CallBottomBarDimensions copyWith({
    double? buttonSize,
    double? endCallButtonSize,
    double? iconSize,
    double? endCallIconSize,
    double? horizontalInset,
    double? innerHorizontal,
    double? verticalPadding,
    double? bottomInset,
    double? barRadius,
  }) {
    return CallBottomBarDimensions(
      buttonSize: buttonSize ?? this.buttonSize,
      endCallButtonSize: endCallButtonSize ?? this.endCallButtonSize,
      iconSize: iconSize ?? this.iconSize,
      endCallIconSize: endCallIconSize ?? this.endCallIconSize,
      horizontalInset: horizontalInset ?? this.horizontalInset,
      innerHorizontal: innerHorizontal ?? this.innerHorizontal,
      verticalPadding: verticalPadding ?? this.verticalPadding,
      bottomInset: bottomInset ?? this.bottomInset,
      barRadius: barRadius ?? this.barRadius,
    );
  }

  List<Object?> get _props => [
        buttonSize,
        endCallButtonSize,
        iconSize,
        endCallIconSize,
        horizontalInset,
        innerHorizontal,
        verticalPadding,
        bottomInset,
        barRadius,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallBottomBarDimensions &&
          runtimeType == other.runtimeType &&
          listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() => 'CallBottomBarDimensions(buttonSize: $buttonSize, '
      'endCallButtonSize: $endCallButtonSize)';
}
