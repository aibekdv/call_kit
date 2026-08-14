/// Every duration the plugin uses. Injected so they can be tuned per app and
/// driven by `fake_async` in tests.
class CallNativeTimeouts {
  const CallNativeTimeouts({
    this.systemRingDuration = const Duration(seconds: 35),
    this.pushStaleThreshold = const Duration(seconds: 60),
    this.pushClockSkew = const Duration(seconds: 5),
    this.burstSuppressionWindow = const Duration(seconds: 5),
    this.pendingCallTtl = const Duration(seconds: 90),
    this.programmaticEndWindow = const Duration(seconds: 5),
    this.audioSessionWait = const Duration(milliseconds: 500),
  });

  /// How long the system call UI rings before giving up. Keep it at or below
  /// the server's ring window, otherwise the callee sees a call the caller has
  /// already abandoned.
  final Duration systemRingDuration;

  /// A push older than this is dropped when it carries no explicit
  /// `timeout_at` / `created_at`.
  final Duration pushStaleThreshold;

  /// Tolerance for device-vs-server clock drift when checking staleness.
  final Duration pushClockSkew;

  /// A second push for the same call inside this window is ignored. Servers
  /// commonly send both an FCM and a PushKit notification for one call.
  final Duration burstSuppressionWindow;

  /// How long a call accepted on the lock screen stays recoverable after a
  /// cold start. Generous on purpose: engine startup can be slow.
  final Duration pendingCallTtl;

  /// Window in which an `ended` action is attributed to our own `end()` call
  /// rather than to the user.
  final Duration programmaticEndWindow;

  /// How long to wait for CallKit to activate `AVAudioSession` before
  /// publishing audio anyway.
  final Duration audioSessionWait;

  Map<String, Object?> toJson() => {
        'systemRingDurationMs': systemRingDuration.inMilliseconds,
        'pushStaleThresholdMs': pushStaleThreshold.inMilliseconds,
        'pushClockSkewMs': pushClockSkew.inMilliseconds,
        'burstSuppressionWindowMs': burstSuppressionWindow.inMilliseconds,
        'pendingCallTtlMs': pendingCallTtl.inMilliseconds,
        'programmaticEndWindowMs': programmaticEndWindow.inMilliseconds,
        'audioSessionWaitMs': audioSessionWait.inMilliseconds,
      };

  factory CallNativeTimeouts.fromJson(Map<String, Object?> json) {
    const fallback = CallNativeTimeouts();
    Duration read(String key, Duration or) {
      final ms = json[key];
      return ms is int ? Duration(milliseconds: ms) : or;
    }

    return CallNativeTimeouts(
      systemRingDuration: read(
        'systemRingDurationMs',
        fallback.systemRingDuration,
      ),
      pushStaleThreshold: read(
        'pushStaleThresholdMs',
        fallback.pushStaleThreshold,
      ),
      pushClockSkew: read('pushClockSkewMs', fallback.pushClockSkew),
      burstSuppressionWindow: read(
        'burstSuppressionWindowMs',
        fallback.burstSuppressionWindow,
      ),
      pendingCallTtl: read('pendingCallTtlMs', fallback.pendingCallTtl),
      programmaticEndWindow: read(
        'programmaticEndWindowMs',
        fallback.programmaticEndWindow,
      ),
      audioSessionWait: read('audioSessionWaitMs', fallback.audioSessionWait),
    );
  }
}
