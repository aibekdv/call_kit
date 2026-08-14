/// Every deadline the engine enforces.
///
/// Injected rather than hardcoded so they can be tuned per app — and so the
/// timer logic can be driven by `fake_async` in tests instead of by waiting.
class CallTimeouts {
  const CallTimeouts({
    this.answerGuard = const Duration(seconds: 15),
    this.connecting = const Duration(seconds: 30),
    this.ringing = const Duration(seconds: 40),
    this.reconnect = const Duration(seconds: 45),
    this.heartbeat = const Duration(seconds: 30),
    this.outgoingCloseDelay = const Duration(seconds: 3),
    this.clear = const Duration(seconds: 5),
  });

  /// How long an accept may take before it is treated as failed.
  ///
  /// Covers the gap between the user pressing Accept on the system UI and the
  /// app actually joining — a stretch where the phone has stopped ringing and
  /// nothing is on screen yet.
  final Duration answerGuard;

  /// How long joining the media room may take.
  final Duration connecting;

  /// How long we ring before giving up. Should be at or below the server's own
  /// ring window, or the caller waits for a call the server already cancelled.
  final Duration ringing;

  /// How long to try re-establishing media before declaring the call lost.
  final Duration reconnect;

  /// How often to tell the server the call is still alive.
  final Duration heartbeat;

  /// How long the ended-call screen stays up after an outgoing call fails, so
  /// the user can read why.
  final Duration outgoingCloseDelay;

  /// Budget for tearing a call down. Everything cleanup does is best-effort;
  /// past this the engine resets its state regardless, rather than leaving the
  /// user stuck on a call that is already over.
  final Duration clear;

  CallTimeouts copyWith({
    Duration? answerGuard,
    Duration? connecting,
    Duration? ringing,
    Duration? reconnect,
    Duration? heartbeat,
    Duration? outgoingCloseDelay,
    Duration? clear,
  }) =>
      CallTimeouts(
        answerGuard: answerGuard ?? this.answerGuard,
        connecting: connecting ?? this.connecting,
        ringing: ringing ?? this.ringing,
        reconnect: reconnect ?? this.reconnect,
        heartbeat: heartbeat ?? this.heartbeat,
        outgoingCloseDelay: outgoingCloseDelay ?? this.outgoingCloseDelay,
        clear: clear ?? this.clear,
      );
}
