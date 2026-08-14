import 'dart:io';

import '../channels.dart';
import '../config/call_native_timeouts.dart';
import '../logging/call_logger.dart';

/// State of the WebRTC audio session, for diagnosing calls that connect
/// perfectly and carry no sound.
class AudioSessionDiagnostics {
  const AudioSessionDiagnostics({
    required this.isActive,
    required this.isAudioEnabled,
    required this.activationCount,
    required this.category,
    required this.mode,
    this.lastActivatedAt,
  });

  final bool isActive;
  final bool isAudioEnabled;

  /// How many times the system activated the session this process. Zero
  /// during a CallKit-accepted call means the delegate chain is broken.
  final int activationCount;

  final String category;
  final String mode;
  final DateTime? lastActivatedAt;

  static AudioSessionDiagnostics fromJson(Map<String, Object?> json) {
    final lastMs = json['lastActivatedAtMs'];
    return AudioSessionDiagnostics(
      isActive: json['isActive'] as bool? ?? false,
      isAudioEnabled: json['isAudioEnabled'] as bool? ?? false,
      activationCount: json['activationCount'] as int? ?? 0,
      category: json['category'] as String? ?? '',
      mode: json['mode'] as String? ?? '',
      lastActivatedAt:
          lastMs is int ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null,
    );
  }

  @override
  String toString() =>
      'AudioSessionDiagnostics(active: $isActive, audioEnabled: '
      '$isAudioEnabled, activations: $activationCount, category: $category, '
      'mode: $mode, lastActivatedAt: $lastActivatedAt)';
}

/// Manual-mode control of the WebRTC audio session.
///
/// ## Why this is not automatic
///
/// On iOS, CallKit — not the app — owns `AVAudioSession` for a call it
/// presents. It activates the session and tells the app afterwards. If the
/// app also activates the session, the two fight and the call ends up with no
/// audio at all: everything else looks healthy, tracks publish, the peer
/// connection reports connected, and nobody hears anything.
///
/// So the rule is:
///
/// * call accepted through the system UI → [awaitActive], never [activate];
/// * call started from inside the app → [activate].
///
/// The chain that makes [awaitActive] complete runs through the host
/// `AppDelegate`: it must conform to `CallkitIncomingAppDelegate` and forward
/// `didActivateAudioSession`. If that forwarding is missing, [awaitActive]
/// times out and the call is silent — which is why the timeout is reported
/// through [CallLogger.recordError] rather than merely logged.
class CallAudioSession {
  CallAudioSession({
    required CallNativeTimeouts Function() timeouts,
    CallLogger logger = const SilentCallLogger(),
  })  : _timeouts = timeouts,
        _logger = logger;

  final CallNativeTimeouts Function() _timeouts;
  final CallLogger _logger;

  /// Activates the session for a call the app started itself.
  Future<void> activate({bool defaultToSpeaker = true}) async {
    try {
      await CallNativeChannels.main
          .invokeMethod<void>(CallNativeMethods.activateAudio, {
        'defaultToSpeaker': defaultToSpeaker,
      });
    } catch (e, st) {
      _logger.recordError(e, st, reason: 'activate audio session');
    }
  }

  Future<void> deactivate() async {
    try {
      await CallNativeChannels.main.invokeMethod<void>(
        CallNativeMethods.deactivateAudio,
      );
    } catch (e, st) {
      _logger.recordError(e, st, reason: 'deactivate audio session');
    }
  }

  /// Waits for the system to activate the session, for a call accepted
  /// through the system UI.
  ///
  /// Returns `false` on timeout. A `false` here is the signature of a silent
  /// call — see the class doc.
  Future<bool> awaitActive({Duration? timeout}) async {
    if (!Platform.isIOS) return true;
    final wait = timeout ?? _timeouts().audioSessionWait;
    try {
      final active = await CallNativeChannels.main
              .invokeMethod<bool>(CallNativeMethods.awaitAudioSessionActive, {
            'timeoutMs': wait.inMilliseconds,
          }) ??
          false;
      if (!active) {
        _logger.recordError(
          StateError('audio session not active after ${wait.inMilliseconds}ms'),
          StackTrace.current,
          reason:
              'CallKit did not activate AVAudioSession — check that the host '
              'AppDelegate conforms to CallkitIncomingAppDelegate and '
              'forwards didActivateAudioSession',
        );
      }
      return active;
    } catch (e, st) {
      _logger.recordError(e, st, reason: 'awaitAudioSessionActive');
      return false;
    }
  }

  Future<AudioSessionDiagnostics?> diagnostics() async {
    try {
      final raw = await CallNativeChannels.main
          .invokeMapMethod<String, Object?>(CallNativeMethods.audioDiagnostics);
      if (raw == null) return null;
      return AudioSessionDiagnostics.fromJson(raw);
    } catch (e, st) {
      _logger.recordError(e, st, reason: 'audioDiagnostics');
      return null;
    }
  }
}
