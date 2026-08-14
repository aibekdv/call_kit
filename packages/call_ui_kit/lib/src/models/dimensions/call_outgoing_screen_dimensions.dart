/// Size tokens for the outgoing call screen.
library;

import 'package:flutter/foundation.dart';

/// The metrics of the screen shown while a call is being placed.
///
/// Every field defaults to the kit's original value, so
/// `const CallOutgoingScreenDimensions()` reproduces the layout the package
/// shipped before sizes became configurable. All of them are multiplied by
/// `CallDimensions.scale`.
@immutable
class CallOutgoingScreenDimensions {
  /// Padding around the minimize chevron.
  final double minimizePadding;

  /// Glyph size of the minimize chevron.
  final double minimizeIconSize;

  /// Radius of the callee's avatar.
  final double avatarRadius;

  /// Gap between the avatar and the callee name.
  final double avatarNameGap;

  /// Font size of the callee name.
  final double nameFontSize;

  /// Gap between the name and the status line.
  final double nameStatusGap;

  /// Font size of the status line.
  final double statusFontSize;

  /// Gap between the controls row and the bottom screen edge.
  final double bottomInset;

  /// Diameter of the end-call button.
  final double endCallSize;

  /// Glyph size inside the end-call button.
  final double endCallIconSize;

  /// Diameter of the mute and speaker toggles.
  final double toggleSize;

  /// Glyph size inside those toggles.
  final double toggleIconSize;

  /// Creates the screen metrics, each defaulting to the kit's original value.
  const CallOutgoingScreenDimensions({
    this.minimizePadding = 12,
    this.minimizeIconSize = 28,
    this.avatarRadius = 50,
    this.avatarNameGap = 16,
    this.nameFontSize = 24,
    this.nameStatusGap = 8,
    this.statusFontSize = 15,
    this.bottomInset = 48,
    this.endCallSize = 50,
    this.endCallIconSize = 22,
    this.toggleSize = 50,
    this.toggleIconSize = 22,
  });

  /// Returns a copy of these metrics with the given fields replaced.
  CallOutgoingScreenDimensions copyWith({
    double? minimizePadding,
    double? minimizeIconSize,
    double? avatarRadius,
    double? avatarNameGap,
    double? nameFontSize,
    double? nameStatusGap,
    double? statusFontSize,
    double? bottomInset,
    double? endCallSize,
    double? endCallIconSize,
    double? toggleSize,
    double? toggleIconSize,
  }) {
    return CallOutgoingScreenDimensions(
      minimizePadding: minimizePadding ?? this.minimizePadding,
      minimizeIconSize: minimizeIconSize ?? this.minimizeIconSize,
      avatarRadius: avatarRadius ?? this.avatarRadius,
      avatarNameGap: avatarNameGap ?? this.avatarNameGap,
      nameFontSize: nameFontSize ?? this.nameFontSize,
      nameStatusGap: nameStatusGap ?? this.nameStatusGap,
      statusFontSize: statusFontSize ?? this.statusFontSize,
      bottomInset: bottomInset ?? this.bottomInset,
      endCallSize: endCallSize ?? this.endCallSize,
      endCallIconSize: endCallIconSize ?? this.endCallIconSize,
      toggleSize: toggleSize ?? this.toggleSize,
      toggleIconSize: toggleIconSize ?? this.toggleIconSize,
    );
  }

  List<Object?> get _props => [
        minimizePadding,
        minimizeIconSize,
        avatarRadius,
        avatarNameGap,
        nameFontSize,
        nameStatusGap,
        statusFontSize,
        bottomInset,
        endCallSize,
        endCallIconSize,
        toggleSize,
        toggleIconSize,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallOutgoingScreenDimensions &&
          runtimeType == other.runtimeType &&
          listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() =>
      'CallOutgoingScreenDimensions(endCallSize: $endCallSize)';
}
