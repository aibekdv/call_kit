import 'package:equatable/equatable.dart';

/// A request to start a call.
///
/// Deliberately says nothing about *who* the participants are beyond their
/// ids: mapping a chat room, a contact or a department to a list of ids is
/// the host app's job, and the one place where a call touches a domain model.
class CallInitiationRequest extends Equatable {
  const CallInitiationRequest({
    required this.participantIds,
    required this.isVideo,
    this.isGroup = false,
    this.title,
    this.participantNames = const {},
    this.externalId,
    this.metadata = const {},
  });

  /// Who to call. Must not be empty.
  final List<String> participantIds;

  final bool isVideo;

  /// Whether this is a group call. Group calls survive a participant leaving;
  /// one-to-one calls do not.
  final bool isGroup;

  /// Group name, shown by the callees' system call UI.
  final String? title;

  /// id → display name, so the callees see names rather than ids before they
  /// have loaded any profiles.
  final Map<String, String> participantNames;

  /// Your own id for whatever this call belongs to — a chat room, a meeting.
  /// Passed through to the server untouched.
  final String? externalId;

  /// Anything else your server wants, sent along verbatim.
  final Map<String, Object?> metadata;

  @override
  List<Object?> get props => [
        participantIds,
        isVideo,
        isGroup,
        title,
        participantNames,
        externalId,
        metadata,
      ];
}
