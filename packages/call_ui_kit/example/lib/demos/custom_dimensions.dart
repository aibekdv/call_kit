import 'package:call_ui_kit/call_ui_kit.dart';
import 'package:flutter/material.dart';

/// Shows the three ways to size the call UI, switchable at runtime from the
/// "more" sheet so the effect is visible side by side:
///
///  * the presets, [CallDimensions.compact] and [CallDimensions.comfortable];
///  * a per-metric override, naming only the tokens that should change;
///  * [CallDimensions.scale], which multiplies whatever the tokens say.
class CustomDimensionsDemo extends StatefulWidget {
  const CustomDimensionsDemo({super.key});

  @override
  State<CustomDimensionsDemo> createState() => _CustomDimensionsDemoState();
}

enum _Preset {
  compact('Compact'),
  comfortable('Comfortable'),
  custom('Custom tokens');

  const _Preset(this.label);

  final String label;

  CallDimensions get dimensions => switch (this) {
        _Preset.compact => const CallDimensions.compact(),
        _Preset.comfortable => const CallDimensions.comfortable(),
        // Only the metrics named here move; everything else keeps the
        // layout the kit ships with.
        _Preset.custom => const CallDimensions(
            bottomBar: CallBottomBarDimensions(
              buttonSize: 62,
              endCallButtonSize: 76,
              iconSize: 28,
              endCallIconSize: 32,
              barRadius: 48,
            ),
            topBar: CallTopBarDimensions(
              nameFontSize: 20,
              statusFontSize: 15,
              flipIconSize: 34,
            ),
            pip: CallPipDimensions(
              size: Size(130, 175),
              borderRadius: 20,
              margin: 20,
            ),
          ),
      };
}

class _CustomDimensionsDemoState extends State<CustomDimensionsDemo> {
  static const _localVideo = ColoredBox(
    key: ValueKey('local'),
    color: Colors.blueGrey,
  );
  static const _remoteVideo = ColoredBox(
    key: ValueKey('remote'),
    color: Colors.teal,
  );

  var _preset = _Preset.compact;
  var _scale = 1.0;

  bool _isMuted = false;
  bool _isSpeakerOn = true;

  /// The preset supplies the tokens; the slider multiplies them. The two are
  /// independent, which is the point — a host can ship one set of metrics and
  /// still let the device decide how large to draw them.
  CallDimensions get _dimensions =>
      _preset.dimensions.copyWith(scale: _preset.dimensions.scale * _scale);

  @override
  Widget build(BuildContext context) {
    return CallScreen(
      callerName: 'Alex Rivera',
      callType: CallType.video,
      dimensions: _dimensions,
      localParticipant: const CallParticipant(
        id: 'local',
        displayName: 'You',
        isLocalUser: true,
      ),
      localVideoWidget: _localVideo,
      remoteVideoWidget: _remoteVideo,
      isMuted: _isMuted,
      isSpeakerOn: _isSpeakerOn,
      callStatusText: '04:23',
      onEndCall: () => Navigator.pop(context),
      onToggleMute: () => setState(() => _isMuted = !_isMuted),
      onToggleSpeaker: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
      onFlipCamera: () {},
      moreSheetBuilder: (context, theme) => _SizePicker(
        theme: theme,
        preset: _preset,
        scale: _scale,
        onPreset: (value) => setState(() => _preset = value),
        onScale: (value) => setState(() => _scale = value),
      ),
    );
  }
}

class _SizePicker extends StatelessWidget {
  final CallTheme theme;
  final _Preset preset;
  final double scale;
  final ValueChanged<_Preset> onPreset;
  final ValueChanged<double> onScale;

  const _SizePicker({
    required this.theme,
    required this.preset,
    required this.scale,
    required this.onPreset,
    required this.onScale,
  });

  @override
  Widget build(BuildContext context) {
    // Kept deliberately compact: `MoreBottomSheet` sizes itself to its child,
    // so tall content overflows on a short viewport.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.buttonBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final value in _Preset.values)
                ChoiceChip(
                  label: Text(value.label),
                  selected: value == preset,
                  onSelected: (_) => onPreset(value),
                ),
            ],
          ),
          Row(
            children: [
              Text(
                'scale ×${scale.toStringAsFixed(2)}',
                style: TextStyle(color: theme.textPrimary),
              ),
              Expanded(
                child: Slider(
                  value: scale,
                  min: 0.8,
                  max: 1.6,
                  divisions: 8,
                  onChanged: onScale,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
