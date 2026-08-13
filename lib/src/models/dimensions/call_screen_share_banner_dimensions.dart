/// Size tokens for the screen-share banner.
library;

import 'package:flutter/foundation.dart';

/// The metrics of the strip that reports an active screen share and offers to
/// stop it.
///
/// Every field defaults to the kit's original value, so
/// `const CallScreenShareBannerDimensions()` reproduces the layout the package
/// shipped before sizes became configurable. All of them are multiplied by
/// `CallDimensions.scale`.
@immutable
class CallScreenShareBannerDimensions {
  /// The height of the banner.
  final double height;

  /// Horizontal padding inside the banner.
  final double horizontalPadding;

  /// Glyph size of the screen-share icon.
  final double iconSize;

  /// Gap between the icon and the text.
  final double iconGap;

  /// Font size of the banner text.
  final double fontSize;

  /// Horizontal padding of the "stop" chip.
  final double stopHorizontal;

  /// Vertical padding of the "stop" chip.
  final double stopVertical;

  /// Corner radius of the "stop" chip.
  final double stopRadius;

  /// Font size of the "stop" chip label.
  final double stopFontSize;

  /// Creates the banner metrics, each defaulting to the kit's original value.
  const CallScreenShareBannerDimensions({
    this.height = 36,
    this.horizontalPadding = 12,
    this.iconSize = 14,
    this.iconGap = 8,
    this.fontSize = 12,
    this.stopHorizontal = 10,
    this.stopVertical = 3,
    this.stopRadius = 4,
    this.stopFontSize = 11,
  });

  /// Returns a copy of these metrics with the given fields replaced.
  CallScreenShareBannerDimensions copyWith({
    double? height,
    double? horizontalPadding,
    double? iconSize,
    double? iconGap,
    double? fontSize,
    double? stopHorizontal,
    double? stopVertical,
    double? stopRadius,
    double? stopFontSize,
  }) {
    return CallScreenShareBannerDimensions(
      height: height ?? this.height,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      iconSize: iconSize ?? this.iconSize,
      iconGap: iconGap ?? this.iconGap,
      fontSize: fontSize ?? this.fontSize,
      stopHorizontal: stopHorizontal ?? this.stopHorizontal,
      stopVertical: stopVertical ?? this.stopVertical,
      stopRadius: stopRadius ?? this.stopRadius,
      stopFontSize: stopFontSize ?? this.stopFontSize,
    );
  }

  List<Object?> get _props => [
        height,
        horizontalPadding,
        iconSize,
        iconGap,
        fontSize,
        stopHorizontal,
        stopVertical,
        stopRadius,
        stopFontSize,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallScreenShareBannerDimensions &&
          runtimeType == other.runtimeType &&
          listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() => 'CallScreenShareBannerDimensions(height: $height)';
}
