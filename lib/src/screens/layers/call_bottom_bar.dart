/// The bottom controls bar for the call screen.
library;

import 'package:flutter/material.dart';

import '../../models/call_dimensions.dart';
import '../../models/call_strings.dart';
import '../../models/call_theme.dart';

/// A rounded bar of circular control buttons (mute, camera, speaker, end call, etc.).
///
/// Each optional button is shown only when its callback is provided.
class CallBottomBar extends StatelessWidget {
  final CallTheme theme;
  final CallDimensions dimensions;
  final CallStrings strings;
  final bool isMuted;
  final bool isCameraOff;
  final bool isSpeakerOn;
  final VoidCallback onResetHideTimer;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onEndCall;
  final VoidCallback? onShowMore;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onToggleScreenShare;
  final bool isScreenSharing;

  const CallBottomBar({
    super.key,
    required this.theme,
    this.dimensions = const CallDimensions(),
    required this.strings,
    required this.isMuted,
    this.isCameraOff = false,
    required this.isSpeakerOn,
    this.isScreenSharing = false,
    required this.onResetHideTimer,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onEndCall,
    this.onShowMore,
    this.onToggleCamera,
    this.onToggleScreenShare,
  });

  @override
  Widget build(BuildContext context) {
    final d = dimensions.bottomBar;
    final buttonSize = dimensions.scaled(d.buttonSize);

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(
          left: dimensions.scaled(d.horizontalInset),
          right: dimensions.scaled(d.horizontalInset),
          bottom: dimensions.scaled(d.bottomInset),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: dimensions.scaled(d.verticalPadding),
            horizontal: dimensions.scaled(d.innerHorizontal),
          ),
          decoration: BoxDecoration(
            color: theme.barBackground.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(
              dimensions.scaled(d.barRadius),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Three dots / more menu
              if (onShowMore != null)
                _buildControlButton(
                  icon: Icons.more_horiz,
                  iconColor: theme.textPrimary,
                  backgroundColor: theme.buttonBackground,
                  size: buttonSize,
                  onTap: onShowMore!,
                  semanticLabel: strings.moreOptions,
                ),

              // Screen share toggle
              if (onToggleScreenShare != null)
                _buildControlButton(
                  icon: isScreenSharing
                      ? Icons.stop_screen_share
                      : Icons.screen_share,
                  iconColor: theme.textPrimary,
                  backgroundColor: theme.buttonBackground,
                  size: buttonSize,
                  onTap: onToggleScreenShare!,
                  semanticLabel: strings.shareScreen,
                ),

              // Video camera toggle
              if (onToggleCamera != null)
                _buildControlButton(
                  icon: isCameraOff ? Icons.videocam_off : Icons.videocam,
                  iconColor: theme.textPrimary,
                  backgroundColor: theme.buttonBackground,
                  size: buttonSize,
                  onTap: onToggleCamera!,
                  semanticLabel: strings.camera,
                ),

              // Speaker
              _buildControlButton(
                icon: Icons.volume_up,
                iconColor: isSpeakerOn
                    ? theme.speakerActiveIconColor
                    : theme.textPrimary,
                backgroundColor: isSpeakerOn
                    ? theme.speakerActiveBackground
                    : theme.buttonBackground,
                size: buttonSize,
                onTap: onToggleSpeaker,
                semanticLabel: strings.speaker,
              ),

              // Microphone
              _buildControlButton(
                icon: isMuted ? Icons.mic_off : Icons.mic,
                iconColor: theme.textPrimary,
                backgroundColor: theme.buttonBackground,
                size: buttonSize,
                onTap: onToggleMute,
                semanticLabel: isMuted ? strings.unmute : strings.mute,
              ),

              // End call
              _buildControlButton(
                icon: Icons.call_end,
                iconColor: theme.textPrimary,
                backgroundColor: theme.endCallColor,
                size: dimensions.scaled(d.endCallButtonSize),
                iconSize: dimensions.scaled(d.endCallIconSize),
                onTap: onEndCall,
                semanticLabel: strings.endCall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required double size,
    double? iconSize,
    required VoidCallback onTap,
    String? semanticLabel,
  }) {
    return Semantics(
      button: true,
      container: true,
      label: semanticLabel,
      onTap: () {
        onResetHideTimer();
        onTap();
      },
      child: GestureDetector(
        onTap: () {
          onResetHideTimer();
          onTap();
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: iconSize ?? dimensions.scaled(dimensions.bottomBar.iconSize),
          ),
        ),
      ),
    );
  }
}
