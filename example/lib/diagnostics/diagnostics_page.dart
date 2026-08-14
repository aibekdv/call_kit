import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:flutter/material.dart';

import '../session/app_session.dart';
import '../signaling/dev_signaling_client.dart';
import 'push_simulator.dart';

/// The state that is otherwise invisible, and the push path that otherwise
/// needs a server.
class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({
    required this.engine,
    required this.session,
    required this.signaling,
    super.key,
  });

  final CallEngine engine;
  final AppSession session;
  final DevSignalingClient signaling;

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  final CallNativeKit _native = CallNativeKit.instance;

  String? _voipToken;
  String? _audio;
  bool? _inPip;
  int _activeCalls = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final token = await _native.voipPushToken();
    final audio = await _native.audio.diagnostics();
    final inPip = await _native.pip.queryIsInPip();
    final active = await _native.systemUi.activeCalls();
    if (!mounted) return;
    setState(() {
      _voipToken = token;
      _audio = audio?.toString();
      _inPip = inPip;
      _activeCalls = active.length;
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PushSimulator(
            engine: widget.engine,
            callerName: 'Demo caller',
            room: 'demo-incoming',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Native', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
            ],
          ),
          // A zero activation count during a CallKit-accepted call is what a
          // silent call looks like from the outside — see CallAudioSession.
          _row('audio session', _audio ?? 'unavailable'),
          _row('voip token', _voipToken ?? '— (iOS only)'),
          _row('in pip', '$_inPip'),
          _row('system calls', '$_activeCalls'),
          _row('storage prefix', _native.config.storageKeys.prefix),
          const SizedBox(height: 24),
          Text('Language', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Switching re-runs CallNativeKit.configure. The config is persisted, '
            'so a call that arrives while the app is dead is drawn from whatever '
            'was written last.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          SegmentedButton<DemoLocale>(
            segments: [
              for (final locale in DemoLocale.values)
                ButtonSegment(value: locale, label: Text(locale.label)),
            ],
            selected: {widget.session.locale},
            onSelectionChanged: (selection) =>
                widget.session.setLocale(selection.first),
          ),
          const SizedBox(height: 24),
          Text('Signalling', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ValueListenableBuilder<List<String>>(
            valueListenable: widget.signaling.log,
            builder: (context, log, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.isEmpty)
                  const Text('nothing yet')
                else
                  for (final entry in log.reversed)
                    Text(
                      entry,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
              ],
            ),
          ),
        ],
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text(label)),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      );
}
