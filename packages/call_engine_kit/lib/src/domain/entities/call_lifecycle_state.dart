/// Where a call is in its life.
///
/// Transitions between these are validated — see `CallStateMachine`. The rules
/// exist because a call has several independent sources of truth racing each
/// other: the user, the signalling server, the media server and the system
/// call UI can all report an outcome, sometimes in the wrong order.
enum CallLifecycleState {
  /// No call.
  idle,

  /// We are calling someone and they have not answered.
  outgoingRinging,

  /// Someone is calling us.
  incomingRinging,

  /// Answered on both sides; joining the media room.
  connecting,

  /// Media is flowing.
  inCall,

  /// Media dropped and is being re-established. Still the same call.
  reconnecting,

  /// Over, for any ordinary reason.
  ended,

  /// Over because something broke. `CallSessionState.error` says what.
  failed;

  /// Whether the call is over, one way or another.
  bool get isTerminal =>
      this == CallLifecycleState.ended || this == CallLifecycleState.failed;

  /// Whether the phone is ringing, on either end.
  bool get isRinging =>
      this == CallLifecycleState.outgoingRinging ||
      this == CallLifecycleState.incomingRinging;
}
