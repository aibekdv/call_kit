/// Size tokens for a single participant tile.
library;

import 'package:flutter/foundation.dart';

/// The metrics of the tile that shows one participant's video or avatar,
/// together with the name, mute, signal and screen-share overlays.
///
/// Every field defaults to the kit's original value, so
/// `const CallParticipantTileDimensions()` reproduces the layout the package
/// shipped before sizes became configurable. All of them are multiplied by
/// `CallDimensions.scale` except [speakingBorderWidth] — see its doc.
@immutable
class CallParticipantTileDimensions {
  /// Padding around the avatar fallback shown when there is no video.
  final double padding;

  /// Radius of that avatar.
  final double avatarRadius;

  /// Gap between the avatar and the name below it.
  final double avatarNameGap;

  /// Font size of the participant name, in both the fallback and the overlay.
  final double nameFontSize;

  /// Height of the scrim behind the name overlay.
  final double gradientHeight;

  /// Inset of the overlays from the tile's edges.
  final double overlayInset;

  /// Right inset of the name row when the mute badge is showing, so the two
  /// do not collide.
  final double mutedRightInset;

  /// Gap between the name and the speaking indicator.
  final double nameIndicatorGap;

  /// Tallest a speaking bar grows to.
  final double speakingMaxHeight;

  /// Shortest a speaking bar shrinks to.
  final double speakingMinHeight;

  /// Width of one speaking bar.
  final double speakingBarWidth;

  /// Gap between two speaking bars.
  final double speakingBarGap;

  /// Width of the animated border drawn around an active speaker.
  ///
  /// **Not scaled.** Like the picture-in-picture frame, this is a hairline:
  /// growing it with the rest of the UI would read as a heavier border rather
  /// than a bigger one.
  final double speakingBorderWidth;

  /// Glyph size of the mute badge.
  final double micOffIconSize;

  /// Glyph size of the signal-strength icon.
  final double signalIconSize;

  /// Inset of the signal-strength icon from the top-left corner.
  final double signalInset;

  /// Glyph size of the screen-share badge.
  final double screenShareIconSize;

  /// Creates the tile metrics, each defaulting to the kit's original value.
  const CallParticipantTileDimensions({
    this.padding = 4,
    this.avatarRadius = 24,
    this.avatarNameGap = 6,
    this.nameFontSize = 11,
    this.gradientHeight = 60,
    this.overlayInset = 8,
    this.mutedRightInset = 28,
    this.nameIndicatorGap = 4,
    this.speakingMaxHeight = 12,
    this.speakingMinHeight = 3,
    this.speakingBarWidth = 2.5,
    this.speakingBarGap = 2,
    this.speakingBorderWidth = 2.5,
    this.micOffIconSize = 14,
    this.signalIconSize = 12,
    this.signalInset = 6,
    this.screenShareIconSize = 14,
  });

  /// Returns a copy of these metrics with the given fields replaced.
  CallParticipantTileDimensions copyWith({
    double? padding,
    double? avatarRadius,
    double? avatarNameGap,
    double? nameFontSize,
    double? gradientHeight,
    double? overlayInset,
    double? mutedRightInset,
    double? nameIndicatorGap,
    double? speakingMaxHeight,
    double? speakingMinHeight,
    double? speakingBarWidth,
    double? speakingBarGap,
    double? speakingBorderWidth,
    double? micOffIconSize,
    double? signalIconSize,
    double? signalInset,
    double? screenShareIconSize,
  }) {
    return CallParticipantTileDimensions(
      padding: padding ?? this.padding,
      avatarRadius: avatarRadius ?? this.avatarRadius,
      avatarNameGap: avatarNameGap ?? this.avatarNameGap,
      nameFontSize: nameFontSize ?? this.nameFontSize,
      gradientHeight: gradientHeight ?? this.gradientHeight,
      overlayInset: overlayInset ?? this.overlayInset,
      mutedRightInset: mutedRightInset ?? this.mutedRightInset,
      nameIndicatorGap: nameIndicatorGap ?? this.nameIndicatorGap,
      speakingMaxHeight: speakingMaxHeight ?? this.speakingMaxHeight,
      speakingMinHeight: speakingMinHeight ?? this.speakingMinHeight,
      speakingBarWidth: speakingBarWidth ?? this.speakingBarWidth,
      speakingBarGap: speakingBarGap ?? this.speakingBarGap,
      speakingBorderWidth: speakingBorderWidth ?? this.speakingBorderWidth,
      micOffIconSize: micOffIconSize ?? this.micOffIconSize,
      signalIconSize: signalIconSize ?? this.signalIconSize,
      signalInset: signalInset ?? this.signalInset,
      screenShareIconSize: screenShareIconSize ?? this.screenShareIconSize,
    );
  }

  List<Object?> get _props => [
        padding,
        avatarRadius,
        avatarNameGap,
        nameFontSize,
        gradientHeight,
        overlayInset,
        mutedRightInset,
        nameIndicatorGap,
        speakingMaxHeight,
        speakingMinHeight,
        speakingBarWidth,
        speakingBarGap,
        speakingBorderWidth,
        micOffIconSize,
        signalIconSize,
        signalInset,
        screenShareIconSize,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallParticipantTileDimensions &&
          runtimeType == other.runtimeType &&
          listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() =>
      'CallParticipantTileDimensions(avatarRadius: $avatarRadius)';
}
