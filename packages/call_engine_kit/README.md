# call_engine_kit

A LiveKit-backed audio and video call engine for Flutter.

The engine runs the call — lifecycle state machine, timeouts, media controls,
screen share, reconnection — and knows nothing about your backend. That part
goes behind one interface.

System call UI (CallKit, PushKit, picture-in-picture) comes from
[call_native_kit](https://github.com/aibekdv/call_kit/tree/master/packages/call_native_kit), which this package depends on. Call
screens come from
[call_ui_kit](https://github.com/aibekdv/call_kit/tree/master/packages/call_ui_kit),
or from your own widgets.

> **Status: pre-release.** The engine is complete — state machine, timers,
> media, screen share, in-call chat, reconnection, the `CallEngine` facade and
> an optional overlay in `package:call_engine_kit/overlay.dart`. What has not
> happened yet is a call between two real devices: everything a unit test can
> reach is tested, and everything it cannot — PushKit, the system call screen,
> audio-session handover, picture-in-picture — is not.

## Install

```yaml
dependencies:
  call_engine_kit: ^0.1.0
```

## Use

```dart
final engine = await CallEngine.create(CallEngineConfig(
  signaling: MySignaling(),
  strings: () => const CallEngineStrings.english(),
));

// Place a call.
await engine.controller.startOutgoingCall(
  fetchConnection: () => engine.signaling.initiateCall(
    const CallInitiationRequest(participantIds: ['42'], isVideo: true),
  ),
  roomName: 'call-with-42',
  displayName: 'Aibek',
  isVideo: true,
);

// Render it.
ValueListenableBuilder(
  valueListenable: engine.controller.session,
  builder: (context, session, _) => switch (session.status) {
    CallLifecycleState.incomingRinging => IncomingCallScreen(/* ... */),
    CallLifecycleState.inCall => CallScreen(/* ... */),
    _ => const SizedBox.shrink(),
  },
);
```

Incoming calls need no wiring: `CallEngine.create` registers for them, answers
the system's questions before it rings, and joins a call the user accepted
while the app was not running.

Feed it foreground pushes:

```dart
FirebaseMessaging.onMessage.listen((message) {
  engine.handleForegroundPush(message.data, sentTime: message.sentTime);
});
```

## The one interface you implement

```dart
abstract interface class CallSignalingClient {
  Future<CallConnectionInfo> initiateCall(CallInitiationRequest request);
  Future<CallConnectionInfo> joinCall({required String callId, required String roomName});
  Future<void> endCall(String callId);
  Future<void> declineCall(String callId);
  Future<void> cancelCall(String callId);
  Future<void> leaveCall(String callId);
  Future<void> heartbeat(String callId);
  Future<CallStatusInfo?> fetchStatus(String callId);
}
```

That is the whole contract with your server: create a call, join it, end it,
and say whether it is still ringing.

## There is no shipped implementation, on purpose

Any adapter this package could ship would encode one particular API's paths,
body keys and spellings — `POST /calls`, `"type": "VIDEO"`, `livekitHost` —
and yours will differ. Configuring your way out of somebody else's request
body is more work than writing your own, and a class named `RestSignaling…`
that only fits one REST API is worse than none: it reads like the recommended
path.

So the package ships the interface, and a worked example lives in
[`example/lib/signaling/rest_call_signaling_client.dart`](https://github.com/aibekdv/call_kit/blob/master/example/lib/signaling/rest_call_signaling_client.dart).
Copy it into your app and edit the literals — they are literals precisely so
they are easy to find and change.

Two things in it are worth keeping whatever your API looks like, because both
are call semantics rather than transport:

* **If creating a call succeeds but joining it fails, cancel the call.**
  Otherwise the callee's phone rings for a call the caller will never be on the
  other end of, and they are left with a missed call from nobody.
* **A call the server has forgotten is `ended`, not an error.** Returning
  `CallLiveStatus.ended` for a 404 stops the phone ringing for calls that are
  over; throwing instead makes it ring.

Note what the interface does not involve: an HTTP client. This package brings
neither `dio` nor `http`, and the example takes a plain function so it keeps
your interceptors, auth and retry policy.

## State

The engine exposes the call as six separate listenables rather than one blob,
because the parts change at very different rates — a mute button when the user
taps it, the active-speaker indicator several times a second. One combined
listenable would rebuild every video surface on each of those.

```dart
ValueListenable<CallSessionState> session;       // status, who, video, error
ValueListenable<CallMediaState> media;           // mute, camera, audio route
ValueListenable<CallParticipantsState> participants;
ValueListenable<CallScreenShareState> screenShare;
ValueListenable<CallViewState> view;             // overlay, layout, pip
ValueListenable<CallTimingState> timing;         // when it connected
```

`CallSnapshot` aggregates all six, and is also available as a stream for
consumers that prefer one subscription to six listeners.

## Lifecycle

```
idle ──> outgoingRinging ──┐
     └─> incomingRinging ──┴─> connecting ──> inCall ⇄ reconnecting
                                                  └──> ended | failed
```

Transitions are validated. A call has several sources of truth racing each
other — the user, the signalling server, the media server and the system call
UI can all report an outcome, and not always in order — so without validation a
late "connecting" from a slow join drags a hung-up call back to life.

Ending is allowed from anywhere. Nothing is allowed after it.

## Timeouts

Every deadline is injected through `CallTimeouts`, which makes them tunable and
makes the timer logic testable with `fake_async` rather than by waiting forty
seconds.

| | default | what it prevents |
| --- | --- | --- |
| `ringing` | 40 s | ringing forever at nobody |
| `connecting` | 30 s | a join that never completes |
| `reconnect` | 45 s | a reconnect that never lands |
| `answerGuard` | 15 s | an accept being torn down mid-flight |
| `heartbeat` | 30 s | the server keeping a dead call alive |
| `outgoingCloseDelay` | 3 s | the caller's screen closing before the callee's |

## Localization

The engine never localizes anything. Pass a *resolver*, not a value:

```dart
CallEngineConfig(
  strings: () => CallEngineStrings(you: 'Вы', /* … */),
  // ...
);
```

It is read on each access, so a locale change takes effect mid-call.

## License

MIT
