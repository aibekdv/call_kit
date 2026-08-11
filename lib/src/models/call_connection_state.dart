/// The connection state of an ongoing call.
library;

/// Describes the transport state of a call, used to surface a banner while
/// the connection is being established or recovered.
///
/// The kit is purely presentational: the host application decides when the
/// state changes and keeps its own renderers alive across a reconnect.
enum CallConnectionState {
  /// The call is connected and media is flowing.
  connected,

  /// The call is being established for the first time.
  connecting,

  /// The connection dropped and is being re-established.
  reconnecting,
}
