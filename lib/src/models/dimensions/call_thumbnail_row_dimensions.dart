/// Size tokens for the thumbnail strip shown under the speaker view.
library;

import 'package:flutter/foundation.dart';

/// The metrics of the horizontal row of participant thumbnails.
///
/// Every field defaults to the kit's original value, so
/// `const CallThumbnailRowDimensions()` reproduces the layout the package
/// shipped before sizes became configurable. All of them are multiplied by
/// `CallDimensions.scale`.
@immutable
class CallThumbnailRowDimensions {
  /// The height of the row.
  final double height;

  /// Padding around the scrollable list.
  final double padding;

  /// Width of a single thumbnail.
  final double tileWidth;

  /// Horizontal margin between two thumbnails.
  final double tileMargin;

  /// Corner radius of a thumbnail.
  final double tileRadius;

  /// Font size of the "+N" overflow label.
  final double moreFontSize;

  /// Creates the row metrics, each defaulting to the kit's original value.
  const CallThumbnailRowDimensions({
    this.height = 90,
    this.padding = 4,
    this.tileWidth = 70,
    this.tileMargin = 2,
    this.tileRadius = 8,
    this.moreFontSize = 12,
  });

  /// Returns a copy of these metrics with the given fields replaced.
  CallThumbnailRowDimensions copyWith({
    double? height,
    double? padding,
    double? tileWidth,
    double? tileMargin,
    double? tileRadius,
    double? moreFontSize,
  }) {
    return CallThumbnailRowDimensions(
      height: height ?? this.height,
      padding: padding ?? this.padding,
      tileWidth: tileWidth ?? this.tileWidth,
      tileMargin: tileMargin ?? this.tileMargin,
      tileRadius: tileRadius ?? this.tileRadius,
      moreFontSize: moreFontSize ?? this.moreFontSize,
    );
  }

  List<Object?> get _props => [
        height,
        padding,
        tileWidth,
        tileMargin,
        tileRadius,
        moreFontSize,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallThumbnailRowDimensions &&
          runtimeType == other.runtimeType &&
          listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() =>
      'CallThumbnailRowDimensions(height: $height, tileWidth: $tileWidth)';
}
