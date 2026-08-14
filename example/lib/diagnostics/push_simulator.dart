import 'dart:convert';

import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:flutter/material.dart';

/// Rings this device, without a server.
///
/// Feeds a payload through exactly the path a real FCM message takes —
/// mapper, gate, system call UI, engine — so the incoming-call flow can be
/// exercised on one device. The gate's decision is shown rather than
/// swallowed: most "it did not ring" reports are a gate doing what it was
/// told.
class PushSimulator extends StatefulWidget {
  const PushSimulator({
    required this.engine,
    required this.callerName,
    required this.room,
    super.key,
  });

  final CallEngine engine;
  final String callerName;
  final String room;

  @override
  State<PushSimulator> createState() => _PushSimulatorState();
}

class _PushSimulatorState extends State<PushSimulator> {
  late final TextEditingController _payload = TextEditingController(
    text: const JsonEncoder.withIndent('  ').convert({
      'type': 'incoming_call',
      'call_id': 'sim-1',
      'call_type': 'video',
      'caller_name': widget.callerName,
      'livekit_room': widget.room,
    }),
  );

  String? _result;

  @override
  void dispose() {
    _payload.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    String result;
    try {
      final data = (jsonDecode(_payload.text) as Map).cast<String, Object?>();
      final decision = await widget.engine.handleForegroundPush(data);
      result = decision.name;
    } catch (e) {
      result = 'invalid payload: $e';
    }
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Simulate a push',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'The same payload your server would send, through the same path.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _payload,
            maxLines: 7,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton(onPressed: _send, child: const Text('Send')),
              const SizedBox(width: 12),
              if (_result != null)
                Expanded(
                  child: Text(
                    'gate: $_result',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
            ],
          ),
        ],
      );
}
