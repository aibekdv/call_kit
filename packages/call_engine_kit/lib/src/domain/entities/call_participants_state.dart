import 'package:equatable/equatable.dart';

import 'unset.dart';

/// Who else is on the call.
class CallParticipantsState extends Equatable {
  const CallParticipantsState({
    this.identities = const [],
    this.names = const {},
    this.activeSpeakerIdentity,
    this.isSpeaking = false,
  });

  static const empty = CallParticipantsState();

  /// Remote participants, stably sorted so the layout does not reshuffle on
  /// every update.
  final List<String> identities;

  /// identity → display name.
  ///
  /// A cache, and deliberately one that never regresses: the media server can
  /// briefly report an empty name for a participant it already named, and
  /// letting that through makes names flicker away mid-call.
  final Map<String, String> names;

  /// Who is talking, for speaker view.
  final String? activeSpeakerIdentity;

  /// Whether the local user is the one talking.
  final bool isSpeaking;

  /// Display name for [identity], falling back to the identity itself.
  String nameOf(String identity) => names[identity] ?? identity;

  CallParticipantsState copyWith({
    List<String>? identities,
    Map<String, String>? names,
    Object? activeSpeakerIdentity = unset,
    bool? isSpeaking,
  }) =>
      CallParticipantsState(
        identities: identities ?? this.identities,
        names: names ?? this.names,
        activeSpeakerIdentity: resolve(
          activeSpeakerIdentity,
          this.activeSpeakerIdentity,
        ),
        isSpeaking: isSpeaking ?? this.isSpeaking,
      );

  @override
  List<Object?> get props => [
        identities,
        names,
        activeSpeakerIdentity,
        isSpeaking,
      ];
}
