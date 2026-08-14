import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:call_engine_kit/overlay.dart';
import 'package:flutter/material.dart';

import 'demo_signaling_client.dart';
import 'home_page.dart';

/// Runs a real call through `call_engine_kit`.
///
/// See [DemoSignalingClient] for how to point it at a LiveKit server.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final signaling = DemoSignalingClient.fromEnvironment();
  final engine = await CallEngine.create(
    CallEngineConfig(
      signaling: signaling,
      strings: () => const CallEngineStrings.english(),
      logger: const ConsoleCallLogger(name: 'call_engine_kit'),
    ),
    nativeConfig: const CallNativeConfig(
      branding: CallNativeBranding(appName: 'call_engine_kit'),
      logger: ConsoleCallLogger(name: 'call_native_kit'),
    ),
  );

  runApp(ExampleApp(engine: engine, signaling: signaling));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({required this.engine, required this.signaling, super.key});

  final CallEngine engine;
  final DemoSignalingClient signaling;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'call_engine_kit',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        // Through `builder`, so the call sits above every route while still
        // inside the app's Directionality, Localizations and Theme.
        builder: (context, child) => CallOverlay(
          engine: engine,
          theme: const CallTheme.whatsApp(),
          localUserName: 'You',
          minimizedBuilder: (context, snapshot) =>
              _MinimizedCall(engine: engine),
          child: child!,
        ),
        home: HomePage(engine: engine, signaling: signaling),
      );
}

/// What the overlay shows when the call is minimized.
class _MinimizedCall extends StatelessWidget {
  const _MinimizedCall({required this.engine});

  final CallEngine engine;

  @override
  Widget build(BuildContext context) => Positioned(
        top: MediaQuery.paddingOf(context).top,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.green.shade700,
          child: InkWell(
            onTap: () => engine.controller.setOverlayExpanded(expanded: true),
            child: const SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  'Tap to return to the call',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      );
}
