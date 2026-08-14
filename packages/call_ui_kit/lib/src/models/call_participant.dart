/// Data model representing a single participant in a call.
library;

import 'package:flutter/widgets.dart';

import 'call_type.dart';

/// Holds all information about a single call participant.
///
/// Each participant has identity data ([id], [displayName], [avatarUrl]),
/// media state ([isMuted], [isCameraOff], [isSpeaking]), and optional
/// widget references for rendering their video and screen-share streams.
///
/// Use [copyWith] to derive a new instance with one or more fields changed.
class CallParticipant {
  /// A unique identifier for this participant (e.g. user ID or peer ID).
  final String id;

  /// The name shown on the participant's tile and in the participant list.
  final String displayName;

  /// An optional URL pointing to the participant's avatar image.
  ///
  /// When `null`, the UI should fall back to initials or a default icon.
  final String? avatarUrl;

  /// Whether the participant's microphone is currently muted.
  final bool isMuted;

  /// Whether the participant's camera is currently turned off.
  final bool isCameraOff;

  /// Whether the participant is actively speaking.
  ///
  /// Typically derived from audio-level detection and used to highlight
  /// the participant's tile with a speaking border.
  final bool isSpeaking;

  /// Whether the participant is currently sharing their screen.
  final bool isScreenSharing;

  /// Whether this participant is the host or organiser of the call.
  final bool isHost;

  /// Whether this participant represents the local (current) user.
  final bool isLocalUser;

  /// The network signal strength for this participant's connection.
  final SignalStrength signalStrength;

  /// An optional widget that renders this participant's live video stream.
  ///
  /// Provided by the integrating application; the kit places it inside
  /// the participant tile.
  final Widget? videoWidget;

  /// An optional widget that renders this participant's screen-share stream.
  final Widget? screenShareWidget;

  /// Creates a [CallParticipant] with the given properties.
  ///
  /// [id] and [displayName] are required. All boolean flags default
  /// to `false`, and [signalStrength] defaults to [SignalStrength.excellent].
  const CallParticipant({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.isMuted = false,
    this.isCameraOff = false,
    this.isSpeaking = false,
    this.isScreenSharing = false,
    this.isHost = false,
    this.isLocalUser = false,
    this.signalStrength = SignalStrength.excellent,
    this.videoWidget,
    this.screenShareWidget,
  });

  /// Compares participants by identity and media state only.
  ///
  /// [videoWidget] and [screenShareWidget] are intentionally excluded because
  /// Flutter widgets do not have meaningful equality semantics — two identical
  /// widget trees are distinct object references. Including them would cause
  /// every rebuild to report a change, defeating optimisation checks in
  /// [didUpdateWidget] and list-equality comparisons.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallParticipant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          avatarUrl == other.avatarUrl &&
          isMuted == other.isMuted &&
          isCameraOff == other.isCameraOff &&
          isSpeaking == other.isSpeaking &&
          isScreenSharing == other.isScreenSharing &&
          isHost == other.isHost &&
          isLocalUser == other.isLocalUser &&
          signalStrength == other.signalStrength;

  @override
  int get hashCode => Object.hash(
        id,
        displayName,
        avatarUrl,
        isMuted,
        isCameraOff,
        isSpeaking,
        isScreenSharing,
        isHost,
        isLocalUser,
        signalStrength,
      );

  /// Returns a copy of this participant with the given fields replaced
  /// by new values.
  ///
  /// To explicitly set a nullable field to `null`, pass the sentinel
  /// [CallParticipant.absent]. For example:
  /// ```dart
  /// participant.copyWith(videoWidget: CallParticipant.absent)
  /// ```
  CallParticipant copyWith({
    String? id,
    String? displayName,
    Object? avatarUrl = _sentinel,
    bool? isMuted,
    bool? isCameraOff,
    bool? isSpeaking,
    bool? isScreenSharing,
    bool? isHost,
    bool? isLocalUser,
    SignalStrength? signalStrength,
    Object? videoWidget = _sentinel,
    Object? screenShareWidget = _sentinel,
  }) {
    return CallParticipant(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: identical(avatarUrl, _sentinel)
          ? this.avatarUrl
          : avatarUrl as String?,
      isMuted: isMuted ?? this.isMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isHost: isHost ?? this.isHost,
      isLocalUser: isLocalUser ?? this.isLocalUser,
      signalStrength: signalStrength ?? this.signalStrength,
      videoWidget: identical(videoWidget, _sentinel)
          ? this.videoWidget
          : videoWidget as Widget?,
      screenShareWidget: identical(screenShareWidget, _sentinel)
          ? this.screenShareWidget
          : screenShareWidget as Widget?,
    );
  }

  /// Sentinel value used to explicitly set a nullable field to `null`
  /// in [copyWith].
  static const Object absent = _sentinel;

  @override
  String toString() => 'CallParticipant(id: $id, displayName: $displayName, '
      'muted: $isMuted, cameraOff: $isCameraOff, '
      'speaking: $isSpeaking, signal: ${signalStrength.name})';
}

const Object _sentinel = Object();
