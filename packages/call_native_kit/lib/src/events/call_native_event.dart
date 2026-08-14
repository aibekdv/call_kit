import '../models/call_handle.dart';
import '../models/call_push_message.dart';

/// Something the operating system or the network told us about a call.
sealed class CallNativeEvent {
  const CallNativeEvent({this.eventId});

  /// Stable id for de-duplication, when the source can produce a repeat.
  final String? eventId;
}

/// A call push arrived and the system call UI was shown for it.
final class IncomingCallReceived extends CallNativeEvent {
  const IncomingCallReceived({required this.push, super.eventId});

  final IncomingCallPush push;
}

/// The caller gave up, or the server ended the call before it was answered.
final class CallCancelledRemotely extends CallNativeEvent {
  const CallCancelledRemotely({required this.push, super.eventId});

  final CallCancelledPush push;
}

/// The user acted on the system call UI.
final class SystemCallActionReceived extends CallNativeEvent {
  const SystemCallActionReceived({required this.action, super.eventId});

  final SystemCallAction action;
}

/// Picture-in-picture was entered or left.
final class PipModeChanged extends CallNativeEvent {
  const PipModeChanged({required this.isInPip, super.eventId});

  final bool isInPip;
}

/// The user tapped a control on the picture-in-picture window.
final class PipActionReceived extends CallNativeEvent {
  const PipActionReceived({required this.action, super.eventId});

  final PipAction action;
}

/// Picture-in-picture could not attach the requested video track.
///
/// Reported instead of silently rendering a black frame: on iOS the track is
/// resolved through the Objective-C runtime, so this is what a `flutter_webrtc`
/// upgrade looks like from Dart.
final class PipAttachmentFailed extends CallNativeEvent {
  const PipAttachmentFailed(
      {required this.trackId, this.reason, super.eventId});

  final String? trackId;
  final String? reason;
}

/// The iOS PushKit token changed and must be re-registered with your server.
final class VoipPushTokenUpdated extends CallNativeEvent {
  const VoipPushTokenUpdated({required this.token, super.eventId});

  /// Empty when the token was invalidated.
  final String token;
}

/// What the user did on the system call UI.
enum SystemCallActionKind {
  incoming,
  start,
  accept,
  decline,
  ended,
  timeout,

  /// The user tapped a missed-call entry to call back.
  callback,
  toggleMute,
  toggleHold,
  toggleAudioSession,
}

/// A single interaction with the system call UI.
class SystemCallAction {
  const SystemCallAction({
    required this.kind,
    this.systemUuid,
    this.call,
    this.isMuted,
    this.isOnHold,
    this.isAudioSessionActive,
  });

  final SystemCallActionKind kind;

  /// The CallKit UUID, i.e. `systemCallUuid(call.callId)`.
  final String? systemUuid;

  /// Parsed from the CallKit `extra` payload; `null` if it was malformed.
  final CallHandle? call;

  final bool? isMuted;
  final bool? isOnHold;
  final bool? isAudioSessionActive;

  @override
  String toString() =>
      'SystemCallAction(${kind.name}, uuid: $systemUuid, call: $call)';
}

/// Controls the picture-in-picture window can offer.
enum PipAction { mute, hangup }
