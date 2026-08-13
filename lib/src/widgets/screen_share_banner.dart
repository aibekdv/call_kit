/// A banner displayed when screen sharing is active.
library;

import 'package:flutter/material.dart';

import '../models/call_dimensions.dart';
import '../models/call_strings.dart';
import '../models/call_theme.dart';

/// Shows a contextual banner at the top of the call screen indicating that
/// screen sharing is in progress.
///
/// Renders differently depending on whether the local user or a remote
/// participant is sharing:
///
/// - **Local sharing**: a red banner with a [Stop] button.
/// - **Remote sharing**: a dark banner showing the sharer's name.
///
/// The banner slides in from the top with a 250 ms ease-out animation.
class ScreenShareBanner extends StatefulWidget {
  /// Whether the local user is the one sharing their screen.
  final bool isLocalSharing;

  /// The display name of the remote participant who is sharing.
  final String? sharerName;

  /// The visual theme providing colours and styling.
  final CallTheme theme;

  /// The sizing configuration. Defaults to the kit's native metrics.
  final CallDimensions dimensions;

  /// The localised strings used for labels.
  final CallStrings strings;

  /// Called when the stop-sharing button is tapped.
  final VoidCallback? onStop;

  /// Creates a [ScreenShareBanner].
  const ScreenShareBanner({
    super.key,
    required this.isLocalSharing,
    this.sharerName,
    required this.theme,
    this.dimensions = const CallDimensions(),
    required this.strings,
    this.onStop,
  });

  @override
  State<ScreenShareBanner> createState() => _ScreenShareBannerState();
}

class _ScreenShareBannerState extends State<ScreenShareBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SlideTransition(
        position: _slideAnimation,
        child:
            widget.isLocalSharing ? _buildLocalBanner() : _buildRemoteBanner(),
      ),
    );
  }

  Widget _buildLocalBanner() {
    final dimensions = widget.dimensions;
    final d = dimensions.screenShareBanner;

    return Container(
      height: dimensions.scaled(d.height),
      color: const Color(0xFFB71C1C).withValues(alpha: 0.9),
      padding: EdgeInsets.symmetric(
        horizontal: dimensions.scaled(d.horizontalPadding),
      ),
      child: Row(
        children: [
          Icon(
            Icons.screen_share,
            color: Colors.white,
            size: dimensions.scaled(d.iconSize),
          ),
          SizedBox(width: dimensions.scaled(d.iconGap)),
          Text(
            widget.strings.youAreSharingYourScreen,
            style: TextStyle(
              color: Colors.white,
              fontSize: dimensions.scaled(d.fontSize),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onStop,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: dimensions.scaled(d.stopHorizontal),
                vertical: dimensions.scaled(d.stopVertical),
              ),
              decoration: BoxDecoration(
                // Hairline: it stays one logical pixel at any scale.
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.54),
                ),
                borderRadius:
                    BorderRadius.circular(dimensions.scaled(d.stopRadius)),
              ),
              child: Text(
                widget.strings.stop,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: dimensions.scaled(d.stopFontSize),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteBanner() {
    final dimensions = widget.dimensions;
    final d = dimensions.screenShareBanner;

    return Container(
      height: dimensions.scaled(d.height),
      color: widget.theme.barBackground.withValues(alpha: 0.9),
      padding: EdgeInsets.symmetric(
        horizontal: dimensions.scaled(d.horizontalPadding),
      ),
      child: Row(
        children: [
          Icon(
            Icons.screen_share,
            color: widget.theme.textPrimary,
            size: dimensions.scaled(d.iconSize),
          ),
          SizedBox(width: dimensions.scaled(d.iconGap)),
          Expanded(
            child: Text(
              widget.strings.isSharingScreen(widget.sharerName ?? ''),
              style: TextStyle(
                color: widget.theme.textPrimary,
                fontSize: dimensions.scaled(d.fontSize),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
