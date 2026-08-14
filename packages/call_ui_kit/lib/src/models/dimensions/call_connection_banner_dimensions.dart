/// Size tokens for the connection-state banner.
library;

import 'package:flutter/foundation.dart';

/// The metrics of the strip that reports reconnecting and disconnected states.
///
/// Every field defaults to the kit's original value, so
/// `const CallConnectionBannerDimensions()` reproduces the layout the package
/// shipped before sizes became configurable. All of them are multiplied by
/// `CallDimensions.scale`.
@immutable
class CallConnectionBannerDimensions {
  /// The height of the banner.
  ///
  /// A host composing its own overlay reserves this much space; reach it
  /// through `CallDimensions.connectionBannerHeight`, which applies the scale.
  final double height;

  /// Horizontal padding inside the banner.
  final double horizontalPadding;

  /// Glyph size of the state icon.
  final double iconSize;

  /// Gap between the icon and the text.
  final double iconGap;

  /// Font size of the banner text.
  final double fontSize;

  /// Creates the banner metrics, each defaulting to the kit's original value.
  const CallConnectionBannerDimensions({
    this.height = 36,
    this.horizontalPadding = 12,
    this.iconSize = 14,
    this.iconGap = 8,
    this.fontSize = 12,
  });

  /// Returns a copy of these metrics with the given fields replaced.
  CallConnectionBannerDimensions copyWith({
    double? height,
    double? horizontalPadding,
    double? iconSize,
    double? iconGap,
    double? fontSize,
  }) {
    return CallConnectionBannerDimensions(
      height: height ?? this.height,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      iconSize: iconSize ?? this.iconSize,
      iconGap: iconGap ?? this.iconGap,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  List<Object?> get _props => [
        height,
        horizontalPadding,
        iconSize,
        iconGap,
        fontSize,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallConnectionBannerDimensions &&
          runtimeType == other.runtimeType &&
          listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() => 'CallConnectionBannerDimensions(height: $height)';
}
