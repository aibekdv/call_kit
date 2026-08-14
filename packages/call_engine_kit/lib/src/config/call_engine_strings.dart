/// Every message the engine can put in front of a user.
///
/// The engine never localizes anything itself. Pass translated values in, and
/// pass a *resolver* rather than a value — `CallEngineConfig.strings` is
/// called each time, so a locale change is picked up without rebuilding the
/// engine mid-call.
class CallEngineStrings {
  const CallEngineStrings({
    required this.you,
    required this.couldNotStartCall,
    required this.couldNotConnect,
    required this.noConnection,
    required this.callAlreadyActive,
    required this.noAnswer,
    required this.partyBusy,
    required this.reconnectFailed,
    required this.microphoneAccessRequired,
    required this.cameraAccessRequired,
    required this.permissionRequestFailed,
    required this.screenShareBlocked,
    required this.screenShareNotificationTitle,
    required this.screenShareNotificationText,
    required this.noParticipants,
  });

  const CallEngineStrings.english()
      : you = 'You',
        couldNotStartCall = 'Could not start the call',
        couldNotConnect = 'Could not connect',
        noConnection = 'No internet connection',
        callAlreadyActive = 'You are already on a call',
        noAnswer = 'No answer',
        partyBusy = 'Busy',
        reconnectFailed = 'Connection lost',
        microphoneAccessRequired = 'Microphone access is required for calls',
        cameraAccessRequired = 'Camera access is required for video calls',
        permissionRequestFailed = 'Could not request permissions',
        screenShareBlocked = 'Someone else is already sharing their screen',
        screenShareNotificationTitle = 'Screen sharing',
        screenShareNotificationText = 'Your screen is being shared',
        noParticipants = 'Nobody to call';

  /// Label for the local participant.
  final String you;

  final String couldNotStartCall;
  final String couldNotConnect;
  final String noConnection;

  /// Shown when a second call is started while one is running.
  final String callAlreadyActive;

  final String noAnswer;
  final String partyBusy;
  final String reconnectFailed;

  final String microphoneAccessRequired;
  final String cameraAccessRequired;
  final String permissionRequestFailed;

  final String screenShareBlocked;

  /// Android requires a visible foreground-service notification while the
  /// screen is being captured.
  final String screenShareNotificationTitle;
  final String screenShareNotificationText;

  /// Shown when a group call is started with nobody to call.
  final String noParticipants;
}

/// Read on every access, so a locale change takes effect mid-call.
typedef CallEngineStringsResolver = CallEngineStrings Function();
