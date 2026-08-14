import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:flutter/material.dart';

import 'demo_signaling_client.dart';

/// Places calls, fakes incoming ones, and shows what the engine did.
class HomePage extends StatefulWidget {
  const HomePage({required this.engine, required this.signaling, super.key});

  final CallEngine engine;
  final DemoSignalingClient signaling;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CallController get _controller => widget.engine.controller;

  Future<void> _placeCall({required bool isVideo}) async {
    await _controller.startOutgoingCall(
      fetchConnection: () => widget.signaling.initiateCall(
        CallInitiationRequest(participantIds: const ['demo'], isVideo: isVideo),
      ),
      roomName: 'call_kit_demo',
      displayName: 'Demo callee',
      isVideo: isVideo,
    );
    if (mounted) setState(() {});
  }

  /// Feeds a payload through the same path a real push takes: the mapper, the
  /// gate, the system call UI, and back into the engine.
  Future<void> _simulateIncoming({required bool isVideo}) async {
    final decision = await widget.engine.handleForegroundPush({
      'type': 'incoming_call',
      'call_id': 'demo',
      'call_type': isVideo ? 'video' : 'audio',
      'caller_name': 'Demo caller',
      'livekit_room': 'call_kit_demo',
    });
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Push gate: ${decision.name}')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('call_engine_kit')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!widget.signaling.isConfigured) const _ConfigurationHint(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _placeCall(isVideo: false),
                  child: const Text('Audio call'),
                ),
                FilledButton(
                  onPressed: () => _placeCall(isVideo: true),
                  child: const Text('Video call'),
                ),
                FilledButton.tonal(
                  onPressed: () => _simulateIncoming(isVideo: true),
                  child: const Text('Simulate incoming'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await _controller.hangupCall();
                    if (mounted) setState(() {});
                  },
                  child: const Text('Hang up'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SessionCard(controller: _controller),
            const SizedBox(height: 24),
            Text('Signaling', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (widget.signaling.log.isEmpty)
              const Text('nothing yet')
            else
              for (final entry in widget.signaling.log.reversed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    entry,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
          ],
        ),
      );
}

/// Live view of the engine's own state.
class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.controller});

  final CallController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<CallSnapshot>(
        valueListenable: _SnapshotNotifier(controller),
        builder: (context, snapshot, _) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('status', snapshot.session.status.name),
                _row('call id', snapshot.session.callId ?? '—'),
                _row('room', snapshot.session.roomName ?? '—'),
                _row('video', '${snapshot.session.isVideo}'),
                _row('participants', '${snapshot.session.activeParticipants}'),
                _row('muted', '${snapshot.media.isMuted}'),
                _row('audio route', snapshot.media.audioRoute.name),
                _row('remote video', '${snapshot.media.hasRemoteVideo}'),
                _row('screen share', '${snapshot.screenShare.isActive}'),
                _row('in pip', '${snapshot.view.isInSystemPip}'),
                _row('error', snapshot.session.error ?? '—'),
              ],
            ),
          ),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(label)),
            Expanded(
              child:
                  Text(value, style: const TextStyle(fontFamily: 'monospace')),
            ),
          ],
        ),
      );
}

class _SnapshotNotifier extends ValueNotifier<CallSnapshot> {
  _SnapshotNotifier(this._controller) : super(_controller.currentSnapshot) {
    _controller.stateChanged.addListener(_sync);
  }

  final CallController _controller;

  void _sync() => value = _controller.currentSnapshot;

  @override
  void dispose() {
    _controller.stateChanged.removeListener(_sync);
    super.dispose();
  }
}

class _ConfigurationHint extends StatelessWidget {
  const _ConfigurationHint();

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No LiveKit server configured, so calls will fail at the connect '
            'step — everything before it still runs.\n\n'
            'flutter run \\\n'
            '  --dart-define=LIVEKIT_URL=wss://your.livekit.cloud \\\n'
            '  --dart-define=LIVEKIT_TOKEN=<token>',
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      );
}
