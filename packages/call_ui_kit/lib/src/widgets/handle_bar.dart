/// A small drag-handle indicator for bottom sheets.
library;

import 'package:flutter/material.dart';

import '../models/call_dimensions.dart';

/// A rounded handle bar typically shown at the top of a modal bottom sheet
/// to indicate it can be dragged.
class HandleBar extends StatelessWidget {
  /// Optional margin override. Defaults to
  /// [CallHandleBarDimensions.verticalMargin] at the current scale.
  final EdgeInsetsGeometry? margin;

  /// The sizing configuration. Defaults to the kit's native metrics.
  final CallDimensions dimensions;

  const HandleBar({
    super.key,
    this.margin,
    this.dimensions = const CallDimensions(),
  });

  @override
  Widget build(BuildContext context) {
    final d = dimensions.handleBar;
    final height = dimensions.scaled(d.height);

    return Container(
      width: dimensions.scaled(d.width),
      height: height,
      margin: margin ??
          EdgeInsets.symmetric(
            vertical: dimensions.scaled(d.verticalMargin),
          ),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
