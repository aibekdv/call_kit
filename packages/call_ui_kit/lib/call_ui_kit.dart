/// A universal call UI kit for Flutter.
///
/// Provides a single [CallScreen] widget that handles personal audio calls,
/// personal video calls, and group video calls. Fully customizable through
/// [CallTheme] for colours, [CallDimensions] for sizes and [CallStrings] for
/// text.
library;

// Models
export 'src/models/call_connection_state.dart';
export 'src/models/call_dimensions.dart';
export 'src/models/call_participant.dart';
export 'src/models/call_type.dart';
export 'src/models/call_strings.dart';
export 'src/models/call_theme.dart';

// Screens
export 'src/screens/call_screen.dart';
export 'src/screens/incoming_call_screen.dart';
export 'src/screens/outgoing_call_screen.dart';

// Widgets
export 'src/widgets/call_avatar.dart';
export 'src/widgets/participant_tile.dart';
export 'src/widgets/floating_pip_view.dart';
export 'src/widgets/speaking_indicator.dart';
export 'src/widgets/screen_share_banner.dart';
export 'src/widgets/connection_state_banner.dart';
export 'src/widgets/more_bottom_sheet.dart';
export 'src/widgets/participants_panel.dart';
export 'src/widgets/signal_strength_icon.dart';
export 'src/widgets/video_surface.dart';

// Utils
export 'src/utils/group_call_layout_resolver.dart';
export 'src/utils/pip_snap_calculator.dart';
