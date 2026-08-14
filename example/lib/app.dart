import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:call_engine_kit/overlay.dart';
import 'package:flutter/material.dart';

import 'contacts/contacts_page.dart';
import 'diagnostics/diagnostics_page.dart';
import 'history/call_history_store.dart';
import 'history/history_page.dart';
import 'session/app_session.dart';
import 'session/sign_in_page.dart';
import 'signaling/dev_signaling_client.dart';
import 'theme/demo_call_theme.dart';

/// The app shell.
///
/// The only call-related thing here is [CallOverlay] in `MaterialApp.builder`:
/// that one line is what puts a call over every screen. Everything else is an
/// ordinary app.
class CallKitExampleApp extends StatelessWidget {
  const CallKitExampleApp({
    required this.engine,
    required this.session,
    required this.signaling,
    required this.history,
    super.key,
  });

  final CallEngine engine;
  final AppSession session;
  final DevSignalingClient signaling;
  final CallHistoryStore history;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: session,
        builder: (context, _) => MaterialApp(
          title: 'call_kit',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF5B6CFF),
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          // Through `builder`, so the call sits above every route while still
          // inside the app's Directionality, Localizations and Theme.
          builder: (context, child) => CallOverlay(
            engine: engine,
            theme: demoCallTheme,
            strings: demoCallStrings(session.locale),
            localUserName: session.displayName,
            minimizedBuilder: (context, snapshot) =>
                _MinimizedCallBar(engine: engine, snapshot: snapshot),
            child: child!,
          ),
          home: session.isSignedIn
              ? _HomeShell(
                  engine: engine,
                  session: session,
                  signaling: signaling,
                  history: history,
                )
              : SignInPage(session: session),
        ),
      );
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({
    required this.engine,
    required this.session,
    required this.signaling,
    required this.history,
  });

  final CallEngine engine;
  final AppSession session;
  final DevSignalingClient signaling;
  final CallHistoryStore history;

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Signed in as ${widget.session.displayName}'),
          actions: [
            IconButton(
              onPressed: widget.session.signOut,
              icon: const Icon(Icons.logout),
              tooltip: 'Switch identity',
            ),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          children: [
            ContactsPage(
              engine: widget.engine,
              session: widget.session,
              signaling: widget.signaling,
            ),
            HistoryPage(store: widget.history),
            DiagnosticsPage(
              engine: widget.engine,
              session: widget.session,
              signaling: widget.signaling,
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.people), label: 'Contacts'),
            NavigationDestination(icon: Icon(Icons.history), label: 'History'),
            NavigationDestination(
              icon: Icon(Icons.monitor_heart),
              label: 'Diagnostics',
            ),
          ],
        ),
      );
}

/// What the overlay shows once the call is minimized.
class _MinimizedCallBar extends StatelessWidget {
  const _MinimizedCallBar({required this.engine, required this.snapshot});

  final CallEngine engine;
  final CallSnapshot snapshot;

  @override
  Widget build(BuildContext context) => Positioned(
        top: MediaQuery.paddingOf(context).top,
        left: 0,
        right: 0,
        child: Material(
          color: const Color(0xFF30A46C),
          child: InkWell(
            onTap: () => engine.controller.setOverlayExpanded(expanded: true),
            child: SizedBox(
              height: 36,
              child: Center(
                child: Text(
                  'Tap to return to ${snapshot.session.displayName ?? 'the call'}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
        ),
      );
}
