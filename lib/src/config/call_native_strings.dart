/// Every user-visible string the plugin can show.
///
/// The plugin never localizes anything itself and never depends on a
/// localization package: pass the already-translated values in through
/// [CallNativeKit.configure] and call it again when the locale changes.
///
/// These strings must also be readable from the FCM background isolate and
/// from native code, so [CallNativeKit.configure] persists them. See
/// `CallNativeConfig` for the full invariant.
class CallNativeStrings {
  const CallNativeStrings({
    required this.audioCallHandle,
    required this.videoCallHandle,
    required this.incomingCallFallbackName,
    required this.acceptAction,
    required this.declineAction,
    required this.notificationPermissionTitle,
    required this.notificationPermissionRationale,
    required this.notificationPermissionSettings,
  });

  /// English defaults, used until [CallNativeKit.configure] runs — including
  /// the very first background push after install.
  const CallNativeStrings.english()
      : audioCallHandle = 'Audio call',
        videoCallHandle = 'Video call',
        incomingCallFallbackName = 'Incoming call',
        acceptAction = 'Accept',
        declineAction = 'Decline',
        notificationPermissionTitle = 'Allow notifications',
        notificationPermissionRationale =
            'Notifications are required to show incoming calls.',
        notificationPermissionSettings = 'Settings';

  /// Shown as the CallKit handle for an audio call.
  final String audioCallHandle;

  /// Shown as the CallKit handle for a video call.
  final String videoCallHandle;

  /// Caller name used when the push carries none.
  final String incomingCallFallbackName;

  /// Label of the accept action on the Android full-screen call notification.
  final String acceptAction;

  /// Label of the decline action on the Android full-screen call notification.
  final String declineAction;

  /// Title of the Android notification-permission prompt.
  final String notificationPermissionTitle;

  /// Body of the Android notification-permission prompt.
  final String notificationPermissionRationale;

  /// Confirm-button label of the Android notification-permission prompt.
  final String notificationPermissionSettings;

  /// Handle to show for a call of the given kind.
  String handleFor({required bool isVideo}) =>
      isVideo ? videoCallHandle : audioCallHandle;

  Map<String, Object?> toJson() => {
        'audioCallHandle': audioCallHandle,
        'videoCallHandle': videoCallHandle,
        'incomingCallFallbackName': incomingCallFallbackName,
        'acceptAction': acceptAction,
        'declineAction': declineAction,
        'notificationPermissionTitle': notificationPermissionTitle,
        'notificationPermissionRationale': notificationPermissionRationale,
        'notificationPermissionSettings': notificationPermissionSettings,
      };

  factory CallNativeStrings.fromJson(Map<String, Object?> json) {
    const fallback = CallNativeStrings.english();
    String read(String key, String or) => json[key] as String? ?? or;
    return CallNativeStrings(
      audioCallHandle: read('audioCallHandle', fallback.audioCallHandle),
      videoCallHandle: read('videoCallHandle', fallback.videoCallHandle),
      incomingCallFallbackName: read(
        'incomingCallFallbackName',
        fallback.incomingCallFallbackName,
      ),
      acceptAction: read('acceptAction', fallback.acceptAction),
      declineAction: read('declineAction', fallback.declineAction),
      notificationPermissionTitle: read(
        'notificationPermissionTitle',
        fallback.notificationPermissionTitle,
      ),
      notificationPermissionRationale: read(
        'notificationPermissionRationale',
        fallback.notificationPermissionRationale,
      ),
      notificationPermissionSettings: read(
        'notificationPermissionSettings',
        fallback.notificationPermissionSettings,
      ),
    );
  }
}
