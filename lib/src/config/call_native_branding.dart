/// Look of the system call UI.
class CallNativeBranding {
  const CallNativeBranding({
    this.appName = 'Call',
    this.androidBackgroundColor = '#1565C0',
    this.androidActionColor = '#4CAF50',
    this.androidRingtonePath = 'system_ringtone_default',
    this.androidLogoUrl,
    this.androidChannelName = 'Incoming calls',
    this.androidChannelDescription = 'Shows incoming call notifications',
    this.iosSupportsVideo = true,
    this.iosSupportsHolding = false,
    this.iosSupportsDtmf = false,
    this.iosSupportsGrouping = false,
    this.iosSupportsUngrouping = false,
    this.iosMaximumCallGroups = 1,
    this.iosMaximumCallsPerGroup = 1,
    this.iosHandleType = 'generic',
    this.iosAudioSessionMode = 'voiceChat',
  });

  /// Shown by CallKit as the calling app, and on the Android notification.
  final String appName;

  /// Background of the Android full-screen incoming-call UI, as `#RRGGBB`.
  final String androidBackgroundColor;

  /// Accent of the accept action on Android, as `#RRGGBB`.
  final String androidActionColor;

  /// `system_ringtone_default`, or a raw resource name bundled by the host app.
  final String androidRingtonePath;

  /// Optional logo shown on the Android incoming-call screen.
  final String? androidLogoUrl;

  final String androidChannelName;
  final String androidChannelDescription;

  final bool iosSupportsVideo;
  final bool iosSupportsHolding;
  final bool iosSupportsDtmf;
  final bool iosSupportsGrouping;
  final bool iosSupportsUngrouping;
  final int iosMaximumCallGroups;
  final int iosMaximumCallsPerGroup;

  /// CallKit handle type: `generic`, `number` or `email`.
  final String iosHandleType;

  /// `AVAudioSession` mode CallKit configures: `voiceChat` or `videoChat`.
  final String iosAudioSessionMode;

  Map<String, Object?> toJson() => {
        'appName': appName,
        'androidBackgroundColor': androidBackgroundColor,
        'androidActionColor': androidActionColor,
        'androidRingtonePath': androidRingtonePath,
        'androidLogoUrl': androidLogoUrl,
        'androidChannelName': androidChannelName,
        'androidChannelDescription': androidChannelDescription,
        'iosSupportsVideo': iosSupportsVideo,
        'iosSupportsHolding': iosSupportsHolding,
        'iosSupportsDtmf': iosSupportsDtmf,
        'iosSupportsGrouping': iosSupportsGrouping,
        'iosSupportsUngrouping': iosSupportsUngrouping,
        'iosMaximumCallGroups': iosMaximumCallGroups,
        'iosMaximumCallsPerGroup': iosMaximumCallsPerGroup,
        'iosHandleType': iosHandleType,
        'iosAudioSessionMode': iosAudioSessionMode,
      };

  factory CallNativeBranding.fromJson(Map<String, Object?> json) {
    const fallback = CallNativeBranding();
    return CallNativeBranding(
      appName: json['appName'] as String? ?? fallback.appName,
      androidBackgroundColor: json['androidBackgroundColor'] as String? ??
          fallback.androidBackgroundColor,
      androidActionColor:
          json['androidActionColor'] as String? ?? fallback.androidActionColor,
      androidRingtonePath: json['androidRingtonePath'] as String? ??
          fallback.androidRingtonePath,
      androidLogoUrl: json['androidLogoUrl'] as String?,
      androidChannelName:
          json['androidChannelName'] as String? ?? fallback.androidChannelName,
      androidChannelDescription: json['androidChannelDescription'] as String? ??
          fallback.androidChannelDescription,
      iosSupportsVideo:
          json['iosSupportsVideo'] as bool? ?? fallback.iosSupportsVideo,
      iosSupportsHolding:
          json['iosSupportsHolding'] as bool? ?? fallback.iosSupportsHolding,
      iosSupportsDtmf:
          json['iosSupportsDtmf'] as bool? ?? fallback.iosSupportsDtmf,
      iosSupportsGrouping:
          json['iosSupportsGrouping'] as bool? ?? fallback.iosSupportsGrouping,
      iosSupportsUngrouping: json['iosSupportsUngrouping'] as bool? ??
          fallback.iosSupportsUngrouping,
      iosMaximumCallGroups:
          json['iosMaximumCallGroups'] as int? ?? fallback.iosMaximumCallGroups,
      iosMaximumCallsPerGroup: json['iosMaximumCallsPerGroup'] as int? ??
          fallback.iosMaximumCallsPerGroup,
      iosHandleType: json['iosHandleType'] as String? ?? fallback.iosHandleType,
      iosAudioSessionMode: json['iosAudioSessionMode'] as String? ??
          fallback.iosAudioSessionMode,
    );
  }
}
