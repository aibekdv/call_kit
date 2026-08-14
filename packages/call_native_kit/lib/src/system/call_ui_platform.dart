import '../events/call_native_event.dart';
import '../models/call_handle.dart';

/// The operating system's own call UI: CallKit on iOS, a full-screen
/// notification on Android.
///
/// Implement it to fake the system in tests — the real implementation is
/// [SystemCallUi], reachable as `CallNativeKit.instance.systemUi`.
abstract interface class CallUiPlatform {
  /// Shows the incoming-call screen.
  Future<void> showIncoming(CallHandle call);

  /// Registers an outgoing call with the system so it appears in the call log
  /// and, on Android, in the notification shade.
  Future<void> startOutgoing(CallHandle call);

  /// Marks a registered call as connected.
  Future<void> setConnected(String callId);

  /// Replaces the incoming-call screen with an ongoing-call one.
  ///
  /// On iOS this is just [setConnected]. Android needs the whole call: its
  /// notification has to be rebuilt, not updated.
  Future<void> transitionToOngoing(CallHandle call);

  /// Ends one call.
  Future<void> end(String callId);

  /// Ends every call the system still believes is alive.
  Future<void> endAll();

  /// Whether *we* ended this call, rather than the user.
  ///
  /// [end] makes the system emit an `ended` action right back at us. Without
  /// this check a hang-up we initiated is indistinguishable from one the user
  /// initiated, and the app tears the call down twice.
  bool wasRecentlyEndedProgrammatically(String systemCallUuid);

  /// Everything the user does on the system call UI.
  Stream<SystemCallAction> get actions;

  /// Calls the system still considers alive. Used at cold start to find a
  /// call accepted on the lock screen.
  Future<List<CallHandle>> activeCalls();
}

/// Why [SystemCallUi.transitionToOngoing] could not simulate an accept on
/// Android.
///
/// Android has no supported way to turn an incoming-call notification into an
/// ongoing one, so the plugin reaches into `flutter_callkit_incoming` by
/// reflection. That is version-sensitive, and a `bool` would hide which step
/// broke after an upgrade.
enum SimulateAcceptResult {
  ok,
  notAndroid,
  pluginClassMissing,
  callNotFound,
  bundleMissing,
  broadcastFailed,
}
