import 'package:equatable/equatable.dart';

import 'call_audio_route.dart';

/// How the call is being presented, as opposed to what it is doing.
class CallViewState extends Equatable {
  const CallViewState({
    this.isOverlayExpanded = false,
    this.viewMode = CallViewMode.grid,
    this.isInSystemPip = false,
  });

  static const initial = CallViewState();

  /// Whether the full call screen is showing, as opposed to a compact bar or
  /// bubble over the rest of the app.
  final bool isOverlayExpanded;

  final CallViewMode viewMode;

  /// Whether the app is in system picture-in-picture.
  final bool isInSystemPip;

  CallViewState copyWith({
    bool? isOverlayExpanded,
    CallViewMode? viewMode,
    bool? isInSystemPip,
  }) =>
      CallViewState(
        isOverlayExpanded: isOverlayExpanded ?? this.isOverlayExpanded,
        viewMode: viewMode ?? this.viewMode,
        isInSystemPip: isInSystemPip ?? this.isInSystemPip,
      );

  @override
  List<Object?> get props => [isOverlayExpanded, viewMode, isInSystemPip];
}
