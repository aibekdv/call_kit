/// Localisation strings used throughout the call UI.
library;

/// Contains every user-facing string displayed by the call UI kit.
///
/// All fields have sensible English defaults via [CallStrings.english].
///
/// Three fields are callbacks that accept runtime arguments:
/// - [isSharingScreen] — receives the participant's display name.
/// - [participantsCount] — receives the total number of participants.
/// - [moreParticipants] — receives the count of additional participants
///   not visible in the current view.
class CallStrings {
  /// Status text while the call is being placed.
  final String calling;

  /// Label shown when a participant's camera is off.
  final String cameraIsOff;

  /// Label for the local participant.
  final String you;

  /// Encryption indicator label.
  final String endToEndEncrypted;

  /// Label for the share-screen menu item.
  final String shareScreen;

  /// Label for the send-message menu item.
  final String sendMessage;

  /// Header text for the participants panel.
  final String participants;

  /// Label for the share-call-link menu item.
  final String shareCallLink;

  /// Label for the cancel button in bottom sheets.
  final String cancel;

  /// Label for the stop button on the screen-share banner.
  final String stop;

  /// Label for the stop-screen-sharing button in the personal call view.
  final String stopScreenSharing;

  /// Banner text when the local user is sharing their screen.
  final String youAreSharingYourScreen;

  /// Status text for a speaking participant.
  final String speaking;

  /// Status text for a muted participant.
  final String muted;

  /// Label for the "mute all" action in the participants panel.
  final String muteAll;

  /// Label for the invite button.
  final String invite;

  /// Label for the mute action.
  final String mute;

  /// Label for the unmute action.
  final String unmute;

  /// Label for the remove-from-call action.
  final String removeFromCall;

  /// Tooltip for the picture-in-picture button.
  final String pictureInPicture;

  /// Tooltip for the add-participant button.
  final String addParticipant;

  /// Tooltip for the flip-camera button.
  final String flipCamera;

  /// Tooltip for the effects button.
  final String effects;

  /// Status text for an incoming audio call.
  final String incomingAudioCall;

  /// Status text for an incoming video call.
  final String incomingVideoCall;

  /// Label for the decline button on the incoming call screen.
  final String decline;

  /// Label for the accept button on the incoming call screen.
  final String accept;

  /// Status text shown when the call has ended.
  final String callEnded;

  /// Banner text while the call is being established.
  final String connecting;

  /// Banner text while a dropped connection is being re-established.
  final String reconnecting;

  // ── Accessibility labels ──

  /// Semantic label for the end-call button.
  final String endCall;

  /// Semantic label for the speaker toggle button.
  final String speaker;

  /// Semantic label for the camera toggle button.
  final String camera;

  /// Semantic label for the more-options button.
  final String moreOptions;

  /// Returns a string indicating a participant is sharing their screen.
  final String Function(String name) isSharingScreen;

  /// Returns a formatted participant count string.
  final String Function(int count) participantsCount;

  /// Returns a label for overflow participants (e.g. "+3 more").
  final String Function(int count) moreParticipants;

  /// Creates a [CallStrings] instance with explicit values for every field.
  const CallStrings({
    required this.calling,
    required this.cameraIsOff,
    required this.you,
    required this.endToEndEncrypted,
    required this.shareScreen,
    required this.sendMessage,
    required this.participants,
    required this.shareCallLink,
    required this.cancel,
    required this.stop,
    this.stopScreenSharing = 'Stop screen sharing',
    required this.youAreSharingYourScreen,
    required this.speaking,
    required this.muted,
    required this.muteAll,
    required this.invite,
    required this.mute,
    required this.unmute,
    required this.removeFromCall,
    required this.pictureInPicture,
    required this.addParticipant,
    required this.flipCamera,
    required this.effects,
    required this.incomingAudioCall,
    required this.incomingVideoCall,
    required this.decline,
    required this.accept,
    required this.callEnded,
    this.connecting = 'Connecting…',
    this.reconnecting = 'Reconnecting…',
    this.endCall = 'End call',
    this.speaker = 'Speaker',
    this.camera = 'Camera',
    this.moreOptions = 'More options',
    required this.isSharingScreen,
    required this.participantsCount,
    required this.moreParticipants,
  });

  /// Cached English defaults. Avoids recreating the instance on every
  /// frame when no custom strings are provided.
  static final englishDefaults = CallStrings.english();

  /// Creates a [CallStrings] instance with sensible English defaults.
  factory CallStrings.english() {
    return CallStrings(
      calling: 'Calling\u2026',
      cameraIsOff: 'Camera is off',
      you: 'You',
      endToEndEncrypted: 'End-to-end encrypted',
      shareScreen: 'Share screen',
      sendMessage: 'Send message',
      participants: 'Participants',
      shareCallLink: 'Share call link',
      cancel: 'Cancel',
      stop: 'Stop',
      stopScreenSharing: 'Stop screen sharing',
      youAreSharingYourScreen: 'You are sharing your screen',
      speaking: 'Speaking',
      muted: 'Muted',
      muteAll: 'Mute all',
      invite: 'Invite',
      mute: 'Mute',
      unmute: 'Unmute',
      removeFromCall: 'Remove from call',
      pictureInPicture: 'Picture in picture',
      addParticipant: 'Add participant',
      flipCamera: 'Flip camera',
      effects: 'Effects',
      incomingAudioCall: 'Incoming audio call',
      incomingVideoCall: 'Incoming video call',
      decline: 'Decline',
      accept: 'Accept',
      callEnded: 'Call ended',
      connecting: 'Connecting…',
      reconnecting: 'Reconnecting…',
      endCall: 'End call',
      speaker: 'Speaker',
      camera: 'Camera',
      moreOptions: 'More options',
      isSharingScreen: (name) => '$name is sharing their screen',
      participantsCount: (count) =>
          '$count participant${count == 1 ? '' : 's'}',
      moreParticipants: (count) => '+$count more',
    );
  }
}
