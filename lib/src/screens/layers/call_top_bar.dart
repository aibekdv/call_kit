/// The top app bar overlay for the call screen.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/call_strings.dart';
import '../../models/call_theme.dart';

/// A gradient-backed top bar showing caller info and camera controls.
class CallTopBar extends StatelessWidget {
  /// The height of the bar, excluding any safe-area inset applied by the
  /// parent. Used by [CallScreen] to keep the PiP clear of the bar.
  static const double height = 80;

  final CallTheme theme;
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
        fontSize: 13,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      height: height,
      child: Row(
        children: [
          // Left — Minimize / PiP button
          Expanded(
            child: onMinimize != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: theme.textPrimary,
                        size: 24,
                      ),
                      tooltip: strings.pictureInPicture,
                      onPressed: () {
                        onResetHideTimer();
                        onMinimize!();
                      },
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
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
                      fontSize: 11,
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
                    child: IconButton(
                      icon: Icon(
                        Icons.flip_camera_ios,
                        color: theme.textPrimary,
                        size: 28,
                      ),
                      tooltip: strings.flipCamera,
                      onPressed: () {
                        onResetHideTimer();
                        onFlipCamera!();
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
