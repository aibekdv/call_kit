import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import '../domain/entities/call_media_state.dart';
import '../domain/entities/call_participants_state.dart';
import '../domain/entities/call_session_state.dart';

/// Recomputes who is on the call from the room, once per burst.
///
/// A single participant joining produces a flurry of events — connected, then
/// a track subscribed per stream, then a mute state per track. Recomputing on
/// each one rebuilds every video tile several times for what the user sees as
/// one arrival, so the work is coalesced into a microtask.
class ParticipantsStateReducer {
  ParticipantsStateReducer({
    required this.media,
    required this.participants,
    required this.session,
    required Room? Function() roomGetter,
  }) : _roomGetter = roomGetter;

  final ValueNotifier<CallMediaState> media;
  final ValueNotifier<CallParticipantsState> participants;
  final ValueNotifier<CallSessionState> session;
  final Room? Function() _roomGetter;

  bool _scheduled = false;

  /// Queues a recompute, collapsing everything that arrives before it runs.
  void schedule() {
    if (_scheduled) return;
    _scheduled = true;
    Future.microtask(() {
      _scheduled = false;
      recomputeNow();
    });
  }

  /// Recomputes immediately.
  ///
  /// Needed right after connecting: participants already in the room when we
  /// arrive never produce a "connected" event, so waiting for one leaves the
  /// call looking empty.
  void recomputeNow() {
    final room = _roomGetter();
    if (room == null) return;

    final remotes = room.remoteParticipants.values.toList();

    final hasRemoteVideo = remotes.any(
      (participant) => participant.videoTrackPublications.any(
        (publication) => !publication.muted && publication.track != null,
      ),
    );

    // Stable order, so tiles do not swap places on an unrelated update.
    remotes.sort((a, b) => a.identity.compareTo(b.identity));
    final identities = remotes
        .map((participant) => participant.identity)
        .toList(growable: false);

    final previousSpeaker = participants.value.activeSpeakerIdentity;
    media.value = media.value.copyWith(hasRemoteVideo: hasRemoteVideo);
    participants.value = participants.value.copyWith(
      identities: identities,
      names: _mergeNames(remotes, participants.value.names),
      // Drop a speaker who has left, keep one who has not.
      activeSpeakerIdentity:
          identities.contains(previousSpeaker) ? previousSpeaker : null,
    );
    session.value = session.value.copyWith(
      activeParticipants: remotes.length + 1,
    );
  }

  /// Merges live names over the cache, never the other way round.
  ///
  /// The server can briefly report an empty name for a participant it already
  /// named, and letting that through makes names flicker away mid-call.
  Map<String, String> _mergeNames(
    List<RemoteParticipant> remotes,
    Map<String, String> cache,
  ) {
    final merged = <String, String>{};
    for (final participant in remotes) {
      final live = participant.name.trim();
      final cached = cache[participant.identity];
      merged[participant.identity] =
          live.isNotEmpty && live != participant.identity
              ? live
              : (cached != null && cached.isNotEmpty
                  ? cached
                  : participant.identity);
    }
    return merged;
  }
}
