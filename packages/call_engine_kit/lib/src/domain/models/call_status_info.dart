import 'package:equatable/equatable.dart';

/// What the server currently thinks of a call.
enum CallLiveStatus {
  /// Announced, nobody has answered.
  ringing,

  /// At least two participants are connected.
  active,

  /// Over.
  ended,

  /// The server did not say, or said something this package does not model.
  unknown,
}

/// A server's answer to "is this call still worth ringing for?".
class CallStatusInfo extends Equatable {
  const CallStatusInfo({
    required this.status,
    this.isVideo,
    this.isGroup,
    this.startedBy,
    this.endReason,
  });

  final CallLiveStatus status;
  final bool? isVideo;
  final bool? isGroup;
  final String? startedBy;

  /// Why it ended, when it has: `timeout`, `declined`, `caller_cancelled`.
  final String? endReason;

  bool get isStillRinging => status == CallLiveStatus.ringing;
  bool get isActive => status == CallLiveStatus.active;

  @override
  List<Object?> get props => [status, isVideo, isGroup, startedBy, endReason];
}
