/// The shared mounting surface for externally-provided video widgets.
library;

import 'package:flutter/material.dart';

/// Hosts a video widget supplied by the application on an opaque, fully
/// expanded surface.
///
/// Renderer widgets (`RTCVideoView` and friends) can legitimately paint
/// nothing — while a texture is being attached, or after it was disposed
/// during a reconnect. Without a backing, that shows as a transparent hole
/// punched through the call UI; with one, it reads as a black video surface,
/// which is what every native call app does.
///
/// A paint-time exception in the child produces the same result: Flutter
/// catches and reports it per render object (see
/// `RenderObject._paintWithContext`), the child simply paints nothing, and the
/// backing remains. An ancestor cannot intercept that exception, so this
/// widget deliberately does not pretend to.
class VideoSurface extends StatelessWidget {
  /// The externally-provided video widget.
  final Widget child;

  /// The colour painted behind [child].
  final Color backgroundColor;

  /// Creates a [VideoSurface].
  const VideoSurface({
    super.key,
    required this.child,
    this.backgroundColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: SizedBox.expand(child: child),
    );
  }
}
