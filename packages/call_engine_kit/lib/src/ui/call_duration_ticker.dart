import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import '../domain/entities/call_lifecycle_state.dart';
import '../domain/entities/call_session_state.dart';
import '../domain/entities/call_timing_state.dart';

/// The line under the caller's name: a status, or a running duration.
///
/// A [ValueListenable] rather than something that calls `setState`. The status
/// changes once a second, and rebuilding the whole call screen that often
/// would rebuild every video surface with it — three participants means thirty
/// pointless texture rebuilds in ten seconds.
class CallDurationTicker extends ValueNotifier<String> {
  CallDurationTicker({
    required ValueListenable<CallSessionState> session,
    required ValueListenable<CallTimingState> timing,
    required String Function(CallLifecycleState status) statusLabel,
    String Function(Duration duration)? formatDuration,
  })  : _session = session,
        _timing = timing,
        _statusLabel = statusLabel,
        _formatDuration = formatDuration ?? formatCallDuration,
        super('') {
    _session.addListener(_refresh);
    _timing.addListener(_refresh);
    _refresh();
  }

  final ValueListenable<CallSessionState> _session;
  final ValueListenable<CallTimingState> _timing;
  final String Function(CallLifecycleState status) _statusLabel;
  final String Function(Duration duration) _formatDuration;

  Timer? _ticker;

  void _refresh() {
    final startedAt = _timing.value.startedAt;
    final connected =
        startedAt != null && _session.value.status == CallLifecycleState.inCall;

    if (connected) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      _tick();
      return;
    }

    _ticker?.cancel();
    _ticker = null;
    value = _statusLabel(_session.value.status);
  }

  void _tick() {
    final startedAt = _timing.value.startedAt;
    if (startedAt == null) return;
    // `clock.now()` rather than `DateTime.now()`, so a test can drive the
    // duration instead of waiting for it.
    value = _formatDuration(clock.now().difference(startedAt));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _session.removeListener(_refresh);
    _timing.removeListener(_refresh);
    super.dispose();
  }
}

/// `12:34`, or `1:02:03` once a call passes an hour.
String formatCallDuration(Duration duration) {
  final seconds = duration.inSeconds.clamp(0, 359999);
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainder = seconds % 60;

  final mm = minutes.toString().padLeft(2, '0');
  final ss = remainder.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
}
