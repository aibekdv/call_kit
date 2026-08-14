import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:flutter/foundation.dart';

enum CallOutcome { completed, missed, declined, failed }

class CallHistoryEntry {
  const CallHistoryEntry({
    required this.peer,
    required this.isVideo,
    required this.outcome,
    required this.startedAt,
    this.duration,
  });

  final String peer;
  final bool isVideo;
  final CallOutcome outcome;
  final DateTime startedAt;

  /// How long the call was connected. Null if it never was.
  final Duration? duration;
}

/// Call history, kept by the app.
///
/// The engine does not store any, and should not: history is a product
/// decision — how long to keep it, whether it syncs, what counts as a missed
/// call — and every app answers those differently. What the engine offers is
/// [CallController.snapshots], which is enough to write history from.
class CallHistoryStore extends ChangeNotifier {
  CallHistoryStore(this._controller) {
    _controller.session.addListener(_onSession);
  }

  final CallController _controller;
  final List<CallHistoryEntry> _entries = [];

  CallLifecycleState _previousStatus = CallLifecycleState.idle;
  bool _wasConnected = false;

  List<CallHistoryEntry> get entries => List.unmodifiable(_entries.reversed);

  void _onSession() {
    final session = _controller.session.value;
    final status = session.status;
    if (status == _previousStatus) return;

    final previous = _previousStatus;
    _previousStatus = status;

    if (status == CallLifecycleState.inCall) {
      _wasConnected = true;
      return;
    }
    if (!status.isTerminal) return;

    _entries.add(
      CallHistoryEntry(
        peer: session.displayName ?? session.roomName ?? '—',
        isVideo: session.isVideo,
        outcome: _outcomeFor(status, previous),
        startedAt: _controller.timing.value.startedAt ?? DateTime.now(),
        duration: _wasConnected
            ? _controller.timing.value.durationAt(DateTime.now())
            : null,
      ),
    );
    _wasConnected = false;
    notifyListeners();
  }

  /// A call that ended without ever connecting was not "completed" — which of
  /// the other three it was depends on where it ended.
  CallOutcome _outcomeFor(
    CallLifecycleState status,
    CallLifecycleState previous,
  ) {
    if (status == CallLifecycleState.failed) return CallOutcome.failed;
    if (_wasConnected) return CallOutcome.completed;
    return previous == CallLifecycleState.incomingRinging
        ? CallOutcome.missed
        : CallOutcome.declined;
  }

  @override
  void dispose() {
    _controller.session.removeListener(_onSession);
    super.dispose();
  }
}
