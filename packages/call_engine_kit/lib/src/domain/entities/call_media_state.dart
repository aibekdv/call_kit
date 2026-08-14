import 'package:equatable/equatable.dart';

import 'call_audio_route.dart';

/// Microphone, camera and audio routing.
class CallMediaState extends Equatable {
  const CallMediaState({
    this.isMuted = false,
    this.audioRoute = CallAudioRoute.earpiece,
    this.isLocalVideoEnabled = true,
    this.hasRemoteVideo = false,
  });

  static const initial = CallMediaState();

  final bool isMuted;
  final CallAudioRoute audioRoute;
  final bool isLocalVideoEnabled;

  /// Whether anybody else is sending video. Drives the choice between a video
  /// layout and an avatar.
  final bool hasRemoteVideo;

  bool get isSpeakerOn => audioRoute == CallAudioRoute.speaker;

  CallMediaState copyWith({
    bool? isMuted,
    CallAudioRoute? audioRoute,
    bool? isLocalVideoEnabled,
    bool? hasRemoteVideo,
  }) =>
      CallMediaState(
        isMuted: isMuted ?? this.isMuted,
        audioRoute: audioRoute ?? this.audioRoute,
        isLocalVideoEnabled: isLocalVideoEnabled ?? this.isLocalVideoEnabled,
        hasRemoteVideo: hasRemoteVideo ?? this.hasRemoteVideo,
      );

  @override
  List<Object?> get props => [
        isMuted,
        audioRoute,
        isLocalVideoEnabled,
        hasRemoteVideo,
      ];
}
