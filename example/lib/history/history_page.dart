import 'package:call_engine_kit/overlay.dart' show formatCallDuration;
import 'package:flutter/material.dart';

import 'call_history_store.dart';

/// What happened, written by the app from the engine's state.
class HistoryPage extends StatelessWidget {
  const HistoryPage({required this.store, super.key});

  final CallHistoryStore store;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final entries = store.entries;
          if (entries.isEmpty) {
            return const Center(child: Text('No calls yet'));
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) =>
                _HistoryTile(entry: entries[index]),
          );
        },
      );
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final CallHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (entry.outcome) {
      CallOutcome.completed => (Icons.call_made, Colors.green),
      CallOutcome.missed => (Icons.call_missed, Colors.red),
      CallOutcome.declined => (Icons.call_end, Colors.orange),
      CallOutcome.failed => (Icons.error_outline, Colors.red),
    };

    final duration = entry.duration;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(entry.peer),
      subtitle: Text(
        [
          entry.isVideo ? 'Video' : 'Audio',
          entry.outcome.name,
          if (duration != null) formatCallDuration(duration),
        ].join(' · '),
      ),
      trailing: Text(_timeOf(entry.startedAt)),
    );
  }

  String _timeOf(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}
