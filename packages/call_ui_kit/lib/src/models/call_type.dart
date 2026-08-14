/// Enumerations for call characteristics.
library;

/// The type of call being made or received.
enum CallType {
  /// An audio-only call with no video stream.
  audio,

  /// A video call where camera streams are displayed.
  video,
}

/// Signal strength level for a participant's network connection.
enum SignalStrength {
  /// Full signal — the connection is strong and stable.
  excellent,

  /// Moderate signal — minor quality degradation may occur.
  good,

  /// Weak signal — noticeable quality issues are likely.
  poor,

  /// No signal — the participant appears to be disconnected.
  none,
}
