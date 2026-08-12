import 'package:flutter_callkit_incoming/entities/entities.dart';

import '../config/call_native_config.dart';
import '../models/call_handle.dart';
import 'call_uuid.dart';

/// Single source of truth for how a call is described to the operating system.
///
/// Synchronous on purpose: it is also used from the background isolate, where
/// there is nothing to await and nothing to resolve — every value comes from
/// [config], which was persisted while the app was alive.
CallKitParams buildSystemCallParams(CallHandle call, CallNativeConfig config) {
  final branding = config.branding;
  return CallKitParams(
    id: systemCallUuid(call.callId),
    nameCaller: call.displayName,
    appName: branding.appName,
    avatar: call.avatarUrl,
    handle: config.strings.handleFor(isVideo: call.isVideo),
    type: call.isVideo ? 1 : 0,
    duration: config.timeouts.systemRingDuration.inMilliseconds,
    // The app owns missed-call notifications: it knows whether the user has
    // already seen the call somewhere else.
    missedCallNotification: const NotificationParams(
      showNotification: false,
      isShowCallback: false,
    ),
    callingNotification: NotificationParams(
      showNotification: true,
      subtitle: branding.appName,
    ),
    extra: call.toJson(),
    android: AndroidParams(
      isCustomNotification: true,
      isCustomSmallExNotification: true,
      textAccept: config.strings.acceptAction,
      textDecline: config.strings.declineAction,
      ringtonePath: branding.androidRingtonePath,
      backgroundColor: branding.androidBackgroundColor,
      actionColor: branding.androidActionColor,
      incomingCallNotificationChannelName: branding.androidChannelName,
      missedCallNotificationChannelName: branding.androidChannelName,
      isShowFullLockedScreen: true,
      isImportant: true,
      logoUrl: branding.androidLogoUrl ?? call.avatarUrl,
    ),
    ios: IOSParams(
      supportsVideo: branding.iosSupportsVideo && call.isVideo,
      handleType: branding.iosHandleType,
      audioSessionMode: branding.iosAudioSessionMode,
      audioSessionActive: true,
      configureAudioSession: true,
      maximumCallGroups: branding.iosMaximumCallGroups,
      maximumCallsPerCallGroup: branding.iosMaximumCallsPerGroup,
      supportsHolding: branding.iosSupportsHolding,
      supportsGrouping: branding.iosSupportsGrouping,
      supportsUngrouping: branding.iosSupportsUngrouping,
      supportsDTMF: branding.iosSupportsDtmf,
    ),
  );
}
