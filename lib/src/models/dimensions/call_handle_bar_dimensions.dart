/// Size tokens for the drag handle shown at the top of a bottom sheet.
library;

import 'package:flutter/foundation.dart';

/// The metrics of the rounded handle that marks a bottom sheet as draggable.
///
/// Every field defaults to the kit's original value, so
/// `const CallHandleBarDimensions()` reproduces the layout the package shipped
/// before sizes became configurable. All of them are multiplied by
/// `CallDimensions.scale`.
@immutable
class CallHandleBarDimensions {
  /// Width of the handle.
  final double width;

  /// Thickness of the handle. Its corner radius is half this value, so the
  /// ends stay fully rounded at any size.
  final double height;

  /// Default vertical margin above and below the handle.
  final double verticalMargin;

  /// Creates the handle metrics, each defaulting to the kit's original value.
  const CallHandleBarDimensions({
    this.width = 36,
    this.height = 4,
    this.verticalMargin = 10,
  });

  /// Returns a copy of these metrics with the given fields replaced.
  CallHandleBarDimensions copyWith({
    double? width,
    double? height,
    double? verticalMargin,
  }) {
    return CallHandleBarDimensions(
      width: width ?? this.width,
      height: height ?? this.height,
      verticalMargin: verticalMargin ?? this.verticalMargin,
    );
  }

  List<Object?> get _props => [width, height, verticalMargin];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallHandleBarDimensions &&
          runtimeType == other.runtimeType &&
          listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() =>
      'CallHandleBarDimensions(width: $width, height: $height)';
}
