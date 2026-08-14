import 'dart:math' as math;
import 'dart:ui';

/// The screen corner a floating Picture-in-Picture view is anchored to.
///
/// The corner — not a pixel offset — is what should be stored as the PiP's
/// position. Deriving the offset from the corner means the view stays in the
/// corner the user put it in when the reserved areas change (call controls
/// fading in or out, a banner appearing, a rotation), instead of being
/// re-snapped from stale pixels and potentially drifting to a different
/// corner.
enum PipCorner {
  /// Top-left corner.
  topLeft,

  /// Top-right corner.
  topRight,

  /// Bottom-left corner.
  bottomLeft,

  /// Bottom-right corner.
  bottomRight,
}

/// Calculates corner positions for the floating Picture-in-Picture view.
///
/// The PiP view snaps to the nearest corner of the screen when the user
/// releases it after dragging.
class PipSnapCalculator {
  PipSnapCalculator._();

  /// Returns the corner nearest to the PiP's current position.
  ///
  /// [current] is the current position of the PiP (top-left corner).
  /// [screenSize] is the total screen size.
  /// [pipSize] is the size of the PiP widget.
  ///
  /// A PiP centred exactly on the screen centre resolves to
  /// [PipCorner.topLeft].
  static PipCorner nearestCorner({
    required Offset current,
    required Size screenSize,
    required Size pipSize,
  }) {
    final cx = current.dx + pipSize.width / 2;
    final cy = current.dy + pipSize.height / 2;
    final isRight = cx > screenSize.width / 2;
    final isBottom = cy > screenSize.height / 2;

    if (isBottom) {
      return isRight ? PipCorner.bottomRight : PipCorner.bottomLeft;
    }
    return isRight ? PipCorner.topRight : PipCorner.topLeft;
  }

  /// Returns the [Offset] at which the PiP sits when anchored to [corner].
  ///
  /// [margin] is the margin from screen edges.
  /// [topBarHeight] is the height of the area reserved at the top.
  /// [controlsHeight] is the height of the area reserved at the bottom.
  ///
  /// The result is clamped to the viewport: the reserved areas can exceed the
  /// screen on very small viewports, and the PiP must stay visible rather than
  /// be pushed off-screen.
  static Offset offsetForCorner(
    PipCorner corner, {
    required Size screenSize,
    required Size pipSize,
    required double margin,
    required double topBarHeight,
    required double controlsHeight,
  }) {
    final isRight =
        corner == PipCorner.topRight || corner == PipCorner.bottomRight;
    final isBottom =
        corner == PipCorner.bottomLeft || corner == PipCorner.bottomRight;

    final dx = isRight ? screenSize.width - pipSize.width - margin : margin;
    final dy = isBottom
        ? screenSize.height - pipSize.height - controlsHeight - margin
        : topBarHeight + margin;

    return clampToBounds(
      Offset(dx, dy),
      screenSize: screenSize,
      pipSize: pipSize,
      margin: margin,
      topBarHeight: topBarHeight,
      controlsHeight: controlsHeight,
    );
  }

  /// Constrains [offset] to the area left free by the reserved insets.
  ///
  /// When the reserved areas are taller than the viewport the allowed range
  /// would be empty, so the position collapses to the top-left of that range
  /// instead of producing an invalid clamp.
  static Offset clampToBounds(
    Offset offset, {
    required Size screenSize,
    required Size pipSize,
    required double margin,
    required double topBarHeight,
    required double controlsHeight,
  }) {
    final maxDx = math.max(margin, screenSize.width - pipSize.width - margin);
    final minDy = topBarHeight + margin;
    final maxDy = math.max(
      minDy,
      screenSize.height - pipSize.height - controlsHeight - margin,
    );

    return Offset(
      offset.dx.clamp(margin, maxDx),
      offset.dy.clamp(minDy, maxDy),
    );
  }

  /// Returns the [Offset] of the nearest corner for the PiP to snap to.
  ///
  /// Convenience composition of [nearestCorner] and [offsetForCorner]; prefer
  /// storing the [PipCorner] itself so the position can be re-derived when the
  /// reserved insets change.
  static Offset snapToNearestCorner({
    required Offset current,
    required Size screenSize,
    required Size pipSize,
    required double margin,
    required double topBarHeight,
    required double controlsHeight,
  }) {
    return offsetForCorner(
      nearestCorner(
        current: current,
        screenSize: screenSize,
        pipSize: pipSize,
      ),
      screenSize: screenSize,
      pipSize: pipSize,
      margin: margin,
      topBarHeight: topBarHeight,
      controlsHeight: controlsHeight,
    );
  }
}
