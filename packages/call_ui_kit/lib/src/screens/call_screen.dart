/// The unified call screen handling personal audio, personal video,
/// and group video calls.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/call_connection_state.dart';
import '../models/call_dimensions.dart';
import '../models/call_participant.dart';
import '../models/call_strings.dart';
import '../models/call_theme.dart';
import '../models/call_type.dart';
import '../widgets/connection_state_banner.dart';
import '../widgets/floating_pip_view.dart';
import '../widgets/more_bottom_sheet.dart';
import '../widgets/participants_panel.dart';
import '../widgets/screen_share_banner.dart';
import 'layers/call_bottom_bar.dart';
import 'layers/call_right_buttons.dart';
import 'layers/call_top_bar.dart';
import 'layers/call_video_content.dart';

/// A single call screen widget that adapts to personal audio, personal video,
/// and group video calls based on the provided configuration.
///
/// The whole screen is laid out inside a [SafeArea], so no layer extends
/// under the status bar or the home indicator.
///
/// The layout is a keyed [Stack], painted bottom to top:
/// 1. Video content (always visible)
/// 2. Top region — banners (never auto-hidden), the top app bar and the side
///    buttons (both auto-hide), flowing vertically so they cannot overlap
/// 3. Bottom controls bar (auto-hide)
/// 4. Local PiP view — topmost, so it always wins hit-testing
///
/// Every layer carries an explicit key so that inserting or removing a
/// conditional layer cannot re-purpose a sibling's element and reset its
/// state.
///
/// Controls auto-hide after 4 seconds and reappear on screen tap, matching
/// WhatsApp behaviour. The PiP follows them: while the bars are hidden it
/// animates into the space they occupied and back again when they return,
/// staying in whichever corner the user left it.
class CallScreen extends StatefulWidget {
  // ── Identity ──

  /// The caller or group name displayed in the top bar.
  final String callerName;

  /// Optional avatar URL for the caller.
  final String? callerAvatarUrl;

  /// Whether this is a group call with multiple participants.
  final bool isGroupCall;

  /// The type of call (audio or video).
  final CallType callType;

  // ── Participants (group call) ──

  /// All remote participants in a group call.
  final List<CallParticipant> participants;

  /// The local participant.
  final CallParticipant localParticipant;

  // ── Video widgets ──

  /// The widget displaying the local camera stream.
  final Widget? localVideoWidget;

  /// The widget displaying the remote camera stream (personal call).
  final Widget? remoteVideoWidget;

  /// The widget displaying a remote screen share stream.
  final Widget? screenShareWidget;

  // ── State ──

  /// Whether the local microphone is muted.
  final bool isMuted;

  /// Whether the local camera is turned off.
  final bool isCameraOff;

  /// Whether the speaker is active (vs earpiece).
  final bool isSpeakerOn;

  /// Whether the local user is sharing their screen.
  final bool isScreenSharing;

  /// The transport state of the call.
  ///
  /// Anything other than [CallConnectionState.connected] shows a persistent
  /// banner below the top bar. The host application keeps its renderers alive
  /// across a reconnect; see the "Reconnection" section of the README for how
  /// to key video widgets so a recreated renderer is picked up.
  final CallConnectionState connectionState;

  // ── Config ──

  /// Whether to show the encryption label in the more sheet.
  final bool showEncryptionLabel;

  /// The visual theme. Defaults to [CallTheme.whatsApp].
  final CallTheme theme;

  /// The sizing configuration. Defaults to the kit's native metrics.
  ///
  /// Raise [CallDimensions.scale] to enlarge the whole call UI at once — see
  /// [CallDimensions] for why a tablet host wants that.
  final CallDimensions dimensions;

  /// Localised strings. Defaults to [CallStrings.english] when null.
  final CallStrings? strings;

  /// Optional call status text override (e.g. "Calling...", "04:23").
  /// If null, shows [strings.calling].
  final String? callStatusText;

  /// A frequently-changing status value, such as a call-duration timer.
  ///
  /// Prefer this over [callStatusText] for anything that ticks: pushing a new
  /// [callStatusText] means the host calls `setState`, which rebuilds the
  /// whole call screen — including every video surface — once per tick. A
  /// listenable rebuilds only the status line. Takes precedence over
  /// [callStatusText] when both are given.
  final ValueListenable<String>? callStatusListenable;

  // ── Callbacks ──

  /// Called when the end-call button is tapped.
  final VoidCallback onEndCall;

  /// Called when the mute toggle is tapped.
  final VoidCallback onToggleMute;

  /// Called when the camera toggle is tapped.
  /// When null, the camera toggle button is hidden.
  final VoidCallback? onToggleCamera;

  /// Called when the speaker toggle is tapped.
  final VoidCallback onToggleSpeaker;

  /// Called when the flip-camera button is tapped.
  /// When null, the flip-camera button is hidden.
  final VoidCallback? onFlipCamera;

  /// Called when the screen-share button in the bottom bar is tapped.
  /// When null, the screen-share button is hidden from the bottom bar.
  final VoidCallback? onToggleScreenShare;

  /// Called when "Stop" is tapped on the screen-share banner.
  final VoidCallback? onStopScreenShare;

  /// Called when the add-participant button is tapped.
  /// When null, the add-participant button is hidden.
  final VoidCallback? onAddParticipant;

  /// Called when the effects button is tapped.
  /// When null, the effects button is hidden.
  final VoidCallback? onEffects;

  /// Builds custom content for the "more" bottom sheet.
  /// When provided, the builder receives [BuildContext] and [CallTheme]
  /// and should return the widget(s) to display in the sheet body.
  /// When null, the "more" button is hidden from the bottom bar.
  final Widget Function(BuildContext context, CallTheme theme)?
      moreSheetBuilder;

  /// Called when the minimize / PiP button is tapped.
  /// When null, the minimize button is hidden.
  final VoidCallback? onMinimize;

  /// Called when the host mutes a participant.
  final void Function(CallParticipant)? onMuteParticipant;

  /// Called when the host taps "Mute all".
  ///
  /// When provided, this is called instead of invoking [onMuteParticipant]
  /// for each unmuted participant, allowing the host app to batch the
  /// state update into a single operation.
  final VoidCallback? onMuteAll;

  /// Called when the host removes a participant.
  final void Function(CallParticipant)? onRemoveParticipant;

  /// Creates a [CallScreen].
  const CallScreen({
    super.key,
    required this.callerName,
    this.callerAvatarUrl,
    this.isGroupCall = false,
    this.callType = CallType.video,
    this.participants = const [],
    required this.localParticipant,
    this.localVideoWidget,
    this.remoteVideoWidget,
    this.screenShareWidget,
    this.isMuted = false,
    this.isCameraOff = false,
    this.isSpeakerOn = false,
    this.isScreenSharing = false,
    this.connectionState = CallConnectionState.connected,
    this.showEncryptionLabel = true,
    this.theme = const CallTheme.whatsApp(),
    this.dimensions = const CallDimensions(),
    this.strings,
    this.callStatusText,
    this.callStatusListenable,
    required this.onEndCall,
    required this.onToggleMute,
    this.onToggleCamera,
    required this.onToggleSpeaker,
    this.onFlipCamera,
    this.onToggleScreenShare,
    this.onStopScreenShare,
    this.onAddParticipant,
    this.onEffects,
    this.moreSheetBuilder,
    this.onMinimize,
    this.onMuteParticipant,
    this.onMuteAll,
    this.onRemoveParticipant,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

/// Encapsulates the auto-hide timer and visibility state for call controls.
///
/// Controls become visible on tap and auto-hide after [_autoHideDelay].
/// Any button interaction should call [reset] to restart the timer.
class _ControlsVisibilityController {
  static const _autoHideDelay = Duration(seconds: 4);

  final ValueNotifier<bool> visible = ValueNotifier(true);
  Timer? _timer;
  bool _mounted = true;

  _ControlsVisibilityController() {
    _startTimer();
  }

  void toggle() {
    if (!_mounted) return;
    visible.value = !visible.value;
    _timer?.cancel();
    if (visible.value) _startTimer();
  }

  void reset() {
    if (!_mounted) return;
    _timer?.cancel();
    _startTimer();
  }

  /// Stops the auto-hide timer without changing visibility.
  ///
  /// Used while a modal sheet is open so the controls do not fade out (and
  /// the layout does not shift) behind it.
  void pause() {
    _timer?.cancel();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(_autoHideDelay, () {
      if (_mounted) visible.value = false;
    });
  }

  void dispose() {
    _mounted = false;
    _timer?.cancel();
    visible.dispose();
  }
}

class _CallScreenState extends State<CallScreen> {
  final _controls = _ControlsVisibilityController();
  final ValueNotifier<bool> _isSwapped = ValueNotifier(false);

  /// Bumped on every widget update so open modal sheets — which are separate
  /// routes and do not rebuild with this screen — can refresh their content.
  final ValueNotifier<int> _revision = ValueNotifier(0);

  /// Number of modal sheets this screen currently has open.
  int _openSheets = 0;

  late CallStrings _strings;

  void _resolveStrings() {
    _strings = widget.strings ?? CallStrings.englishDefaults;
  }

  /// Whether the floating local PiP applies to the current layout.
  bool get _showPip =>
      widget.callType == CallType.video &&
      (!widget.isGroupCall || widget.participants.length <= 1) &&
      !widget.isScreenSharing &&
      widget.screenShareWidget == null;

  /// The name of the remote participant sharing their screen, if any.
  ///
  /// Computed per build rather than cached: [CallParticipant] equality
  /// deliberately ignores video widgets, so no cache-invalidation check can
  /// be both correct and cheap here.
  String? get _screenSharerName {
    for (final p in widget.participants) {
      if (p.isScreenSharing) return p.displayName;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _resolveStrings();
  }

  @override
  void didUpdateWidget(covariant CallScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.strings != widget.strings) {
      _resolveStrings();
    }
    // Swapping puts the local video full screen. Turning the local camera off,
    // or leaving the PiP layout entirely, must not strand the remote video in
    // a hidden slot.
    if (_isSwapped.value &&
        ((!oldWidget.isCameraOff && widget.isCameraOff) || !_showPip)) {
      _isSwapped.value = false;
    }
    // An open sheet lives in its own route, so notifying it here would mark a
    // widget outside the current build scope as dirty. Defer to after the
    // frame, and only bother when a sheet is actually listening.
    if (_openSheets > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _openSheets > 0) _revision.value++;
      });
    }
  }

  @override
  void dispose() {
    _controls.dispose();
    _isSwapped.dispose();
    _revision.dispose();
    super.dispose();
  }

  Future<void> _showMoreBottomSheet() async {
    if (widget.moreSheetBuilder == null) return;
    _controls.pause();
    _openSheets++;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ValueListenableBuilder<int>(
        valueListenable: _revision,
        builder: (_, __, ___) => MoreBottomSheet(
          theme: widget.theme,
          dimensions: widget.dimensions,
          strings: _strings,
          showEncryptionLabel: widget.showEncryptionLabel,
          child: widget.moreSheetBuilder!(ctx, widget.theme),
        ),
      ),
    );
    _openSheets--;
    if (mounted) _controls.reset();
  }

  Future<void> _showParticipantsPanel() async {
    _controls.pause();
    _openSheets++;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: _revision,
        builder: (_, __, ___) => ParticipantsPanel(
          // Local participant first: this is a roster, where "You" leads.
          participants: [widget.localParticipant, ...widget.participants],
          isLocalHost: widget.localParticipant.isHost,
          theme: widget.theme,
          dimensions: widget.dimensions,
          strings: _strings,
          onMuteParticipant: widget.onMuteParticipant,
          onMuteAll: widget.onMuteAll,
          onRemoveParticipant: widget.onRemoveParticipant,
          onInvite: widget.onAddParticipant,
        ),
      ),
    );
    _openSheets--;
    if (mounted) _controls.reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    final showConnectionBanner =
        widget.connectionState != CallConnectionState.connected;
    final showScreenShareBanner =
        widget.isScreenSharing || widget.screenShareWidget != null;
    final showRightButtons =
        widget.onAddParticipant != null || widget.onEffects != null;

    // Areas the PiP must keep clear of, in each controls state. The banners
    // are counted in both because they are never auto-hidden; the top bar and
    // the side buttons only while they are on screen, so the PiP rises into
    // that space when the controls fade out and returns when they come back.
    // Safe-area insets are consumed by the SafeArea below, so they are not
    // added here. The screen-share banner is left out on purpose: it never
    // coexists with the PiP (see _showPip).
    final dimensions = widget.dimensions;
    final bannerInset =
        showConnectionBanner ? dimensions.connectionBannerHeight : 0.0;
    final pipTopInsetVisible = bannerInset +
        dimensions.topBarHeight +
        (showRightButtons
            ? dimensions.scaled(dimensions.rightButtons.gapFromTopBar) +
                dimensions.rightButtonsHeight(
                  hasAdd: widget.onAddParticipant != null,
                  hasEffects: widget.onEffects != null,
                )
            : 0.0);
    final pipTopInsetHidden = bannerInset;

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.background,
        body: Stack(
          children: [
            // Layer 1 — Video content (tap here toggles controls)
            Positioned.fill(
              key: const ValueKey('call-video'),
              child: GestureDetector(
                onTap: _controls.toggle,
                behavior: HitTestBehavior.opaque,
                child: RepaintBoundary(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isSwapped,
                    builder: (context, swapped, _) => CallVideoContent(
                      theme: theme,
                      dimensions: dimensions,
                      strings: _strings,
                      isGroupCall: widget.isGroupCall,
                      callerName: widget.callerName,
                      callerAvatarUrl: widget.callerAvatarUrl,
                      participants: widget.participants,
                      localParticipant: widget.localParticipant,
                      // Swapping shows the local video full screen; blank it
                      // when the local camera is off.
                      remoteVideoWidget: swapped
                          ? (widget.isCameraOff
                              ? null
                              : widget.localVideoWidget)
                          : widget.remoteVideoWidget,
                      screenShareWidget: widget.screenShareWidget,
                      isCameraOff: widget.isCameraOff,
                      isScreenSharing: widget.isScreenSharing,
                      onStopScreenShare: widget.onStopScreenShare,
                      onShowParticipantsPanel: _showParticipantsPanel,
                    ),
                  ),
                ),
              ),
            ),

            // Layer 2 — Top region. The bar, the banners and the side buttons
            // flow vertically, so they can never overlap one another and the
            // banners stay visible while the controls fade.
            Positioned(
              key: const ValueKey('call-top-region'),
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banners come first: they are never auto-hidden, so they
                  // must sit at the very top rather than under a bar that
                  // fades away beneath them.
                  if (showScreenShareBanner)
                    ScreenShareBanner(
                      key: const ValueKey('call-share-banner'),
                      isLocalSharing: widget.isScreenSharing,
                      sharerName: widget.isScreenSharing
                          ? null
                          : (_screenSharerName ?? widget.callerName),
                      theme: theme,
                      dimensions: dimensions,
                      strings: _strings,
                      onStop: widget.isScreenSharing
                          ? widget.onStopScreenShare
                          : null,
                    ),
                  if (showConnectionBanner)
                    ConnectionStateBanner(
                      key: const ValueKey('call-connection-banner'),
                      state: widget.connectionState,
                      theme: theme,
                      dimensions: dimensions,
                      strings: _strings,
                    ),
                  _AutoHideLayer(
                    key: const ValueKey('call-top-bar'),
                    visible: _controls.visible,
                    child: CallTopBar(
                      theme: theme,
                      dimensions: dimensions,
                      strings: _strings,
                      callerName: widget.callerName,
                      callStatusText: widget.callStatusText,
                      callStatusListenable: widget.callStatusListenable,
                      isGroupCall: widget.isGroupCall,
                      participantCount: widget.participants.length + 1,
                      onResetHideTimer: _controls.reset,
                      onFlipCamera: widget.onFlipCamera,
                      onMinimize: widget.onMinimize,
                    ),
                  ),
                  if (showRightButtons)
                    _AutoHideLayer(
                      key: const ValueKey('call-right-buttons'),
                      visible: _controls.visible,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: dimensions
                              .scaled(dimensions.rightButtons.gapFromTopBar),
                          right: dimensions
                              .scaled(dimensions.rightButtons.insetFromEdge),
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: CallRightButtons(
                            theme: theme,
                            dimensions: dimensions,
                            strings: _strings,
                            onAddParticipant: widget.onAddParticipant,
                            onEffects: widget.onEffects,
                            onResetHideTimer: _controls.reset,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Layer 3 — Bottom controls bar
            Positioned(
              key: const ValueKey('call-bottom-bar'),
              bottom: 0,
              left: 0,
              right: 0,
              child: _AutoHideLayer(
                visible: _controls.visible,
                child: CallBottomBar(
                  theme: theme,
                  dimensions: dimensions,
                  strings: _strings,
                  isMuted: widget.isMuted,
                  isCameraOff: widget.isCameraOff,
                  isSpeakerOn: widget.isSpeakerOn,
                  onResetHideTimer: _controls.reset,
                  onShowMore: widget.moreSheetBuilder != null
                      ? _showMoreBottomSheet
                      : null,
                  onToggleMute: widget.onToggleMute,
                  onToggleCamera: widget.onToggleCamera,
                  onToggleScreenShare: widget.onToggleScreenShare,
                  isScreenSharing: widget.isScreenSharing,
                  onToggleSpeaker: widget.onToggleSpeaker,
                  onEndCall: widget.onEndCall,
                ),
              ),
            ),

            // Layer 4 — Local PiP view, topmost so it always wins hit-testing
            // against the bars (video calls only).
            if (_showPip)
              LayoutBuilder(
                key: const ValueKey('call-pip'),
                builder: (context, constraints) {
                  final availableSize = constraints.biggest;
                  // FloatingPipView is rooted in an AnimatedPositioned, which
                  // requires a Stack ancestor; this single-child Stack is that
                  // ancestor.
                  return SizedBox.expand(
                    child: Stack(
                      children: [
                        // The PiP follows the controls: while they are hidden
                        // it reclaims the bar areas, and it animates back when
                        // they return, keeping its corner either way.
                        ValueListenableBuilder<bool>(
                          valueListenable: _controls.visible,
                          builder: (context, controlsVisible, _) =>
                              ValueListenableBuilder<bool>(
                            valueListenable: _isSwapped,
                            builder: (context, swapped, _) => FloatingPipView(
                              displayName: swapped
                                  ? widget.callerName
                                  : widget.localParticipant.displayName,
                              theme: theme,
                              dimensions: dimensions,
                              strings: _strings,
                              screenSize: availableSize,
                              topBarHeight: controlsVisible
                                  ? pipTopInsetVisible
                                  : pipTopInsetHidden,
                              controlsHeight: controlsVisible
                                  ? dimensions.bottomBarHeight
                                  : 0,
                              onTap: widget.isCameraOff
                                  ? null
                                  : () {
                                      _controls.reset();
                                      _isSwapped.value = !_isSwapped.value;
                                    },
                              // isCameraOff refers to the local camera, so
                              // blank only the surface currently showing
                              // local video.
                              child: swapped
                                  ? widget.remoteVideoWidget
                                  : (widget.isCameraOff
                                      ? null
                                      : widget.localVideoWidget),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a call-control layer in the shared auto-hide fade.
///
/// Interactivity is tied to the fade, not to the raw visibility flag: a bar
/// that is still fading out stays tappable (the tap performs its action and
/// re-shows the controls), and only a fully invisible bar is inert. Flipping
/// [IgnorePointer] together with the flag would drop taps on buttons that are
/// still plainly visible on screen.
class _AutoHideLayer extends StatefulWidget {
  static const _fadeDuration = Duration(milliseconds: 300);

  final ValueListenable<bool> visible;
  final Widget child;

  const _AutoHideLayer({
    super.key,
    required this.visible,
    required this.child,
  });

  @override
  State<_AutoHideLayer> createState() => _AutoHideLayerState();
}

class _AutoHideLayerState extends State<_AutoHideLayer> {
  late bool _fullyHidden;

  @override
  void initState() {
    super.initState();
    _fullyHidden = !widget.visible.value;
    widget.visible.addListener(_onVisibilityChanged);
  }

  @override
  void didUpdateWidget(covariant _AutoHideLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      oldWidget.visible.removeListener(_onVisibilityChanged);
      widget.visible.addListener(_onVisibilityChanged);
      _fullyHidden = !widget.visible.value;
    }
  }

  @override
  void dispose() {
    widget.visible.removeListener(_onVisibilityChanged);
    super.dispose();
  }

  void _onVisibilityChanged() {
    // Showing is immediate — the user just asked for the controls.
    if (widget.visible.value && _fullyHidden) {
      setState(() => _fullyHidden = false);
    }
  }

  void _onFadeEnd() {
    if (!widget.visible.value && !_fullyHidden) {
      setState(() => _fullyHidden = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.visible,
      builder: (context, visible, child) => IgnorePointer(
        ignoring: _fullyHidden,
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: _AutoHideLayer._fadeDuration,
          onEnd: _onFadeEnd,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
