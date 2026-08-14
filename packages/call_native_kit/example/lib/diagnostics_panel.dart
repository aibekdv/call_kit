import 'package:call_native_kit/call_native_kit.dart';
import 'package:flutter/material.dart';

/// Live view of the state that is otherwise invisible.
///
/// [AudioSessionDiagnostics.activationCount] staying at zero during a
/// CallKit-accepted call is what a silent call looks like from the outside;
/// see [CallAudioSession] for why.
class DiagnosticsPanel extends StatefulWidget {
  const DiagnosticsPanel({required this.calls, super.key});

  final CallNativeKit calls;

  @override
  State<DiagnosticsPanel> createState() => _DiagnosticsPanelState();
}

class _DiagnosticsPanelState extends State<DiagnosticsPanel> {
  AudioSessionDiagnostics? _audio;
  String? _voipToken;
  PendingCall? _pending;
  List<CallHandle> _active = const [];
  bool? _inPip;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final audio = await widget.calls.audio.diagnostics();
    final token = await widget.calls.voipPushToken();
    final pending = await widget.calls.takePendingAcceptedCall();
    final active = await widget.calls.systemUi.activeCalls();
    final inPip = await widget.calls.pip.queryIsInPip();
    if (!mounted) return;
    setState(() {
      _audio = audio;
      _voipToken = token;
      _pending = pending;
      _active = active;
      _inPip = inPip;
    });
  }

  @override
  Widget build(BuildContext context) {
    final keys = widget.calls.config.storageKeys;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Diagnostics', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
        _row('audio session', _audio?.toString() ?? 'unavailable'),
        _row('voip token', _voipToken ?? '—'),
        _row('pending call', _pending?.toString() ?? 'none'),
        _row('active calls', _active.isEmpty ? 'none' : '${_active.length}'),
        _row('in pip', '$_inPip'),
        _row('storage prefix', keys.prefix),
        _row('active-call key', keys.activeCall),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 130, child: Text(label)),
        Expanded(
          child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ),
      ],
    ),
  );
}
