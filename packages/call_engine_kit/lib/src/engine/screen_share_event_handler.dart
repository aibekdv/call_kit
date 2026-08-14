import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import '../domain/entities/call_screen_share_state.dart';

/// Keeps [CallScreenShareState] in step with what the room is publishing.
///
/// Only one share is shown at a time, so the interesting cases are the
/// hand-overs: when the current sharer stops, somebody else may already be
/// sharing, and the UI should switch rather than blank.
class ScreenShareEventHandler {
  ScreenShareEventHandler({
    required this.screenShare,
    required Room? Function() roomGetter,
  }) : _roomGetter = roomGetter;

  final ValueNotifier<CallScreenShareState> screenShare;
  final Room? Function() _roomGetter;

  void onRemoteStarted(String participantIdentity) {
    // First one wins: a second sharer does not take the screen from the first.
    if (screenShare.value.isActive) return;
    screenShare.value = screenShare.value.copyWith(
      isActive: true,
      participantIdentity: participantIdentity,
    );
  }

  void onRemoteStopped(String participantIdentity) {
    final next = _findNextSharer(excluding: participantIdentity);
    screenShare.value = next != null
        ? screenShare.value.copyWith(participantIdentity: next)
        : screenShare.value
            .copyWith(isActive: false, participantIdentity: null);
  }

  void onLocalPublished() {
    screenShare.value = screenShare.value.copyWith(
      isLocalSharing: true,
      isActive: true,
      participantIdentity: _roomGetter()?.localParticipant?.identity,
    );
  }

  void onLocalUnpublished() {
    final localIdentity = _roomGetter()?.localParticipant?.identity ?? '';
    final next = _findNextSharer(excluding: localIdentity);
    screenShare.value = screenShare.value.copyWith(
      isLocalSharing: false,
      isActive: next != null,
      participantIdentity: next,
    );
  }

  String? _findNextSharer({required String excluding}) {
    final room = _roomGetter();
    if (room == null) return null;

    final local = room.localParticipant;
    if (local != null &&
        local.identity != excluding &&
        local.isScreenShareEnabled()) {
      return local.identity;
    }
    for (final participant in room.remoteParticipants.values) {
      if (participant.identity == excluding) continue;
      if (participant.isScreenShareEnabled()) return participant.identity;
    }
    return null;
  }
}
