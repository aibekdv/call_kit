import 'package:call_native_kit/call_native_kit.dart';
import 'package:flutter/material.dart';

import 'diagnostics_panel.dart';
import 'simulate_push_field.dart';

/// Manual test rig for `call_native_kit`.
///
/// The parts of a VoIP stack that cannot be unit-tested — the system call
/// screen, PushKit delivery, picture-in-picture, cold-start recovery — all
/// need a device and a human. This app is that harness.
void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final CallNativeKit _calls = CallNativeKit.instance;
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _calls.configure(
      const CallNativeConfig(
        branding: CallNativeBranding(appName: 'call_native_kit'),
        logger: ConsoleCallLogger(),
      ),
    );
    await _calls.initialize();
    _calls.events.listen((event) {
      if (!mounted) return;
      setState(() => _log.insert(0, _describe(event)));
    });
  }

  String _describe(CallNativeEvent event) => switch (event) {
        IncomingCallReceived(:final push) => 'incoming ${push.callId}',
        CallCancelledRemotely(:final push) => 'cancelled ${push.callId}',
        SystemCallActionReceived(:final action) =>
          'system ${action.kind.name} ${action.call?.callId ?? action.systemUuid}',
        PipModeChanged(:final isInPip) => 'pip ${isInPip ? 'entered' : 'left'}',
        PipActionReceived(:final action) => 'pip action ${action.name}',
        PipAttachmentFailed(:final trackId, :final reason) =>
          'pip attach failed $trackId: $reason',
        VoipPushTokenUpdated(:final token) =>
          'voip token ${token.isEmpty ? '(cleared)' : token.substring(0, 8)}',
      };

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'call_native_kit',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: Scaffold(
          appBar: AppBar(title: const Text('call_native_kit')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SimulatePushField(calls: _calls),
              const SizedBox(height: 24),
              _Actions(calls: _calls),
              const SizedBox(height: 24),
              DiagnosticsPanel(calls: _calls),
              const SizedBox(height: 24),
              Text('Events', style: Theme.of(context).textTheme.titleMedium),
              for (final line in _log)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    line,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _Actions extends StatelessWidget {
  const _Actions({required this.calls});

  final CallNativeKit calls;

  static const _demo = CallHandle(
    callId: '1001',
    roomName: 'call_1001',
    displayName: 'Demo caller',
    isVideo: true,
  );

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton(
            onPressed: () => calls.systemUi.showIncoming(_demo),
            child: const Text('Show incoming'),
          ),
          FilledButton.tonal(
            onPressed: () => calls.systemUi.startOutgoing(_demo),
            child: const Text('Start outgoing'),
          ),
          FilledButton.tonal(
            onPressed: () => calls.systemUi.setConnected(_demo.callId),
            child: const Text('Set connected'),
          ),
          OutlinedButton(
            onPressed: calls.systemUi.endAll,
            child: const Text('End all'),
          ),
          OutlinedButton(
            onPressed: () async {
              await calls.pip.setActiveVideoCall(active: true);
              await calls.pip.enterPip();
            },
            child: const Text('Enter PiP'),
          ),
          OutlinedButton(
            onPressed: calls.pip.closePip,
            child: const Text('Close PiP'),
          ),
          OutlinedButton(
            onPressed: () => calls.audio.activate(),
            child: const Text('Activate audio'),
          ),
          OutlinedButton(
            onPressed: calls.audio.deactivate,
            child: const Text('Deactivate audio'),
          ),
        ],
      );
}
