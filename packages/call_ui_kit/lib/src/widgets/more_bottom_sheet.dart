/// The "more options" bottom sheet shown from the three-dots button.
library;

import 'package:flutter/material.dart';

import '../models/call_dimensions.dart';
import '../models/call_strings.dart';
import '../models/call_theme.dart';
import 'handle_bar.dart';

/// A modal bottom sheet with a handle bar, optional encryption label,
/// custom content area, and a cancel button.
///
/// The [child] widget is placed between the encryption label and the cancel
/// button. Consumers provide their own menu items via [child]:
///
/// ```dart
/// MoreBottomSheet(
///   theme: theme,
///   strings: strings,
///   child: Column(
///     children: [
///       ListTile(title: Text('Share Screen'), onTap: ...),
///       ListTile(title: Text('Send Message'), onTap: ...),
///     ],
///   ),
/// )
/// ```
class MoreBottomSheet extends StatelessWidget {
  /// The visual theme.
  final CallTheme theme;

  /// The sizing configuration. Defaults to the kit's native metrics.
  final CallDimensions dimensions;

  /// Localised strings (used for the cancel button text).
  final CallStrings strings;

  /// Whether to show the end-to-end encryption label.
  final bool showEncryptionLabel;

  /// Custom content placed between the encryption label and cancel button.
  final Widget child;

  /// Creates a [MoreBottomSheet].
  const MoreBottomSheet({
    super.key,
    required this.theme,
    this.dimensions = const CallDimensions(),
    required this.strings,
    this.showEncryptionLabel = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final d = dimensions.moreSheet;

    return Container(
      decoration: BoxDecoration(
        color: theme.barBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(dimensions.scaled(d.radius)),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: bottomPadding + dimensions.scaled(d.bottomPadding),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          HandleBar(dimensions: dimensions),

          // Encryption label
          if (showEncryptionLabel) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  color: theme.textPrimary.withValues(alpha: 0.54),
                  size: dimensions.scaled(d.lockIconSize),
                ),
                SizedBox(width: dimensions.scaled(d.lockGap)),
                Text(
                  strings.endToEndEncrypted,
                  style: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.54),
                    fontSize: dimensions.scaled(d.encryptionFontSize),
                  ),
                ),
              ],
            ),
            SizedBox(height: dimensions.scaled(d.sectionGap)),
          ],

          // Custom content
          child,

          SizedBox(height: dimensions.scaled(d.sectionGap)),

          // Cancel button
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: dimensions.scaled(d.cancelMargin),
            ),
            decoration: BoxDecoration(
              color: theme.buttonBackground,
              borderRadius: BorderRadius.circular(
                dimensions.scaled(d.cancelRadius),
              ),
            ),
            child: ListTile(
              title: Text(
                strings.cancel,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: dimensions.scaled(d.cancelFontSize),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              onTap: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
