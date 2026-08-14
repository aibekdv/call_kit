/// Size configuration for the call UI.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'dimensions/call_bottom_bar_dimensions.dart';
import 'dimensions/call_connection_banner_dimensions.dart';
import 'dimensions/call_handle_bar_dimensions.dart';
import 'dimensions/call_incoming_screen_dimensions.dart';
import 'dimensions/call_more_sheet_dimensions.dart';
import 'dimensions/call_outgoing_screen_dimensions.dart';
import 'dimensions/call_participant_tile_dimensions.dart';
import 'dimensions/call_participants_panel_dimensions.dart';
import 'dimensions/call_pip_dimensions.dart';
import 'dimensions/call_right_buttons_dimensions.dart';
import 'dimensions/call_screen_share_banner_dimensions.dart';
import 'dimensions/call_thumbnail_row_dimensions.dart';
import 'dimensions/call_top_bar_dimensions.dart';
import 'dimensions/call_video_content_dimensions.dart';

export 'dimensions/call_bottom_bar_dimensions.dart';
export 'dimensions/call_connection_banner_dimensions.dart';
export 'dimensions/call_handle_bar_dimensions.dart';
export 'dimensions/call_incoming_screen_dimensions.dart';
export 'dimensions/call_more_sheet_dimensions.dart';
export 'dimensions/call_outgoing_screen_dimensions.dart';
export 'dimensions/call_participant_tile_dimensions.dart';
export 'dimensions/call_participants_panel_dimensions.dart';
export 'dimensions/call_pip_dimensions.dart';
export 'dimensions/call_right_buttons_dimensions.dart';
export 'dimensions/call_screen_share_banner_dimensions.dart';
export 'dimensions/call_thumbnail_row_dimensions.dart';
export 'dimensions/call_top_bar_dimensions.dart';
export 'dimensions/call_video_content_dimensions.dart';

/// Every size the call UI lays out — button diameters, icon and font sizes,
/// bar heights, paddings, gaps and radii.
///
/// The kit used to hard-code all of them. They now live in one token class per
/// surface, each field defaulting to the value the package originally shipped,
/// so `const CallDimensions()` reproduces the old layout exactly and an
/// existing consumer sees no change.
///
/// There are two ways to resize the UI, and they compose.
///
/// **Set an individual metric.** Reach for the surface you want and name the
/// field:
///
/// ```dart
/// CallScreen(
///   dimensions: const CallDimensions(
///     bottomBar: CallBottomBarDimensions(
///       buttonSize: 56,        // was 50
///       endCallButtonSize: 72, // was 58
///     ),
///     pip: CallPipDimensions(size: Size(120, 160)), // was 90x120
///   ),
///   ...
/// )
/// ```
///
/// **Scale everything at once.** The kit is laid out in raw logical pixels,
/// which suits a phone held at reading distance. On a tablet, or on a rugged
/// device used at arm's length and in gloves, the controls end up smaller than
/// the rest of the host application. [scale] multiplies every token:
///
/// ```dart
/// CallScreen(
///   dimensions: CallDimensions(
///     scale: MediaQuery.sizeOf(context).shortestSide >= 550 ? 1.25 : 1.0,
///   ),
///   ...
/// )
/// ```
///
/// [scale] applies on top of whatever the tokens say, so an override is scaled
/// too: `endCallButtonSize: 72` at `scale: 1.25` renders 90. Four fields are
/// deliberately left out of the scaling — [CallPipDimensions.borderWidth],
/// [CallParticipantTileDimensions.speakingBorderWidth] and
/// [CallVideoContentDimensions.gridGutter] are hairlines, and
/// [CallVideoContentDimensions.personalAvatarFontRatio] is a ratio. Each says
/// so in its own doc.
///
/// [CallDimensions.compact] and [CallDimensions.comfortable] are ready-made
/// starting points; use [copyWith] to derive a variant from either.
@immutable
class CallDimensions {
  /// The multiplier applied to every token. `1.0` leaves them as declared.
  ///
  /// Must be finite and greater than zero.
  final double scale;

  /// Metrics of the top bar.
  final CallTopBarDimensions topBar;

  /// Metrics of the bottom controls bar.
  final CallBottomBarDimensions bottomBar;

  /// Metrics of the side button column.
  final CallRightButtonsDimensions rightButtons;

  /// Metrics of the video area below the bars.
  final CallVideoContentDimensions videoContent;

  /// Metrics of a single participant tile.
  final CallParticipantTileDimensions participantTile;

  /// Metrics of the thumbnail strip under the speaker view.
  final CallThumbnailRowDimensions thumbnailRow;

  /// Metrics of the floating picture-in-picture view.
  final CallPipDimensions pip;

  /// Metrics of the connection-state banner.
  final CallConnectionBannerDimensions connectionBanner;

  /// Metrics of the screen-share banner.
  final CallScreenShareBannerDimensions screenShareBanner;

  /// Metrics of the participants panel.
  final CallParticipantsPanelDimensions participantsPanel;

  /// Metrics of the "more options" sheet.
  final CallMoreSheetDimensions moreSheet;

  /// Metrics of a bottom sheet's drag handle.
  final CallHandleBarDimensions handleBar;

  /// Metrics of the incoming call screen.
  final CallIncomingScreenDimensions incoming;

  /// Metrics of the outgoing call screen.
  final CallOutgoingScreenDimensions outgoing;

  /// Creates a [CallDimensions]. Every token defaults to the kit's original
  /// metrics, so `const CallDimensions()` changes nothing.
  const CallDimensions({
    this.scale = 1.0,
    this.topBar = const CallTopBarDimensions(),
    this.bottomBar = const CallBottomBarDimensions(),
    this.rightButtons = const CallRightButtonsDimensions(),
    this.videoContent = const CallVideoContentDimensions(),
    this.participantTile = const CallParticipantTileDimensions(),
    this.thumbnailRow = const CallThumbnailRowDimensions(),
    this.pip = const CallPipDimensions(),
    this.connectionBanner = const CallConnectionBannerDimensions(),
    this.screenShareBanner = const CallScreenShareBannerDimensions(),
    this.participantsPanel = const CallParticipantsPanelDimensions(),
    this.moreSheet = const CallMoreSheetDimensions(),
    this.handleBar = const CallHandleBarDimensions(),
    this.incoming = const CallIncomingScreenDimensions(),
    this.outgoing = const CallOutgoingScreenDimensions(),
  }) : assert(scale > 0, 'scale must be greater than zero');

  /// The kit's original phone metrics — identical to `const CallDimensions()`.
  ///
  /// Sized for a handset held at reading distance.
  const CallDimensions.compact()
      : scale = 1.0,
        topBar = const CallTopBarDimensions(),
        bottomBar = const CallBottomBarDimensions(),
        rightButtons = const CallRightButtonsDimensions(),
        videoContent = const CallVideoContentDimensions(),
        participantTile = const CallParticipantTileDimensions(),
        thumbnailRow = const CallThumbnailRowDimensions(),
        pip = const CallPipDimensions(),
        connectionBanner = const CallConnectionBannerDimensions(),
        screenShareBanner = const CallScreenShareBannerDimensions(),
        participantsPanel = const CallParticipantsPanelDimensions(),
        moreSheet = const CallMoreSheetDimensions(),
        handleBar = const CallHandleBarDimensions(),
        incoming = const CallIncomingScreenDimensions(),
        outgoing = const CallOutgoingScreenDimensions();

  /// Roomier metrics for a tablet, or for a device used at arm's length and in
  /// gloves.
  ///
  /// Everything grows by 15%, and the buttons a host is most likely to be
  /// aimed at in a hurry — the bottom bar's controls, the side buttons and the
  /// accept/decline pair — grow further still.
  const CallDimensions.comfortable()
      : scale = 1.15,
        topBar = const CallTopBarDimensions(),
        bottomBar = const CallBottomBarDimensions(
          buttonSize: 56,
          endCallButtonSize: 64,
        ),
        rightButtons = const CallRightButtonsDimensions(buttonSize: 52),
        videoContent = const CallVideoContentDimensions(),
        participantTile = const CallParticipantTileDimensions(),
        thumbnailRow = const CallThumbnailRowDimensions(),
        pip = const CallPipDimensions(),
        connectionBanner = const CallConnectionBannerDimensions(),
        screenShareBanner = const CallScreenShareBannerDimensions(),
        participantsPanel = const CallParticipantsPanelDimensions(),
        moreSheet = const CallMoreSheetDimensions(),
        handleBar = const CallHandleBarDimensions(),
        incoming = const CallIncomingScreenDimensions(actionButtonSize: 72),
        outgoing = const CallOutgoingScreenDimensions();

  /// A token brought to the current [scale].
  double scaled(double base) => base * scale;

  /// A two-dimensional token brought to the current [scale].
  Size scaledSize(Size base) => Size(base.width * scale, base.height * scale);

  // ── Reserved areas ──
  //
  // These live here rather than on the bars because a host that composes its
  // own overlay has to reserve the same space, and the bars are not exported.
  // A copy on the host side is how it silently drifts — see the 94-vs-102 bug
  // fixed in 0.5.0.

  /// The height of the top bar, excluding any safe-area inset.
  double get topBarHeight => scaled(topBar.height);

  /// The height of the connection-state banner.
  double get connectionBannerHeight => scaled(connectionBanner.height);

  /// The height of the bottom controls bar, excluding any safe-area inset.
  ///
  /// Composed from the bar's own tokens rather than declared separately, so it
  /// cannot drift when they change; `call_dimensions_test.dart` asserts it
  /// against the laid-out bar.
  double get bottomBarHeight => scaled(
        bottomBar.bottomInset +
            bottomBar.verticalPadding * 2 +
            bottomBar.endCallButtonSize,
      );

  /// The height the side button column occupies for the given set of buttons.
  ///
  /// Used to keep the picture-in-picture view clear of them.
  double rightButtonsHeight({
    required bool hasAdd,
    required bool hasEffects,
  }) {
    var height = 0.0;
    if (hasAdd) height += rightButtons.buttonSize;
    if (hasEffects) height += rightButtons.buttonSize;
    if (hasAdd && hasEffects) height += rightButtons.spacing;
    return scaled(height);
  }

  /// Returns a copy of these dimensions with the given fields replaced.
  CallDimensions copyWith({
    double? scale,
    CallTopBarDimensions? topBar,
    CallBottomBarDimensions? bottomBar,
    CallRightButtonsDimensions? rightButtons,
    CallVideoContentDimensions? videoContent,
    CallParticipantTileDimensions? participantTile,
    CallThumbnailRowDimensions? thumbnailRow,
    CallPipDimensions? pip,
    CallConnectionBannerDimensions? connectionBanner,
    CallScreenShareBannerDimensions? screenShareBanner,
    CallParticipantsPanelDimensions? participantsPanel,
    CallMoreSheetDimensions? moreSheet,
    CallHandleBarDimensions? handleBar,
    CallIncomingScreenDimensions? incoming,
    CallOutgoingScreenDimensions? outgoing,
  }) {
    return CallDimensions(
      scale: scale ?? this.scale,
      topBar: topBar ?? this.topBar,
      bottomBar: bottomBar ?? this.bottomBar,
      rightButtons: rightButtons ?? this.rightButtons,
      videoContent: videoContent ?? this.videoContent,
      participantTile: participantTile ?? this.participantTile,
      thumbnailRow: thumbnailRow ?? this.thumbnailRow,
      pip: pip ?? this.pip,
      connectionBanner: connectionBanner ?? this.connectionBanner,
      screenShareBanner: screenShareBanner ?? this.screenShareBanner,
      participantsPanel: participantsPanel ?? this.participantsPanel,
      moreSheet: moreSheet ?? this.moreSheet,
      handleBar: handleBar ?? this.handleBar,
      incoming: incoming ?? this.incoming,
      outgoing: outgoing ?? this.outgoing,
    );
  }

  List<Object?> get _props => [
        scale,
        topBar,
        bottomBar,
        rightButtons,
        videoContent,
        participantTile,
        thumbnailRow,
        pip,
        connectionBanner,
        screenShareBanner,
        participantsPanel,
        moreSheet,
        handleBar,
        incoming,
        outgoing,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallDimensions &&
          runtimeType == other.runtimeType &&
          listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() => 'CallDimensions(scale: $scale)';
}
