/// Size tokens for the incoming call screen.
library;

import 'package:flutter/foundation.dart';

/// The metrics of the screen that announces an incoming call and offers to
/// accept or decline it.
///
/// Every field defaults to the kit's original value, so
/// `const CallIncomingScreenDimensions()` reproduces the layout the package
/// shipped before sizes became configurable. All of them are multiplied by
/// `CallDimensions.scale`.
@immutable
class CallIncomingScreenDimensions {
  /// Radius of the caller's avatar.
  final double avatarRadius;

  /// Gap between the avatar and the caller name.
  final double avatarNameGap;

  /// Font size of the caller name.
  final double nameFontSize;

  /// Gap between the name and the status line.
  final double nameStatusGap;

  /// Font size of the status line.
  final double statusFontSize;

  /// Gap between the action row and the bottom screen edge.
  final double bottomInset;

  /// Diameter of the accept and decline buttons.
  final double actionButtonSize;

  /// Glyph size inside those buttons.
  final double actionIconSize;

  /// Gap between a button and its label.
  final double actionLabelGap;

  /// Font size of a button's label.
  final double actionLabelFontSize;

  /// Creates the screen metrics, each defaulting to the kit's original value.
  const CallIncomingScreenDimensions({
    this.avatarRadius = 50,
    this.avatarNameGap = 16,
    this.nameFontSize = 24,
    this.nameStatusGap = 8,
    this.statusFontSize = 15,
    this.bottomInset = 48,
    this.actionButtonSize = 64,
    this.actionIconSize = 28,
    this.actionLabelGap = 8,
    this.actionLabelFontSize = 13,
  });

  /// Returns a copy of these metrics with the given fields replaced.
  CallIncomingScreenDimensions copyWith({
    double? avatarRadius,
    double? avatarNameGap,
    double? nameFontSize,
    double? nameStatusGap,
    double? statusFontSize,
    double? bottomInset,
    double? actionButtonSize,
    double? actionIconSize,
    double? actionLabelGap,
    double? actionLabelFontSize,
  }) {
    return CallIncomingScreenDimensions(
      avatarRadius: avatarRadius ?? this.avatarRadius,
      avatarNameGap: avatarNameGap ?? this.avatarNameGap,
      nameFontSize: nameFontSize ?? this.nameFontSize,
      nameStatusGap: nameStatusGap ?? this.nameStatusGap,
      statusFontSize: statusFontSize ?? this.statusFontSize,
      bottomInset: bottomInset ?? this.bottomInset,
      actionButtonSize: actionButtonSize ?? this.actionButtonSize,
      actionIconSize: actionIconSize ?? this.actionIconSize,
      actionLabelGap: actionLabelGap ?? this.actionLabelGap,
      actionLabelFontSize: actionLabelFontSize ?? this.actionLabelFontSize,
    );
  }

  List<Object?> get _props => [
        avatarRadius,
        avatarNameGap,
        nameFontSize,
        nameStatusGap,
        statusFontSize,
        bottomInset,
        actionButtonSize,
        actionIconSize,
        actionLabelGap,
        actionLabelFontSize,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallIncomingScreenDimensions &&
          runtimeType == other.runtimeType &&
          listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() =>
      'CallIncomingScreenDimensions(actionButtonSize: $actionButtonSize)';
}
