/// Layout resolution logic for group calls.
library;

/// The layout mode used to arrange participants in a group call.
enum GroupCallLayoutMode {
  /// Full-screen remote + local PiP (2 participants total).
  fullScreenPip,

  /// 2×2 grid layout (3–4 participants).
  grid2x2,

  /// 2×3 grid layout (5–6 participants).
  grid2x3,

  /// Active speaker prominent + thumbnail row (7+ participants).
  speakerView,

  /// Screen share content prominent + thumbnail row.
  screenShare,
}

/// Resolves the appropriate [GroupCallLayoutMode] based on participant count
/// and screen-sharing state.
///
/// This is a pure static utility class with no side effects.
class GroupCallLayoutResolver {
  GroupCallLayoutResolver._();

  /// Determines the optimal layout mode for a group call.
  ///
  /// [totalCount] includes the local participant.
  /// [hasScreenShare] is `true` when someone is sharing their screen.
  static GroupCallLayoutMode resolve({
    required int totalCount,
    required bool hasScreenShare,
  }) {
    if (hasScreenShare) return GroupCallLayoutMode.screenShare;
    if (totalCount <= 2) return GroupCallLayoutMode.fullScreenPip;
    if (totalCount <= 4) return GroupCallLayoutMode.grid2x2;
    if (totalCount <= 6) return GroupCallLayoutMode.grid2x3;
    return GroupCallLayoutMode.speakerView;
  }
}
