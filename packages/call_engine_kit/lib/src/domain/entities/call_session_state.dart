import 'package:equatable/equatable.dart';

import 'call_lifecycle_state.dart';
import 'unset.dart';

/// What the call is and where it stands.
class CallSessionState extends Equatable {
  const CallSessionState({
    required this.status,
    this.callId,
    this.roomName,
    this.displayName,
    this.avatarUrl,
    this.isVideo = false,
    this.isGroup = false,
    this.activeParticipants = 0,
    this.error,
    this.permissionDenied = false,
  });

  static const idle = CallSessionState(status: CallLifecycleState.idle);

  final CallLifecycleState status;

  /// Your server's call id, once one exists. Absent for an incoming call that
  /// has been announced but not yet identified.
  final String? callId;

  /// Media room to join.
  final String? roomName;

  /// Who the user thinks they are talking to: the other party, or the group.
  final String? displayName;
  final String? avatarUrl;

  final bool isVideo;
  final bool isGroup;

  /// How many people are on the call, including the local user.
  final int activeParticipants;

  /// Set when [status] is [CallLifecycleState.failed]; ready to show.
  final String? error;

  /// The user refused microphone or camera access. Distinct from [error]
  /// because it is fixed in Settings, not by trying again.
  final bool permissionDenied;

  /// Whether there is a call to show. False once it has ended or failed.
  bool get hasActiveCall =>
      !status.isTerminal && status != CallLifecycleState.idle;

  CallSessionState copyWith({
    CallLifecycleState? status,
    Object? callId = unset,
    Object? roomName = unset,
    Object? displayName = unset,
    Object? avatarUrl = unset,
    bool? isVideo,
    bool? isGroup,
    int? activeParticipants,
    Object? error = unset,
    bool? permissionDenied,
  }) =>
      CallSessionState(
        status: status ?? this.status,
        callId: resolve(callId, this.callId),
        roomName: resolve(roomName, this.roomName),
        displayName: resolve(displayName, this.displayName),
        avatarUrl: resolve(avatarUrl, this.avatarUrl),
        isVideo: isVideo ?? this.isVideo,
        isGroup: isGroup ?? this.isGroup,
        activeParticipants: activeParticipants ?? this.activeParticipants,
        error: resolve(error, this.error),
        permissionDenied: permissionDenied ?? this.permissionDenied,
      );

  @override
  List<Object?> get props => [
        status,
        callId,
        roomName,
        displayName,
        avatarUrl,
        isVideo,
        isGroup,
        activeParticipants,
        error,
        permissionDenied,
      ];
}
