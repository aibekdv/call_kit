import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'history/call_history_store.dart';
import 'session/app_session.dart';
import 'signaling/dev_signaling_client.dart';
import 'theme/demo_call_theme.dart';

/// Puts the three packages together.
///
/// The whole integration is this function. Everything after it is an ordinary
/// app that happens to be able to make calls.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = await AppSession.load();

  // Reads the identity from the session on each request rather than taking a
  // copy: the user signs in after this point.
  final signaling = DevSignalingClient(session: session);

  final engine = await CallEngine.create(
    CallEngineConfig(
      signaling: signaling,
      // A resolver, not a value: switching language on the Diagnostics page
      // takes effect without rebuilding the engine, mid-call included.
      strings: () => demoEngineStrings(session.locale),
      logger: const ConsoleCallLogger(name: 'call_engine_kit'),
    ),
    nativeConfig: _nativeConfig(session),
  );

  // Re-push the native config whenever the language changes. It is persisted,
  // and a call arriving while the app is dead is drawn from whatever was
  // written last — so this is the difference between an incoming call in the
  // user's language and one in the previous one.
  session.addListener(() {
    CallNativeKit.instance.configure(_nativeConfig(session));
  });

  runApp(
    CallKitExampleApp(
      engine: engine,
      session: session,
      signaling: signaling,
      history: CallHistoryStore(engine.controller),
    ),
  );
}

CallNativeConfig _nativeConfig(AppSession session) => CallNativeConfig(
      strings: demoNativeStrings(session.locale),
      branding: const CallNativeBranding(
        appName: 'call_kit',
        androidBackgroundColor: '#10131A',
        androidActionColor: '#30A46C',
      ),
      logger: const ConsoleCallLogger(name: 'call_native_kit'),
    );
