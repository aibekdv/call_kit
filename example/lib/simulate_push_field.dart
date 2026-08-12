import 'dart:convert';

import 'package:call_native_kit/call_native_kit.dart';
import 'package:flutter/material.dart';

/// Feeds a raw push payload through the same path a real FCM message takes.
///
/// The gate decision is shown rather than swallowed — most "the phone did not
/// ring" reports are a gate doing exactly what it was told to.
class SimulatePushField extends StatefulWidget {
  const SimulatePushField({required this.calls, super.key});

  final CallNativeKit calls;

  @override
  State<SimulatePushField> createState() => _SimulatePushFieldState();
}

class _SimulatePushFieldState extends State<SimulatePushField> {
  static const _sample =
      '{"type":"incoming_call","call_id":"1001","call_type":"video",'
      '"caller_name":"Demo caller","is_group":false}';

  late final TextEditingController _controller = TextEditingController(
    text: _sample,
  );
  String? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    const mapper = DefaultCallPushMapper();
    String result;
    try {
      final data = (jsonDecode(_controller.text) as Map)
          .cast<String, Object?>();
      final message = mapper.parse(data);
      result = switch (message) {
        IncomingCallPush() => (await widget.calls.handleIncomingPush(
          message,
        )).name,
        CallCancelledPush() =>
          await widget.calls
              .handleCancelledPush(message)
              .then((_) => 'cancelled'),
        null => 'not a call push',
      };
    } catch (e) {
      result = 'invalid JSON: $e';
    }
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Simulate push', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      TextField(
        controller: _controller,
        maxLines: 4,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          FilledButton(onPressed: _send, child: const Text('Send')),
          const SizedBox(width: 12),
          if (_result != null) Expanded(child: Text('→ $_result')),
        ],
      ),
    ],
  );
}
