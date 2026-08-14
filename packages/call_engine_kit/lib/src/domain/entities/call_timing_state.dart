import 'package:equatable/equatable.dart';

import 'unset.dart';

/// When the call actually connected.
///
/// Set once, on the transition into `CallLifecycleState.inCall`, so the
/// duration shown to the user counts talking time rather than ringing time.
class CallTimingState extends Equatable {
  const CallTimingState({this.startedAt});

  static const initial = CallTimingState();

  final DateTime? startedAt;

  /// How long the call has been connected, or null before it was.
  Duration? durationAt(DateTime now) =>
      startedAt == null ? null : now.difference(startedAt!);

  CallTimingState copyWith({Object? startedAt = unset}) =>
      CallTimingState(startedAt: resolve(startedAt, this.startedAt));

  @override
  List<Object?> get props => [startedAt];
}
