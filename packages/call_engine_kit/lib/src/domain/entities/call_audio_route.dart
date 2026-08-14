/// Where call audio comes out.
enum CallAudioRoute {
  /// The phone held to the ear.
  earpiece,

  /// The loudspeaker.
  speaker,

  /// A connected Bluetooth device.
  bluetooth,
}

/// How a group call lays participants out.
enum CallViewMode {
  /// One large participant, the rest small.
  speaker,

  /// Everybody the same size.
  grid,
}
