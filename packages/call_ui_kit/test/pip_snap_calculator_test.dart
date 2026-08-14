import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:call_ui_kit/call_ui_kit.dart';

void main() {
  const screenSize = Size(390, 844);
  const pipSize = Size(90, 120);
  const margin = 16.0;
  const topBarHeight = 100.0;
  const controlsHeight = 150.0;

  // Pre-computed expected snap positions:
  // left-x  = margin = 16
  // right-x = screenSize.width - pipSize.width - margin = 390 - 90 - 16 = 284
  // top-y   = topBarHeight + margin = 100 + 16 = 116
  // bottom-y = screenSize.height - pipSize.height - controlsHeight - margin
  //          = 844 - 120 - 150 - 16 = 558

  group('PipSnapCalculator', () {
    test('snaps to top-right when pip is in top-right quadrant', () {
      final result = PipSnapCalculator.snapToNearestCorner(
        current: const Offset(300, 50),
        screenSize: screenSize,
        pipSize: pipSize,
        margin: margin,
        topBarHeight: topBarHeight,
        controlsHeight: controlsHeight,
      );
      expect(result.dx, 284.0);
      expect(result.dy, 116.0);
    });

    test('snaps to top-left when pip is in top-left quadrant', () {
      final result = PipSnapCalculator.snapToNearestCorner(
        current: const Offset(10, 50),
        screenSize: screenSize,
        pipSize: pipSize,
        margin: margin,
        topBarHeight: topBarHeight,
        controlsHeight: controlsHeight,
      );
      expect(result.dx, 16.0);
      expect(result.dy, 116.0);
    });

    test('snaps to bottom-right when pip is in bottom-right quadrant', () {
      final result = PipSnapCalculator.snapToNearestCorner(
        current: const Offset(300, 600),
        screenSize: screenSize,
        pipSize: pipSize,
        margin: margin,
        topBarHeight: topBarHeight,
        controlsHeight: controlsHeight,
      );
      expect(result.dx, 284.0);
      expect(result.dy, 558.0);
    });

    test('snaps to bottom-left when pip is in bottom-left quadrant', () {
      final result = PipSnapCalculator.snapToNearestCorner(
        current: const Offset(10, 600),
        screenSize: screenSize,
        pipSize: pipSize,
        margin: margin,
        topBarHeight: topBarHeight,
        controlsHeight: controlsHeight,
      );
      expect(result.dx, 16.0);
      expect(result.dy, 558.0);
    });

    test('snaps to top-left when pip center is exactly at screen center', () {
      // Center of pip must equal center of screen:
      // cx = current.dx + pipSize.width / 2 = screenSize.width / 2 = 195
      //   => current.dx = 195 - 45 = 150
      // cy = current.dy + pipSize.height / 2 = screenSize.height / 2 = 422
      //   => current.dy = 422 - 60 = 362
      //
      // isRight uses >, so cx == screenWidth/2 => false (goes left).
      // isBottom uses >, so cy == screenHeight/2 => false (goes top).
      // Result: top-left.
      final result = PipSnapCalculator.snapToNearestCorner(
        current: const Offset(150, 362),
        screenSize: screenSize,
        pipSize: pipSize,
        margin: margin,
        topBarHeight: topBarHeight,
        controlsHeight: controlsHeight,
      );
      expect(result.dx, 16.0);
      expect(result.dy, 116.0);
    });
  });

  group('PipSnapCalculator.nearestCorner', () {
    PipCorner cornerFor(Offset current) => PipSnapCalculator.nearestCorner(
          current: current,
          screenSize: screenSize,
          pipSize: pipSize,
        );

    test('resolves each quadrant to its corner', () {
      expect(cornerFor(const Offset(300, 50)), PipCorner.topRight);
      expect(cornerFor(const Offset(10, 50)), PipCorner.topLeft);
      expect(cornerFor(const Offset(300, 600)), PipCorner.bottomRight);
      expect(cornerFor(const Offset(10, 600)), PipCorner.bottomLeft);
    });

    test('resolves an exactly centred pip to top-left', () {
      expect(cornerFor(const Offset(150, 362)), PipCorner.topLeft);
    });
  });

  group('PipSnapCalculator.offsetForCorner', () {
    Offset offsetFor(
      PipCorner corner, {
      double top = topBarHeight,
      double bottom = controlsHeight,
      Size size = screenSize,
    }) =>
        PipSnapCalculator.offsetForCorner(
          corner,
          screenSize: size,
          pipSize: pipSize,
          margin: margin,
          topBarHeight: top,
          controlsHeight: bottom,
        );

    test('places each corner at the expected position', () {
      expect(offsetFor(PipCorner.topLeft), const Offset(16, 116));
      expect(offsetFor(PipCorner.topRight), const Offset(284, 116));
      expect(offsetFor(PipCorner.bottomLeft), const Offset(16, 558));
      expect(offsetFor(PipCorner.bottomRight), const Offset(284, 558));
    });

    test('follows shrinking insets', () {
      // What happens when the call controls fade out.
      expect(offsetFor(PipCorner.topRight, top: 0), const Offset(284, 16));
      expect(
        offsetFor(PipCorner.bottomRight, bottom: 0),
        const Offset(284, 708),
      );
    });

    test('keeps the pip on screen when the insets exceed the viewport', () {
      final result = offsetFor(
        PipCorner.bottomRight,
        size: const Size(320, 320),
        top: 200,
        bottom: 200,
      );

      expect(result.dx, 214.0);
      // Reserved areas leave no room, so the position collapses to the top of
      // the allowed range rather than going off-screen.
      expect(result.dy, 216.0);
    });
  });
}
