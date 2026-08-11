/// A banner displayed while the call is connecting or reconnecting.
library;

import 'package:flutter/material.dart';

import '../models/call_connection_state.dart';
import '../models/call_strings.dart';
import '../models/call_theme.dart';

/// Shows a slim banner at the top of the call screen while the connection is
/// being established or recovered.
///
/// Unlike the call controls, this banner is never auto-hidden: a user whose
/// call is reconnecting needs the status to stay on screen.
///
/// The banner is deliberately static — no looping spinner — so that
/// `pumpAndSettle` still settles in host application tests.
class ConnectionStateBanner extends StatelessWidget {
  /// The height of the banner, used by [CallScreen] to keep the PiP clear.
  static const double height = 36;

  /// The current connection state. [CallConnectionState.connected] renders
  /// nothing.
  final CallConnectionState state;

  /// The visual theme providing colours and styling.
  final CallTheme theme;

  /// The localised strings used for labels.
  final CallStrings strings;

  /// Creates a [ConnectionStateBanner].
  const ConnectionStateBanner({
    super.key,
    required this.state,
    required this.theme,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    if (state == CallConnectionState.connected) {
      return const SizedBox.shrink();
    }

    final isReconnecting = state == CallConnectionState.reconnecting;
    final label = isReconnecting ? strings.reconnecting : strings.connecting;

    return RepaintBoundary(
      child: Semantics(
        liveRegion: true,
        label: label,
        child: Container(
          height: height,
          color: theme.barBackground.withValues(alpha: 0.9),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isReconnecting ? Icons.sync_problem : Icons.sync,
                color: theme.textPrimary,
                size: 14,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(color: theme.textPrimary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
