/// Size tokens for the call screen's video area.
library;

import 'package:flutter/foundation.dart';

/// The metrics of the area below the bars: the personal-call avatar, the
/// "you are sharing your screen" panel, and the grid gutters.
///
/// Every field defaults to the kit's original value, so
/// `const CallVideoContentDimensions()` reproduces the layout the package
/// shipped before sizes became configurable. All of them are multiplied by
/// `CallDimensions.scale` except [personalAvatarFontRatio] and [gridGutter] —
/// see their docs.
@immutable
class CallVideoContentDimensions {
  /// Radius of the avatar shown on a personal call with no video.
  final double personalAvatarRadius;

  /// Gap between that avatar and the name below it.
  final double personalAvatarNameGap;

  /// Font size of that name.
  final double personalNameFontSize;

  /// The initial's font size as a fraction of the avatar's diameter.
  ///
  /// **Not scaled.** It is a ratio, not a size — the avatar it multiplies is
  /// already scaled.
  final double personalAvatarFontRatio;

  /// Glyph size of the screen-share icon on the sharing panel.
  final double sharingIconSize;

  /// Gap between that icon and the label below it.
  final double sharingIconGap;

  /// Font size of the sharing label.
  final double sharingLabelFontSize;

  /// Gap between the label and the stop button.
  final double sharingLabelButtonGap;

  /// Horizontal padding of the stop button.
  final double sharingStopHorizontal;

  /// Vertical padding of the stop button.
  final double sharingStopVertical;

  /// Corner radius of the stop button.
  final double sharingStopRadius;

  /// Font size of the stop button's label.
  final double sharingStopFontSize;

  /// Separator between two tiles in a group grid.
  ///
  /// **Not scaled.** It is a hairline: it stays one logical pixel however
  /// large the tiles grow.
  final double gridGutter;

  /// Creates the video-area metrics, each defaulting to the kit's original
  /// value.
  const CallVideoContentDimensions({
    this.personalAvatarRadius = 40,
    this.personalAvatarNameGap = 12,
    this.personalNameFontSize = 20,
    this.personalAvatarFontRatio = 0.35,
    this.sharingIconSize = 48,
    this.sharingIconGap = 16,
    this.sharingLabelFontSize = 16,
    this.sharingLabelButtonGap = 24,
    this.sharingStopHorizontal = 24,
    this.sharingStopVertical = 10,
    this.sharingStopRadius = 24,
    this.sharingStopFontSize = 14,
    this.gridGutter = 1,
  });

  /// Returns a copy of these metrics with the given fields replaced.
  CallVideoContentDimensions copyWith({
    double? personalAvatarRadius,
    double? personalAvatarNameGap,
    double? personalNameFontSize,
    double? personalAvatarFontRatio,
    double? sharingIconSize,
    double? sharingIconGap,
    double? sharingLabelFontSize,
    double? sharingLabelButtonGap,
    double? sharingStopHorizontal,
    double? sharingStopVertical,
    double? sharingStopRadius,
    double? sharingStopFontSize,
    double? gridGutter,
  }) {
    return CallVideoContentDimensions(
      personalAvatarRadius: personalAvatarRadius ?? this.personalAvatarRadius,
      personalAvatarNameGap:
          personalAvatarNameGap ?? this.personalAvatarNameGap,
      personalNameFontSize: personalNameFontSize ?? this.personalNameFontSize,
      personalAvatarFontRatio:
          personalAvatarFontRatio ?? this.personalAvatarFontRatio,
      sharingIconSize: sharingIconSize ?? this.sharingIconSize,
      sharingIconGap: sharingIconGap ?? this.sharingIconGap,
      sharingLabelFontSize: sharingLabelFontSize ?? this.sharingLabelFontSize,
      sharingLabelButtonGap:
          sharingLabelButtonGap ?? this.sharingLabelButtonGap,
      sharingStopHorizontal:
          sharingStopHorizontal ?? this.sharingStopHorizontal,
      sharingStopVertical: sharingStopVertical ?? this.sharingStopVertical,
      sharingStopRadius: sharingStopRadius ?? this.sharingStopRadius,
      sharingStopFontSize: sharingStopFontSize ?? this.sharingStopFontSize,
      gridGutter: gridGutter ?? this.gridGutter,
    );
  }

  List<Object?> get _props => [
        personalAvatarRadius,
        personalAvatarNameGap,
        personalNameFontSize,
        personalAvatarFontRatio,
        sharingIconSize,
        sharingIconGap,
        sharingLabelFontSize,
        sharingLabelButtonGap,
        sharingStopHorizontal,
        sharingStopVertical,
        sharingStopRadius,
        sharingStopFontSize,
        gridGutter,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallVideoContentDimensions &&
          runtimeType == other.runtimeType &&
          listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() =>
      'CallVideoContentDimensions(personalAvatarRadius: $personalAvatarRadius)';
}
