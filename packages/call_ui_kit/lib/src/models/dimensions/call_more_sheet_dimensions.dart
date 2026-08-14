/// Size tokens for the "more options" bottom sheet.
library;

import 'package:flutter/foundation.dart';

/// The metrics of the sheet raised by the bottom bar's "more" button.
///
/// Every field defaults to the kit's original value, so
/// `const CallMoreSheetDimensions()` reproduces the layout the package shipped
/// before sizes became configurable. All of them are multiplied by
/// `CallDimensions.scale`.
@immutable
class CallMoreSheetDimensions {
  /// Corner radius of the sheet's top edge.
  final double radius;

  /// Padding added below the sheet's content, on top of the safe area.
  final double bottomPadding;

  /// Glyph size of the encryption lock.
  final double lockIconSize;

  /// Gap between that lock and its label.
  final double lockGap;

  /// Font size of the encryption label.
  final double encryptionFontSize;

  /// Gap above and below the host-supplied content.
  final double sectionGap;

  /// Horizontal margin of the cancel button.
  final double cancelMargin;

  /// Corner radius of the cancel button.
  final double cancelRadius;

  /// Font size of the cancel button's label.
  final double cancelFontSize;

  /// Creates the sheet metrics, each defaulting to the kit's original value.
  const CallMoreSheetDimensions({
    this.radius = 16,
    this.bottomPadding = 16,
    this.lockIconSize = 14,
    this.lockGap = 6,
    this.encryptionFontSize = 13,
    this.sectionGap = 12,
    this.cancelMargin = 16,
    this.cancelRadius = 12,
    this.cancelFontSize = 16,
  });

  /// Returns a copy of these metrics with the given fields replaced.
  CallMoreSheetDimensions copyWith({
    double? radius,
    double? bottomPadding,
    double? lockIconSize,
    double? lockGap,
    double? encryptionFontSize,
    double? sectionGap,
    double? cancelMargin,
    double? cancelRadius,
    double? cancelFontSize,
  }) {
    return CallMoreSheetDimensions(
      radius: radius ?? this.radius,
      bottomPadding: bottomPadding ?? this.bottomPadding,
      lockIconSize: lockIconSize ?? this.lockIconSize,
      lockGap: lockGap ?? this.lockGap,
      encryptionFontSize: encryptionFontSize ?? this.encryptionFontSize,
      sectionGap: sectionGap ?? this.sectionGap,
      cancelMargin: cancelMargin ?? this.cancelMargin,
      cancelRadius: cancelRadius ?? this.cancelRadius,
      cancelFontSize: cancelFontSize ?? this.cancelFontSize,
    );
  }

  List<Object?> get _props => [
        radius,
        bottomPadding,
        lockIconSize,
        lockGap,
        encryptionFontSize,
        sectionGap,
        cancelMargin,
        cancelRadius,
        cancelFontSize,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallMoreSheetDimensions &&
          runtimeType == other.runtimeType &&
          listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() => 'CallMoreSheetDimensions(radius: $radius)';
}
