/// The incoming call screen with accept and decline buttons.
library;

import 'package:flutter/material.dart';

import '../models/call_dimensions.dart';
import '../models/call_strings.dart';
import '../models/call_theme.dart';
import '../models/call_type.dart';
import '../widgets/call_avatar.dart';

/// Displays an incoming call screen with caller info, and accept/decline
/// buttons.
///
/// This is a [StatelessWidget] with zero animation controllers or timers
/// for maximum performance. All state is managed externally via callbacks.
///
/// ```dart
/// IncomingCallScreen(
///   callerName: 'Sarah Johnson',
///   callerAvatarUrl: 'https://example.com/avatar.jpg',
///   callType: CallType.video,
///   onAccept: () => navigateToCallScreen(),
///   onDecline: () => Navigator.pop(context),
/// )
/// ```
class IncomingCallScreen extends StatelessWidget {
  /// The name of the caller displayed prominently.
  final String callerName;

  /// Optional avatar URL for the caller.
  final String? callerAvatarUrl;

  /// The type of incoming call (audio or video).
  final CallType callType;

  /// The visual theme. Defaults to [CallTheme.whatsApp].
  final CallTheme theme;

  /// The sizing configuration. Defaults to the kit's native metrics.
  final CallDimensions dimensions;

  /// Localised strings. Defaults to [CallStrings.english].
  final CallStrings? strings;

  /// Called when the accept button is tapped.
  final VoidCallback onAccept;

  /// Called when the decline button is tapped.
  final VoidCallback onDecline;

  /// Creates an [IncomingCallScreen].
  const IncomingCallScreen({
    super.key,
    required this.callerName,
    this.callerAvatarUrl,
    this.callType = CallType.audio,
    this.theme = const CallTheme.whatsApp(),
    this.dimensions = const CallDimensions(),
    this.strings,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final s = strings ?? CallStrings.english();
    final d = dimensions.incoming;
    final statusText =
        callType == CallType.video ? s.incomingVideoCall : s.incomingAudioCall;

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.background,
        body: Column(
          children: [
            // ── Caller info ──
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CallAvatar(
                      displayName: callerName,
                      avatarUrl: callerAvatarUrl,
                      radius: dimensions.scaled(d.avatarRadius),
                      theme: theme,
                    ),
                    SizedBox(height: dimensions.scaled(d.avatarNameGap)),
                    Text(
                      callerName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: dimensions.scaled(d.nameFontSize),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: dimensions.scaled(d.nameStatusGap)),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: dimensions.scaled(d.statusFontSize),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Accept / Decline buttons ──
            Padding(
              padding: EdgeInsets.only(
                bottom: dimensions.scaled(d.bottomInset),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallActionButton(
                    icon: Icons.call_end,
                    label: s.decline,
                    color: theme.endCallColor,
                    theme: theme,
                    dimensions: dimensions,
                    onTap: onDecline,
                  ),
                  _CallActionButton(
                    icon: callType == CallType.video
                        ? Icons.videocam
                        : Icons.call,
                    label: s.accept,
                    color: theme.acceptCallColor,
                    theme: theme,
                    dimensions: dimensions,
                    onTap: onAccept,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final CallTheme theme;
  final CallDimensions dimensions;
  final VoidCallback onTap;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.theme,
    required this.dimensions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final d = dimensions.incoming;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dimensions.scaled(d.actionButtonSize),
            height: dimensions.scaled(d.actionButtonSize),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: dimensions.scaled(d.actionIconSize),
            ),
          ),
          SizedBox(height: dimensions.scaled(d.actionLabelGap)),
          Text(
            label,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: dimensions.scaled(d.actionLabelFontSize),
            ),
          ),
        ],
      ),
    );
  }
}
