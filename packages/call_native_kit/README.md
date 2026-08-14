# call_native_kit

The operating system's own call UI for Flutter, with no opinion about how your
calls are signalled or carried.

* **iOS** — CallKit and PushKit, so a call rings on the lock screen and appears
  in the phone's call history.
* **Android** — a full-screen incoming-call notification that works over the
  lock screen.
* **Both** — picture-in-picture, and manual-mode control of the WebRTC audio
  session.

Bring your own media stack. If you want a LiveKit-based one, see
[call_engine_kit](../call_engine_kit).

## Install

```yaml
dependencies:
  call_native_kit: ^0.1.0
```

## Use

```dart
final calls = CallNativeKit.instance;

await calls.configure(CallNativeConfig(
  strings: CallNativeStrings(
    audioCallHandle: 'Аудиозвонок',
    videoCallHandle: 'Видеозвонок',
    incomingCallFallbackName: 'Входящий звонок',
    acceptAction: 'Принять',
    declineAction: 'Отклонить',
    notificationPermissionTitle: '…',
    notificationPermissionRationale: '…',
    notificationPermissionSettings: '…',
  ),
  branding: const CallNativeBranding(appName: 'My App'),
));
await calls.initialize();

calls.events.listen((event) {
  switch (event) {
    case SystemCallActionReceived(:final action)
        when action.kind == SystemCallActionKind.accept:
      joinCall(action.call!);            // your media stack
    case SystemCallActionReceived(:final action)
        when action.kind == SystemCallActionKind.decline:
      declineOnServer(action.call!.callId);
    case VoipPushTokenUpdated(:final token):
      registerVoipToken(token);          // iOS only
    default:
      break;
  }
});
```

Incoming pushes while the app is running:

```dart
const mapper = DefaultCallPushMapper();
FirebaseMessaging.onMessage.listen((message) async {
  final push = mapper.parse(message.data);
  if (push case IncomingCallPush()) {
    await calls.handleIncomingPush(push, sentTime: message.sentTime);
  } else if (push case CallCancelledPush()) {
    await calls.handleCancelledPush(push);
  }
});
```

…and while it is not:

```dart
@pragma('vm:entry-point')
Future<void> backgroundHandler(RemoteMessage message) async {
  if (const DefaultCallPushMapper().isCallPush(message.data)) {
    await handleBackgroundCallPush(message.data, sentTime: message.sentTime);
    return;
  }
  // your other notifications
}
```

Tell the plugin when a call is up, so a second push does not stack another
call screen on top of it:

```dart
await calls.setActiveCall(active: true);
```

And at startup, recover a call the user accepted while the app was not running:

```dart
final pending = await calls.takePendingAcceptedCall();
if (pending != null) joinCall(pending.call);
```

## Your push payload

`DefaultCallPushMapper` reads a flat payload:

```json
{"type": "incoming_call", "call_id": "314", "call_type": "video",
 "caller_name": "Aibek", "is_group": false,
 "livekit_room": "call_314", "timeout_at": "2026-08-12T09:00:40Z"}
```

Different field names? Pass a `CallPushFieldNames`. Different shape entirely —
nested, or a JSON string inside a `metadata` field? Implement `CallPushMapper`.

Two fields are worth sending even though both are optional:

* `livekit_room` (or whatever you name it) — otherwise the room name is derived
  from a template, which is a convention two systems then have to keep agreeing
  on.
* `timeout_at` — lets the plugin drop a push for a call that already stopped
  ringing, instead of waking someone for nothing.

## Platform setup

Some of this cannot be automated. Where that is the case, the reason is given —
they are not arbitrary.

### iOS

If your app has no `AppDelegate` work of its own:

```swift
import call_native_kit

@main
@objc class AppDelegate: CallNativeKitAppDelegate {}
```

If it does, keep yours and forward to `CallNativeKitHost` — see that class's
documentation for the full example. What you cannot skip: your delegate has to
conform to `CallkitIncomingAppDelegate` and forward `didActivateAudioSession`.
CallKit dispatches through `UIApplication.shared.delegate`, so there is no way
for a plugin to intercept it. **If that forwarding is missing, a call accepted
through CallKit connects, publishes tracks, reports healthy — and has no
audio.**

In Xcode, enable **Background Modes → Voice over IP** and **Remote
notifications**, and **Push Notifications**. In `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>voip</string>
  <string>audio</string>
  <string>remote-notification</string>
</array>
```

Minimum iOS 13. Picture-in-picture requires iOS 15 and is simply not offered
below it.

### Android

```kotlin
import dev.aibekdv.call_native_kit.CallNativeKitActivity

class MainActivity : CallNativeKitActivity()
```

That is the whole setup. `FlutterActivity` extends the plain `Activity` rather
than `ComponentActivity`, so `onPictureInPictureModeChanged` has no listener a
plugin could register, and `onUserLeaveHint` has none at all. If your activity
must extend something else, override both and forward to
`CallNativeKitPlugin.current`.

In the manifest:

```xml
<activity android:name=".MainActivity"
          android:supportsPictureInPicture="true"
          ... />
```

Without that attribute every request to shrink the window is refused.

Minimum SDK 24. Call permissions and services are merged in from
`flutter_callkit_incoming`.

## Picture-in-picture

The two platforms differ in a way that leaks into the API.

**Android** renders your own Flutter tree in the small window — you keep
drawing, with much less room. Because the window *is* the app, a mode change
can be missed, so re-sync with `queryIsInPip()` when the window metrics change.

**iOS** renders a native surface fed one WebRTC video track. Nothing of your
Flutter tree is visible, so you must say which track to show:

```dart
await calls.pip.setActiveVideoCall(active: true);
await calls.pip.attachTrack(trackId: remoteTrack.sid);
await calls.pip.enterPip();
```

It never picks a track on its own. An earlier version did, and reliably latched
onto a screen share where the user expected a face. Pass `null` to detach.

## Audio

For a call the user accepted on the system UI, **wait** — do not activate:

```dart
await calls.audio.awaitActive();
```

For a call started inside the app, activate:

```dart
await calls.audio.activate(defaultToSpeaker: true);
```

Getting this backwards is the silent-call failure described above. If you are
chasing one, `calls.audio.diagnostics()` reports how many times the system
actually activated the session — zero during a CallKit call means the delegate
chain is broken.

## Trying it

`example/` is a manual test rig, not a demo: a push simulator that takes raw
JSON, buttons for every system-UI call, and a live diagnostics panel. The parts
of a VoIP stack that only a real device exercises are all in there.

```bash
cd example && flutter run
```

## License

MIT
