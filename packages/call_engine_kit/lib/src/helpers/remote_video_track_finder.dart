import 'package:livekit_client/livekit_client.dart';

/// The remote camera track worth showing large.
///
/// Prefers [preferIdentity] — normally the active speaker — and falls back to
/// whoever is sending video. Screen shares are skipped: they are shown in
/// their own place, and treating one as somebody's camera puts a spreadsheet
/// where the user expects a face.
VideoTrack? findBestRemoteVideoTrack(Room room, {String? preferIdentity}) {
  if (preferIdentity != null) {
    for (final participant in room.remoteParticipants.values) {
      if (participant.identity != preferIdentity) continue;
      final track = findParticipantCameraTrack(participant);
      if (track != null) return track;
    }
  }
  for (final participant in room.remoteParticipants.values) {
    final track = findParticipantCameraTrack(participant);
    if (track != null) return track;
  }
  return null;
}

/// One participant's live camera track, never their screen share.
VideoTrack? findParticipantCameraTrack(RemoteParticipant participant) {
  for (final publication in participant.videoTrackPublications) {
    if (!publication.muted &&
        !publication.isScreenShare &&
        publication.track != null) {
      return publication.track! as VideoTrack;
    }
  }
  return null;
}

/// The screen share being presented — the counterpart of
/// [findBestRemoteVideoTrack], which deliberately ignores them.
VideoTrack? findRemoteScreenShareTrack(Room room, {String? sharerIdentity}) {
  if (sharerIdentity != null) {
    for (final participant in room.remoteParticipants.values) {
      if (participant.identity != sharerIdentity) continue;
      final track = _screenShareTrackOf(participant);
      if (track != null) return track;
    }
  }
  for (final participant in room.remoteParticipants.values) {
    final track = _screenShareTrackOf(participant);
    if (track != null) return track;
  }
  return null;
}

VideoTrack? _screenShareTrackOf(RemoteParticipant participant) {
  for (final publication in participant.videoTrackPublications) {
    if (!publication.muted &&
        publication.isScreenShare &&
        publication.track != null) {
      return publication.track! as VideoTrack;
    }
  }
  return null;
}
