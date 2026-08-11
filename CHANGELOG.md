## 0.5.0

### Fixed
* Local video no longer shows as a transparent hole in the PiP — the frame had no background, so a renderer that stopped painting (a texture disposed by a reconnect) showed straight through. All external video widgets now sit on an opaque `VideoSurface`.
* Group video no longer goes stale after a reconnect: the cached participant list ignored `videoWidget` changes and kept rendering the disposed renderer.
* PiP no longer drifts to another corner when the controls fade. It still follows them WhatsApp-style, but now stores its corner instead of a pixel offset.
* Bottom bar no longer swallows taps and drags aimed at the PiP.
* Buttons still visibly fading out now respond to taps (300 ms dead window removed).
* Turning the local camera off no longer blanks the remote video after a tap-to-swap.
* Personal-call fallback no longer claims the remote party's camera is off.
* Screen-share banner now also appears in personal calls.
* Modal sheets pause the auto-hide timer and refresh with the call state instead of showing a snapshot.
* `CallBottomBar.height` was `94` while the bar measured `102`, halving the gap the PiP keeps from the controls.

### Added
* `CallConnectionState` and `ConnectionStateBanner` — pass `connectionState` for a persistent "Connecting…"/"Reconnecting…" banner. Adds `CallStrings.connecting` and `CallStrings.reconnecting`.
* `callStatusListenable` — for values that tick, such as a call timer. `callStatusText` makes the host `setState`, which rebuilds every video surface once per tick (30 rebuilds per 10 s with three participants); a listenable rebuilds only the status line.
* `PipCorner`, `PipSnapCalculator.nearestCorner` / `offsetForCorner` / `clampToBounds`.
* Golden tests for six layouts, and CI running format, analysis and tests.
* README: "Reconnection" and "Performance" sections.

### Breaking
* Removed `_VideoErrorBoundary` (0.4.0) in favour of `VideoSurface`. It never worked: Flutter catches paint exceptions in `RenderObject._paintWithContext` without rethrowing, so an ancestor `try`/`catch` was never reached.
* `CallScreen`: removed `isHandRaised` and `onRaiseHand`, which were accepted and never used.
* `FloatingPipView`: `controlsVisible` is deprecated and ignored — pass visibility-dependent `topBarHeight`/`controlsHeight` instead.
* Internal layers: `CallTopBar.callType` and `CallBottomBar.bottomPadding` removed.

## 0.4.0

### Performance
* Narrow `LayoutBuilder` scope in `CallScreen` — only `FloatingPipView` rebuilds on constraint changes instead of all 5 layers.
* Pre-compute `allParticipants` list in `didUpdateWidget` instead of allocating on every build.
* Add `ValueKey` to `ParticipantTile` in grid layouts for correct widget reuse across participant reorders.
* Add `RepaintBoundary` to `ScreenShareBanner` slide animation to isolate repaints.

### Improvements
* Animate grid layout transitions with `AnimatedPositioned` (250ms easeOutCubic) — smooth tile repositioning when participants join or leave.
* Add `Semantics` to all call control buttons, `ParticipantTile`, and `SignalStrengthIcon` for screen reader accessibility.
* Add `endCall`, `speaker`, `camera`, `moreOptions` localisation strings to `CallStrings`.
* Extract controls visibility timer into `_ControlsVisibilityController` for cleaner `CallScreen` state management.
* Add defensive timer cancellation in `_startHideTimer()` to prevent timer leaks.
* Add `_VideoErrorBoundary` around externally-provided video widgets — catches rendering errors at the `RenderObject` level and shows a fallback instead of crashing the call screen.
* Add `toString()` to `CallParticipant` and `CallTheme` for easier debugging.
* Document why `videoWidget`/`screenShareWidget` are excluded from `CallParticipant` equality.

### Breaking Changes
* `CallBottomBar`: now requires a `strings` (`CallStrings`) parameter for accessibility labels.
* `CallVideoContent`: new optional `allParticipants` parameter — pass a pre-built list to avoid per-build allocation.

## 0.3.1

### Bug Fixes
* Fix remote video being hidden when local camera is turned off in personal (1-on-1) calls.

## 0.3.0

### Improvements
* Wrap `CallScreen` Scaffold with `SafeArea` — all content now respects device insets automatically.
* Replace manual `MediaQuery.paddingOf` safe area handling with `LayoutBuilder` for accurate sizing.
* Remove `EdgeInsets safeArea` parameter from `CallTopBar` and `CallBottomBar`.
* Remove `safeAreaLeft/Right/Top/Bottom` parameters from `FloatingPipView`.
* Remove redundant `SafeArea` wrapper from `CallVideoContent` group call layout.

### Breaking Changes
* `CallTopBar`: removed `safeArea` parameter.
* `CallBottomBar`: replaced `safeArea` parameter with `bottomPadding` (`double`).
* `FloatingPipView`: removed `safeAreaLeft`, `safeAreaRight`, `safeAreaTop`, `safeAreaBottom` parameters.

## 0.2.1

* Lower minimum SDK constraints from Dart `^3.11.3` / Flutter `>=3.29.0` to Dart `^3.4.0` / Flutter `>=3.22.0` for wider compatibility.

## 0.2.0

### Performance
* Cache `CallStrings.english()` as `CallStrings.englishDefaults` to prevent cascading widget rebuilds.
* Extract speaking border animation into isolated `StatefulWidget` — `ParticipantTile` is now a `StatelessWidget`.
* Keep `SpeakingIndicator` in widget tree permanently and toggle via `visible` parameter instead of destroying/recreating the `AnimationController`.
* Skip rendering `SignalStrengthIcon` when signal strength is `excellent` (the default).
* Cache screen sharer name lookup in `didUpdateWidget` instead of scanning participants on every build.
* Add `RepaintBoundary` to `FloatingPipView` child to isolate video repaints during snap animation.
* Remove `_DefaultStrings` sentinel class (~60 lines of boilerplate).

### Bug Fixes
* Show remote screen share content in personal (1:1) call layout — previously `screenShareWidget` was ignored outside group calls.

### Breaking Changes
* `CallScreen.strings` is now nullable (`CallStrings?`). Pass `null` or omit to use English defaults. Previously accepted a non-null `CallStrings` with an internal sentinel.
* `CallStrings.englishDefaults` is a new cached static field — use it instead of `CallStrings.english()` when a stable reference is needed.

## 0.1.1

* Use GitHub-hosted screenshots to reduce package size.
* Exclude build artifacts from published package.

## 0.1.0

* Initial release.
* `CallScreen` widget for personal audio, personal video, and group calls.
* Adaptive group call layouts: 2x2 grid, 2x3 grid, speaker view, screen share view.
* Draggable PiP (Picture-in-Picture) view with corner snapping.
* Animated speaking indicators and speaking tile borders.
* Signal strength indicator per participant.
* Participants panel with host actions (mute, remove).
* Customizable "more" bottom sheet with encryption label.
* Screen share banner with stop button.
* Full theming via `CallTheme` with WhatsApp preset.
* Full localization via `CallStrings` with English defaults.
* Zero external dependencies.
