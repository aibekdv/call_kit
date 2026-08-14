import 'package:call_ui_kit/call_ui_kit.dart' as ui;
import 'package:livekit_client/livekit_client.dart';

import '../domain/entities/call_media_state.dart';
import '../domain/entities/call_participants_state.dart';
import '../helpers/remote_video_track_finder.dart';
import 'video_renderer_cache.dart';

/// Turns a LiveKit room into the participants `call_ui_kit` draws.
class CallParticipantMapper {
  CallParticipantMapper({VideoRendererCache? renderers})
      : _renderers = renderers ?? VideoRendererCache();

  final VideoRendererCache _renderers;

  /// Everyone but the local user, in the order the engine settled on.
  List<ui.CallParticipant> remoteParticipants(
    Room room,
    CallParticipantsState state,
  ) {
    final byIdentity = room.remoteParticipants.values.fold(
      <String, RemoteParticipant>{},
      (map, participant) => map..[participant.identity] = participant,
    );

    final mapped = <ui.CallParticipant>[];
    for (final identity in state.identities) {
      final participant = byIdentity[identity];
      if (participant == null) continue;
      mapped.add(_map(participant, state));
    }
    _retainLiveRenderers(room);
    return mapped;
  }

  ui.CallParticipant _map(
    RemoteParticipant participant,
    CallParticipantsState state,
  ) {
    final camera = findParticipantCameraTrack(participant);
    return ui.CallParticipant(
      id: participant.identity,
      displayName: state.nameOf(participant.identity),
      isMuted: participant.audioTrackPublications.every((p) => p.muted),
      isCameraOff: camera == null,
      isSpeaking: state.activeSpeakerIdentity == participant.identity,
      isScreenSharing: participant.isScreenShareEnabled(),
      videoWidget: camera == null ? null : _renderers.rendererFor(camera),
    );
  }

  /// The local user, as `call_ui_kit` expects them.
  ui.CallParticipant localParticipant(
    Room? room,
    CallMediaState media,
    CallParticipantsState participants, {
    required String displayName,
    String? avatarUrl,
  }) {
    final local = room?.localParticipant;
    final camera = local == null ? null : _localCameraTrack(local);
    return ui.CallParticipant(
      id: local?.identity ?? 'local',
      displayName: displayName,
      avatarUrl: avatarUrl,
      isMuted: media.isMuted,
      isCameraOff: camera == null,
      isSpeaking: participants.isSpeaking,
      isScreenSharing: local?.isScreenShareEnabled() ?? false,
      isLocalUser: true,
      // Mirrored, because a self-view that is not mirrored looks wrong to the
      // person it is showing.
      videoWidget: camera == null
          ? null
          : _renderers.rendererFor(camera, fit: VideoViewFit.cover),
    );
  }

  VideoTrack? _localCameraTrack(LocalParticipant local) {
    for (final publication in local.videoTrackPublications) {
      if (!publication.muted &&
          !publication.isScreenShare &&
          publication.track != null) {
        return publication.track! as VideoTrack;
      }
    }
    return null;
  }

  /// The screen being shared, if any.
  ui.CallParticipant? screenSharer(
    Room room,
    CallParticipantsState state,
    String? sharerIdentity,
  ) {
    final track = findRemoteScreenShareTrack(
      room,
      sharerIdentity: sharerIdentity,
    );
    if (track == null || sharerIdentity == null) return null;
    return ui.CallParticipant(
      id: sharerIdentity,
      displayName: state.nameOf(sharerIdentity),
      isScreenSharing: true,
      screenShareWidget: _renderers.rendererFor(
        track,
        fit: VideoViewFit.contain,
      ),
    );
  }

  void _retainLiveRenderers(Room room) {
    final live = <String>[
      for (final participant in room.remoteParticipants.values)
        for (final publication in participant.videoTrackPublications)
          if (publication.track != null) publication.sid,
      for (final publication in room.localParticipant?.videoTrackPublications ??
          const <LocalTrackPublication<LocalVideoTrack>>[])
        if (publication.track != null) publication.sid,
    ];
    _renderers.retain(live);
  }

  void dispose() => _renderers.clear();
}
