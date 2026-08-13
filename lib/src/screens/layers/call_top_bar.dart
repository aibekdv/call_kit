/// The top app bar overlay for the call screen.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/call_dimensions.dart';
import '../../models/call_strings.dart';
import '../../models/call_theme.dart';

/// A gradient-backed top bar showing caller info and camera controls.
class CallTopBar extends StatelessWidget {
  final CallTheme theme;
  final CallDimensions dimensions;
  final CallStrings strings;
  final String callerName;
  final String? callStatusText;

  /// When provided, the status line listens to this instead of using
  /// [callStatusText], so a value that changes often does not rebuild the bar.
  final ValueListenable<String>? callStatusListenable;

  final bool isGroupCall;
  final int participantCount;
  final VoidCallback onResetHideTimer;
  final VoidCallback? onFlipCamera;
  final VoidCallback? onMinimize;

  const CallTopBar({
    super.key,
    required this.theme,
    this.dimensions = const CallDimensions(),
    required this.strings,
    required this.callerName,
    this.callStatusText,
    this.callStatusListenable,
    required this.isGroupCall,
    required this.participantCount,
    required this.onResetHideTimer,
    this.onFlipCamera,
    this.onMinimize,
  });

  Widget _buildStatusText(String status) {
    return Text(
      status,
      style: TextStyle(
        color: theme.textPrimary.withValues(alpha: 0.7),
        fontSize: dimensions.scaled(dimensions.topBar.statusFontSize),
      ),
    );
  }

  /// Keeps the tap target in step with the icon: [IconButton] would otherwise
  /// stay at its default 48 px however large the glyph grows.
  Widget _buildIconButton({
    required IconData icon,
    required double size,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final scaled = dimensions.scaled(size);
    final target = dimensions.scaled(dimensions.topBar.minTapTarget);

    return IconButton(
      icon: Icon(icon, color: theme.textPrimary, size: scaled),
      iconSize: scaled,
      constraints: BoxConstraints.tightFor(width: target, height: target),
      tooltip: tooltip,
      onPressed: () {
        onResetHideTimer();
        onPressed();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = dimensions.topBar;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ),
      ),
      height: dimensions.topBarHeight,
      child: Row(
        children: [
          // Left — Minimize / PiP button
          Expanded(
            child: onMinimize != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: _buildIconButton(
                      icon: Icons.keyboard_arrow_down_rounded,
                      size: d.minimizeIconSize,
                      tooltip: strings.pictureInPicture,
                      onPressed: onMinimize!,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Center — name + status
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  callerName,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: dimensions.scaled(d.nameFontSize),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: dimensions.scaled(d.nameGap)),
                if (callStatusListenable != null)
                  ValueListenableBuilder<String>(
                    valueListenable: callStatusListenable!,
                    builder: (context, status, _) => _buildStatusText(status),
                  )
                else
                  _buildStatusText(callStatusText ?? strings.calling),
                if (isGroupCall)
                  Text(
                    strings.participantsCount(participantCount),
                    style: TextStyle(
                      color: theme.textPrimary.withValues(alpha: 0.54),
                      fontSize: dimensions.scaled(d.countFontSize),
                    ),
                  ),
              ],
            ),
          ),

          // Right — flip camera (when callback provided)
          Expanded(
            child: onFlipCamera != null
                ? Align(
                    alignment: Alignment.centerRight,
                    child: _buildIconButton(
                      icon: Icons.flip_camera_ios,
                      size: d.flipIconSize,
                      tooltip: strings.flipCamera,
                      onPressed: onFlipCamera!,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
