/// Size tokens for the participants panel.
library;

import 'package:flutter/foundation.dart';

/// The metrics of the draggable sheet listing everyone on the call, its invite
/// button, and the host-action sheet raised from a row.
///
/// Every field defaults to the kit's original value, so
/// `const CallParticipantsPanelDimensions()` reproduces the layout the package
/// shipped before sizes became configurable. All of them are multiplied by
/// `CallDimensions.scale`.
@immutable
class CallParticipantsPanelDimensions {
  /// Corner radius of the sheet's top edge.
  final double radius;

  /// Padding added below the sheet's content, on top of the safe area.
  final double bottomPadding;

  /// Horizontal padding of the header row.
  final double headerHorizontal;

  /// Vertical padding of the header row.
  final double headerVertical;

  /// Font size of the "Participants (N)" title.
  final double titleFontSize;

  /// Font size of the "Mute all" action.
  final double muteAllFontSize;

  /// Glyph size of the close button.
  final double closeIconSize;

  /// Horizontal margin of the invite button.
  final double inviteHorizontal;

  /// Gap above the invite button.
  final double inviteTop;

  /// Height of the invite button.
  final double inviteButtonHeight;

  /// Glyph size inside the invite button.
  final double inviteIconSize;

  /// Corner radius of the invite button.
  final double inviteRadius;

  /// Height of one participant row.
  final double rowHeight;

  /// Horizontal padding of a participant row.
  final double rowHorizontal;

  /// Radius of a row's avatar.
  final double rowAvatarRadius;

  /// Font size of the initial inside that avatar.
  final double rowAvatarFontSize;

  /// Gap between the avatar and the name.
  final double rowAvatarGap;

  /// Font size of a row's participant name.
  final double rowNameFontSize;

  /// Font size of a row's status line.
  final double rowStatusFontSize;

  /// Glyph size of a row's mute and screen-share icons.
  final double rowIconSize;

  /// Glyph size of a row's host badge.
  final double rowHostIconSize;

  /// Gap between a row's trailing icons.
  final double rowIconGap;

  /// Gap above the host-action sheet's content.
  final double hostActionsTop;

  /// Gap between the host-action sheet's handle and its first tile.
  final double hostActionsHandleGap;

  /// Creates the panel metrics, each defaulting to the kit's original value.
  const CallParticipantsPanelDimensions({
    this.radius = 16,
    this.bottomPadding = 16,
    this.headerHorizontal = 16,
    this.headerVertical = 4,
    this.titleFontSize = 15,
    this.muteAllFontSize = 13,
    this.closeIconSize = 20,
    this.inviteHorizontal = 16,
    this.inviteTop = 8,
    this.inviteButtonHeight = 44,
    this.inviteIconSize = 20,
    this.inviteRadius = 22,
    this.rowHeight = 52,
    this.rowHorizontal = 16,
    this.rowAvatarRadius = 18,
    this.rowAvatarFontSize = 14,
    this.rowAvatarGap = 12,
    this.rowNameFontSize = 14,
    this.rowStatusFontSize = 11,
    this.rowIconSize = 18,
    this.rowHostIconSize = 16,
    this.rowIconGap = 8,
    this.hostActionsTop = 8,
    this.hostActionsHandleGap = 16,
  });

  /// Returns a copy of these metrics with the given fields replaced.
  CallParticipantsPanelDimensions copyWith({
    double? radius,
    double? bottomPadding,
    double? headerHorizontal,
    double? headerVertical,
    double? titleFontSize,
    double? muteAllFontSize,
    double? closeIconSize,
    double? inviteHorizontal,
    double? inviteTop,
    double? inviteButtonHeight,
    double? inviteIconSize,
    double? inviteRadius,
    double? rowHeight,
    double? rowHorizontal,
    double? rowAvatarRadius,
    double? rowAvatarFontSize,
    double? rowAvatarGap,
    double? rowNameFontSize,
    double? rowStatusFontSize,
    double? rowIconSize,
    double? rowHostIconSize,
    double? rowIconGap,
    double? hostActionsTop,
    double? hostActionsHandleGap,
  }) {
    return CallParticipantsPanelDimensions(
      radius: radius ?? this.radius,
      bottomPadding: bottomPadding ?? this.bottomPadding,
      headerHorizontal: headerHorizontal ?? this.headerHorizontal,
      headerVertical: headerVertical ?? this.headerVertical,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      muteAllFontSize: muteAllFontSize ?? this.muteAllFontSize,
      closeIconSize: closeIconSize ?? this.closeIconSize,
      inviteHorizontal: inviteHorizontal ?? this.inviteHorizontal,
      inviteTop: inviteTop ?? this.inviteTop,
      inviteButtonHeight: inviteButtonHeight ?? this.inviteButtonHeight,
      inviteIconSize: inviteIconSize ?? this.inviteIconSize,
      inviteRadius: inviteRadius ?? this.inviteRadius,
      rowHeight: rowHeight ?? this.rowHeight,
      rowHorizontal: rowHorizontal ?? this.rowHorizontal,
      rowAvatarRadius: rowAvatarRadius ?? this.rowAvatarRadius,
      rowAvatarFontSize: rowAvatarFontSize ?? this.rowAvatarFontSize,
      rowAvatarGap: rowAvatarGap ?? this.rowAvatarGap,
      rowNameFontSize: rowNameFontSize ?? this.rowNameFontSize,
      rowStatusFontSize: rowStatusFontSize ?? this.rowStatusFontSize,
      rowIconSize: rowIconSize ?? this.rowIconSize,
      rowHostIconSize: rowHostIconSize ?? this.rowHostIconSize,
      rowIconGap: rowIconGap ?? this.rowIconGap,
      hostActionsTop: hostActionsTop ?? this.hostActionsTop,
      hostActionsHandleGap: hostActionsHandleGap ?? this.hostActionsHandleGap,
    );
  }

  List<Object?> get _props => [
        radius,
        bottomPadding,
        headerHorizontal,
        headerVertical,
        titleFontSize,
        muteAllFontSize,
        closeIconSize,
        inviteHorizontal,
        inviteTop,
        inviteButtonHeight,
        inviteIconSize,
        inviteRadius,
        rowHeight,
        rowHorizontal,
        rowAvatarRadius,
        rowAvatarFontSize,
        rowAvatarGap,
        rowNameFontSize,
        rowStatusFontSize,
        rowIconSize,
        rowHostIconSize,
        rowIconGap,
        hostActionsTop,
        hostActionsHandleGap,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallParticipantsPanelDimensions &&
          runtimeType == other.runtimeType &&
          listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() => 'CallParticipantsPanelDimensions(rowHeight: $rowHeight)';
}
