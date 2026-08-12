import 'package:flutter/widgets.dart';

import '../channels.dart';
import '../config/call_native_config.dart';
import '../models/call_push_message.dart';
import '../system/system_call_ui.dart';
import 'call_push_mapper.dart';
import 'incoming_push_gate.dart';

/// Rings the phone from the FCM background isolate.
///
/// Call it from your `@pragma('vm:entry-point')` background handler, before
/// anything else looks at the message:
///
/// ```dart
/// @pragma('vm:entry-point')
/// Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
///   const mapper = DefaultCallPushMapper();
///   if (mapper.isCallPush(message.data)) {
///     await handleBackgroundCallPush(message.data, sentTime: message.sentTime);
///     return;
///   }
///   // ... your other notifications
/// }
/// ```
///
/// ## What this isolate cannot do
///
/// It has no dependency injection, no localization and no access to anything
/// `main()` set up — it is a second Dart isolate started by the system just to
/// handle this message. So the config is read back from storage, where
/// [CallNativeKit.configure] left it. If the app has never run, the English
/// defaults are used, which is the correct trade: an English call screen beats
/// no call screen.
///
/// Returns the decision that was made, so hosts can log it.
Future<PushGateDecision> handleBackgroundCallPush(
  Map<String, Object?> data, {
  CallNativeConfig? config,
  CallPushMapper? mapper,
  String? fallbackCallerName,
  DateTime? sentTime,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final resolved =
      config ?? await CallNativeConfig.restore() ?? const CallNativeConfig();
  final push = (mapper ??
          DefaultCallPushMapper(
            fields: resolved.pushFields,
            incomingCallFallbackName: resolved.strings.incomingCallFallbackName,
          ))
      .parse(data, fallbackCallerName: fallbackCallerName);

  if (push is! IncomingCallPush) {
    // A cancellation reaching the background isolate means the call is over;
    // there is no ringing UI in this isolate to stop, and the foreground path
    // handles the running-app case.
    return PushGateDecision.notRinging;
  }

  final gate = IncomingPushGate(config: () => resolved);
  final decision = await gate.evaluate(push, sentTime: sentTime);
  resolved.logger.log('background push ${push.callId}: ${decision.name}');
  if (decision != PushGateDecision.show) return decision;

  await gate.markShown(push.callId);
  await SystemCallUi(config: () => resolved).showIncoming(push.toHandle());

  // Best effort: lets the app recover the call if the user accepts it from the
  // lock screen and the app then cold-starts. Plugin channels are only partly
  // attached here, so this may throw — which is fine, iOS writes the same
  // record natively and Android recovers through the system's active calls.
  try {
    await CallNativeChannels.main.invokeMethod<void>(
      CallNativeMethods.savePendingCall,
      push.toHandle().toJson(),
    );
  } catch (_) {}

  return decision;
}
