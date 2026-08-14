# call_engine_kit

A LiveKit-backed audio and video call engine for Flutter.

The engine runs the call — lifecycle state machine, timeouts, media controls,
screen share, reconnection — and knows nothing about your backend. That part
goes behind one interface.

System call UI (CallKit, PushKit, picture-in-picture) comes from
[call_native_kit](../call_native_kit), which this package depends on. Call
screens come from [call_ui_kit](https://github.com/aibekdv/call_ui_kit), or
from your own widgets.

> **Status: in progress.** The state machine, timers, entities, ports and the
> REST adapter are done and tested. The media layer, the orchestrating
> `CallEngine` facade and the optional overlay are not written yet, so this is
> not usable end to end.

## Install

```yaml
dependencies:
  call_engine_kit: ^0.1.0
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

## If your API already looks like this

```
POST /calls                  -> { id, livekitRoom }
POST /calls/{id}/join        -> { token, livekitHost }
POST /calls/{id}/end | /decline | /cancel | /leave | /heartbeat
GET  /calls/{id}/status      -> { status }
```

use the adapter instead of writing one:

```dart
final signaling = RestCallSignalingClient(
  transport: (method, path, {body, query}) async {
    final response = await dio.request<Map<String, Object?>>(
      path,
      data: body,
      queryParameters: query,
      options: Options(method: method),
    );
    return response.data;
  },
);
```

Note what it does *not* take: an HTTP client. This package brings neither `dio`
nor `http` — you pass a function, and keep your own interceptors, auth and
retry policy. Paths and field names are configurable via `basePath` and
`RestCallFieldNames`.

The adapter also handles one thing that is easy to miss: if creating a call
succeeds but joining it fails, it cancels the call. Otherwise the callee's
phone rings for a call the caller will never be on the other end of, and they
are left with a missed call from nobody.

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
