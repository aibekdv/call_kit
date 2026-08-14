import 'package:flutter/widgets.dart';
import 'package:livekit_client/livekit_client.dart';

/// Keeps one video widget per track alive across rebuilds.
///
/// A `VideoTrackRenderer` owns a texture. Building a new one on every frame
/// makes the video flicker as textures are created and disposed underneath it,
/// so renderers are cached and only dropped when their track really goes away.
class VideoRendererCache {
  final Map<String, Widget> _renderers = {};

  /// The widget for [track], created once and reused.
  Widget rendererFor(VideoTrack track,
      {VideoViewFit fit = VideoViewFit.cover}) {
    // Keyed by track identity: the same participant republishing after a
    // camera toggle is a different track and must not reuse the old texture.
    final key = '${track.sid}:${fit.name}';
    return _renderers.putIfAbsent(
      key,
      () => VideoTrackRenderer(track, fit: fit, key: ValueKey(key)),
    );
  }

  /// Drops renderers for tracks that are no longer published.
  void retain(Iterable<String> liveTrackSids) {
    final live = liveTrackSids.toSet();
    _renderers.removeWhere(
      (key, _) => !live.contains(key.split(':').first),
    );
  }

  void clear() => _renderers.clear();
}
