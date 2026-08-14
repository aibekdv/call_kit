/// Size tokens for the call screen's top bar.
library;

import 'package:flutter/foundation.dart';

/// The metrics of the bar carrying the caller name, status and the
/// minimize/flip-camera actions.
///
/// Every field defaults to the kit's original value, so
/// `const CallTopBarDimensions()` reproduces the layout the package shipped
/// before sizes became configurable. All of them are multiplied by
/// `CallDimensions.scale`.
@immutable
class CallTopBarDimensions {
  /// The height of the bar, excluding any safe-area inset.
  ///
  /// A host composing its own overlay reserves this much space; reach it
  /// through `CallDimensions.topBarHeight`, which applies the scale.
  final double height;

  /// Diameter of the minimize chevron glyph.
  final double minimizeIconSize;

  /// Diameter of the flip-camera glyph.
  final double flipIconSize;

  /// Font size of the caller name.
  final double nameFontSize;

  /// Font size of the status line below the name.
  final double statusFontSize;

  /// Font size of the "N participants" label on a group call.
  final double countFontSize;

  /// Vertical gap between the name and the status line.
  final double nameGap;

  /// The smallest tap target for the bar's icon buttons.
  ///
  /// Defaults to Flutter's `kMinInteractiveDimension`. It follows the scale so
  /// the target keeps pace with the glyph — an `IconButton` would otherwise
  /// stay pinned at 48 px however large the icon grew.
  final double minTapTarget;

  /// Creates the top bar metrics, each defaulting to the kit's original value.
  const CallTopBarDimensions({
    this.height = 80,
    this.minimizeIconSize = 24,
    this.flipIconSize = 28,
    this.nameFontSize = 16,
    this.statusFontSize = 13,
    this.countFontSize = 11,
    this.nameGap = 2,
    this.minTapTarget = 48,
  });

  /// Returns a copy of these metrics with the given fields replaced.
  CallTopBarDimensions copyWith({
    double? height,
    double? minimizeIconSize,
    double? flipIconSize,
    double? nameFontSize,
    double? statusFontSize,
    double? countFontSize,
    double? nameGap,
    double? minTapTarget,
  }) {
    return CallTopBarDimensions(
      height: height ?? this.height,
      minimizeIconSize: minimizeIconSize ?? this.minimizeIconSize,
      flipIconSize: flipIconSize ?? this.flipIconSize,
      nameFontSize: nameFontSize ?? this.nameFontSize,
      statusFontSize: statusFontSize ?? this.statusFontSize,
      countFontSize: countFontSize ?? this.countFontSize,
      nameGap: nameGap ?? this.nameGap,
      minTapTarget: minTapTarget ?? this.minTapTarget,
    );
  }

  List<Object?> get _props => [
        height,
        minimizeIconSize,
        flipIconSize,
        nameFontSize,
        statusFontSize,
        countFontSize,
        nameGap,
        minTapTarget,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallTopBarDimensions &&
          runtimeType == other.runtimeType &&
          listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() => 'CallTopBarDimensions(height: $height)';
}
