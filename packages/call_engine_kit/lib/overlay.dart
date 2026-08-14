/// A ready-made call overlay, built on `call_ui_kit`.
///
/// Optional: `package:call_engine_kit/call_engine_kit.dart` is headless and
/// has no widgets at all. Import this only if you want the screens rather than
/// your own.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => CallOverlay(
///     engine: engine,
///     theme: const CallTheme(),
///     child: child!,
///   ),
/// )
/// ```
library;

export 'package:call_ui_kit/call_ui_kit.dart'
    show CallDimensions, CallStrings, CallTheme, CallType;

export 'src/ui/call_duration_ticker.dart'
    show CallDurationTicker, formatCallDuration;
export 'src/ui/call_overlay.dart' show CallOverlay;
export 'src/ui/call_participant_mapper.dart' show CallParticipantMapper;
export 'src/ui/video_renderer_cache.dart' show VideoRendererCache;
