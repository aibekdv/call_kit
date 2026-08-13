/// Size tokens for the floating picture-in-picture view.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The metrics of the draggable self-view that snaps to the screen corners.
///
/// Every field defaults to the kit's original value, so
/// `const CallPipDimensions()` reproduces the layout the package shipped before
/// sizes became configurable. All of them are multiplied by
/// `CallDimensions.scale` except [borderWidth] — see its doc.
@immutable
class CallPipDimensions {
  /// The frame's width and height.
  final Size size;

  /// Gap kept between the frame and the screen edges, and between the frame
  /// and the areas reserved for the bars.
  final double margin;

  /// Corner radius of the frame.
  final double borderRadius;

  /// Width of the frame's outline.
  ///
  /// **Not scaled.** A hairline should stay a hairline: growing it with the
  /// rest of the UI would read as a heavier border, not a bigger one. It also
  /// sets the inner clip radius, which is [borderRadius] minus this value.
  final double borderWidth;

  /// Radius of the avatar shown when the camera is off.
  final double avatarRadius;

  /// Font size of the initial inside that avatar.
  final double initialFontSize;

  /// Gap between the avatar and the label below it.
  final double labelGap;

  /// Font size of the label.
  final double labelFontSize;

  /// Creates the picture-in-picture metrics, each defaulting to the kit's
  /// original value.
  const CallPipDimensions({
    this.size = const Size(90, 120),
    this.margin = 16,
    this.borderRadius = 12,
    this.borderWidth = 1.5,
    this.avatarRadius = 20,
    this.initialFontSize = 14,
    this.labelGap = 4,
    this.labelFontSize = 10,
  });

  /// Returns a copy of these metrics with the given fields replaced.
  CallPipDimensions copyWith({
    Size? size,
    double? margin,
    double? borderRadius,
    double? borderWidth,
    double? avatarRadius,
    double? initialFontSize,
    double? labelGap,
    double? labelFontSize,
  }) {
    return CallPipDimensions(
      size: size ?? this.size,
      margin: margin ?? this.margin,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      avatarRadius: avatarRadius ?? this.avatarRadius,
      initialFontSize: initialFontSize ?? this.initialFontSize,
      labelGap: labelGap ?? this.labelGap,
      labelFontSize: labelFontSize ?? this.labelFontSize,
    );
  }

  List<Object?> get _props => [
        size,
        margin,
        borderRadius,
        borderWidth,
        avatarRadius,
        initialFontSize,
        labelGap,
        labelFontSize,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallPipDimensions &&
          runtimeType == other.runtimeType &&
          listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() => 'CallPipDimensions(size: $size, margin: $margin)';
}
