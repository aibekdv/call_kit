/// A draggable Picture-in-Picture overlay for local video.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/call_strings.dart';
import '../models/call_theme.dart';
import '../utils/pip_snap_calculator.dart';
import 'video_surface.dart';

/// A floating, draggable mini-view that displays the local participant's
/// video stream during a call.
///
/// When [child] is non-null it fills the PiP area; otherwise a dark background
/// with initials is rendered as a fallback. The frame is always opaque, so a
/// host video widget that stops painting shows black rather than turning
/// transparent.
///
/// The view snaps to the nearest screen corner on drag release. What it keeps
/// is the [PipCorner], not a pixel offset: the offset is derived from the
/// corner and the reserved insets on every build. So when [topBarHeight] or
/// [controlsHeight] change — the call controls fading out, a banner
/// appearing — the PiP animates into the space that just freed up and back
/// again, always staying in the corner the user put it in.
///
/// Callers that hide their controls should pass smaller insets while hidden;
/// see `CallScreen` for the reference wiring.
class FloatingPipView extends StatefulWidget {
  /// The local video widget rendered inside the PiP frame.
  final Widget? child;

  /// The display name used for the avatar fallback.
  final String displayName;

  /// The visual theme providing colours and sizing.
  final CallTheme theme;

  /// Localised strings.
  final CallStrings strings;

  /// The total screen size used for clamping and corner calculations.
  final Size screenSize;

  /// The height of the area reserved at the top of the screen.
  ///
  /// The PiP keeps clear of it. Pass a smaller value while the top bar is
  /// hidden and the PiP animates upwards into the freed space.
  final double topBarHeight;

  /// The height of the area reserved at the bottom of the screen.
  ///
  /// Behaves like [topBarHeight], at the other edge.
  final double controlsHeight;

  /// No longer used.
  ///
  /// The PiP used to subscribe to this and re-snap to the nearest corner on
  /// every visibility change, which recomputed the corner from stale pixels
  /// and could drift to a different one. Pass visibility-dependent
  /// [topBarHeight] and [controlsHeight] instead: the PiP animates to follow
  /// them and keeps its corner.
  @Deprecated(
    'No longer used; pass visibility-dependent topBarHeight/controlsHeight '
    'instead. This parameter has no effect and will be removed in a future '
    'release.',
  )
  final ValueListenable<bool>? controlsVisible;

  /// Called when the PiP view is tapped (e.g. to swap local/remote video).
  final VoidCallback? onTap;

  /// Creates a [FloatingPipView].
  const FloatingPipView({
    super.key,
    this.child,
    required this.displayName,
    required this.theme,
    required this.strings,
    required this.screenSize,
    required this.topBarHeight,
    required this.controlsHeight,
    @Deprecated(
      'No longer used; pass visibility-dependent topBarHeight/controlsHeight '
      'instead. This parameter has no effect and will be removed in a future '
      'release.',
    )
    this.controlsVisible,
    this.onTap,
  });

  @override
  State<FloatingPipView> createState() => _FloatingPipViewState();
}

class _FloatingPipViewState extends State<FloatingPipView> {
  static const _pipSize = Size(90, 120);
  static const _margin = 16.0;
  static const _borderRadius = 12.0;
  static const _borderWidth = 1.5;
  static const _snapDuration = Duration(milliseconds: 220);
  static const _snapCurve = Curves.easeOutCubic;

  /// The corner the PiP is anchored to — the actual stored position.
  PipCorner _corner = PipCorner.topRight;

  /// The free-form position while the user is dragging, and `null` at every
  /// other moment. When null the position is derived from [_corner], which is
  /// what lets the PiP follow the reserved insets without any listener.
  final ValueNotifier<Offset?> _dragOffset = ValueNotifier(null);

  @override
  void didUpdateWidget(FloatingPipView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The anchored position needs no maintenance — it is recomputed on every
    // build. Only an in-flight drag has to be brought back into bounds.
    final drag = _dragOffset.value;
    if (drag != null &&
        (oldWidget.screenSize != widget.screenSize ||
            oldWidget.topBarHeight != widget.topBarHeight ||
            oldWidget.controlsHeight != widget.controlsHeight)) {
      _dragOffset.value = _clampPosition(drag);
    }
  }

  @override
  void dispose() {
    _dragOffset.dispose();
    super.dispose();
  }

  Offset get _anchoredOffset => PipSnapCalculator.offsetForCorner(
        _corner,
        screenSize: widget.screenSize,
        pipSize: _pipSize,
        margin: _margin,
        topBarHeight: widget.topBarHeight,
        controlsHeight: widget.controlsHeight,
      );

  Offset _clampPosition(Offset offset) => PipSnapCalculator.clampToBounds(
        offset,
        screenSize: widget.screenSize,
        pipSize: _pipSize,
        margin: _margin,
        topBarHeight: widget.topBarHeight,
        controlsHeight: widget.controlsHeight,
      );

  void _onPanStart(DragStartDetails details) {
    _dragOffset.value = _anchoredOffset;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final current = _dragOffset.value ?? _anchoredOffset;
    _dragOffset.value = _clampPosition(current + details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    final released = _dragOffset.value;
    if (released != null) {
      setState(() {
        _corner = PipSnapCalculator.nearestCorner(
          current: released,
          screenSize: widget.screenSize,
          pipSize: _pipSize,
        );
      });
    }
    // Handing control back to the anchor animates the PiP into its corner.
    _dragOffset.value = null;
  }

  Widget _buildFallbackContent() {
    final initial = widget.displayName.isNotEmpty
        ? widget.displayName[0].toUpperCase()
        : '?';
    return ColoredBox(
      color: widget.theme.buttonBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: widget.theme.barBackground,
              child: Text(
                initial,
                style: TextStyle(
                  color: widget.theme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.strings.you,
              style: TextStyle(
                color: widget.theme.textPrimary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pipChild = GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: widget.onTap,
      child: Container(
        width: _pipSize.width,
        height: _pipSize.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_borderRadius),
          border: Border.all(
            color: widget.theme.textPrimary,
            width: _borderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_borderRadius - _borderWidth),
          // The opaque backing matters: a host renderer that stops painting
          // (a disposed texture after a reconnect, for example) would
          // otherwise leave a see-through hole framed by the border.
          child: widget.child != null
              ? VideoSurface(child: widget.child!)
              : _buildFallbackContent(),
        ),
      ),
    );

    return ValueListenableBuilder<Offset?>(
      valueListenable: _dragOffset,
      builder: (context, drag, child) {
        final position = drag ?? _anchoredOffset;
        return AnimatedPositioned(
          // A drag tracks the finger 1:1; everything else — snapping to a
          // corner, following the controls as they fade — is animated.
          duration: drag != null ? Duration.zero : _snapDuration,
          curve: _snapCurve,
          left: position.dx,
          top: position.dy,
          child: child!,
        );
      },
      child: RepaintBoundary(child: pipChild),
    );
  }
}
