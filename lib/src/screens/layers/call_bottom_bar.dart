/// The bottom controls bar for the call screen.
library;

import 'package:flutter/material.dart';

import '../../models/call_strings.dart';
import '../../models/call_theme.dart';

/// A rounded bar of circular control buttons (mute, camera, speaker, end call, etc.).
///
/// Each optional button is shown only when its callback is provided.
class CallBottomBar extends StatelessWidget {
  static const double _buttonSize = 50;
  static const double _endCallButtonSize = 58;
  static const double _barPadding = 12;
  static const double _bottomInset = 20;

  /// The height of the bar, excluding any safe-area inset applied by the
  /// parent. Used by [CallScreen] to keep the PiP clear of the controls.
  ///
  /// Derived from the layout constants rather than hand-written, so it cannot
  /// drift when the bar's metrics change. `call_bottom_bar_test.dart` asserts
  /// it against the laid-out bar.
  static const double height =
      _bottomInset + _barPadding * 2 + _endCallButtonSize;

  final CallTheme theme;
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
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: _bottomInset,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: _barPadding,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: theme.barBackground.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(40),
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
                  size: _buttonSize,
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
                  size: _buttonSize,
                  onTap: onToggleScreenShare!,
                  semanticLabel: strings.shareScreen,
                ),

              // Video camera toggle
              if (onToggleCamera != null)
                _buildControlButton(
                  icon: isCameraOff ? Icons.videocam_off : Icons.videocam,
                  iconColor: theme.textPrimary,
                  backgroundColor: theme.buttonBackground,
                  size: _buttonSize,
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
                size: _buttonSize,
                onTap: onToggleSpeaker,
                semanticLabel: strings.speaker,
              ),

              // Microphone
              _buildControlButton(
                icon: isMuted ? Icons.mic_off : Icons.mic,
                iconColor: theme.textPrimary,
                backgroundColor: theme.buttonBackground,
                size: _buttonSize,
                onTap: onToggleMute,
                semanticLabel: isMuted ? strings.unmute : strings.mute,
              ),

              // End call
              _buildControlButton(
                icon: Icons.call_end,
                iconColor: theme.textPrimary,
                backgroundColor: theme.endCallColor,
                size: _endCallButtonSize,
                iconSize: 26,
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
    double iconSize = 22,
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
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
      ),
    );
  }
}
