import 'package:call_native_kit/call_native_kit.dart' show CallHandle;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../engine/live_kit_room_service.dart';
import '../ports/call_logger.dart';
import '../ports/call_permissions_delegate.dart';
import '../ports/call_room_service.dart';
import '../ports/call_signaling_client.dart';
import 'call_engine_strings.dart';
import 'call_timeouts.dart';

/// Everything the engine needs from you.
///
/// Only two entries are required: how to talk to your server, and what to say
/// to the user. The rest has defaults that suit most apps and exist to be
/// replaced in tests.
class CallEngineConfig {
  const CallEngineConfig({
    required this.signaling,
    required this.strings,
    this.roomService,
    this.permissions = const PermissionHandlerDelegate(),
    this.connectivity,
    this.logger = const SilentCallLogger(),
    this.timeouts = const CallTimeouts(),
    this.roomOptions = const CallRoomOptions(),
    this.onCallNotificationTapped,
  });

  /// How calls are created, joined and ended on your server.
  final CallSignalingClient signaling;

  /// Read on every access, so a locale change takes effect mid-call.
  final CallEngineStringsResolver strings;

  /// Defaults to [LiveKitRoomService]. Replace it to run the engine against a
  /// fake in tests.
  final CallRoomService? roomService;

  final CallPermissionsDelegate permissions;

  /// Defaults to a fresh [Connectivity].
  final Connectivity? connectivity;

  final CallLogger logger;
  final CallTimeouts timeouts;
  final CallRoomOptions roomOptions;

  /// The user tapped a missed-call notification to call back.
  final void Function(CallHandle call)? onCallNotificationTapped;
}
