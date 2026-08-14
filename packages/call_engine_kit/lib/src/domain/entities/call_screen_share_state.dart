import 'package:equatable/equatable.dart';

import 'unset.dart';

/// Whether anybody is sharing their screen.
class CallScreenShareState extends Equatable {
  const CallScreenShareState({
    this.isActive = false,
    this.participantIdentity,
    this.isLocalSharing = false,
  });

  static const inactive = CallScreenShareState();

  final bool isActive;

  /// Who is sharing.
  final String? participantIdentity;

  /// Whether it is the local user. Only one participant may share at a time,
  /// so this also means "the share button is ours to stop".
  final bool isLocalSharing;

  CallScreenShareState copyWith({
    bool? isActive,
    Object? participantIdentity = unset,
    bool? isLocalSharing,
  }) =>
      CallScreenShareState(
        isActive: isActive ?? this.isActive,
        participantIdentity:
            resolve(participantIdentity, this.participantIdentity),
        isLocalSharing: isLocalSharing ?? this.isLocalSharing,
      );

  @override
  List<Object?> get props => [isActive, participantIdentity, isLocalSharing];
}
