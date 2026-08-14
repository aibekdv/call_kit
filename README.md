# call_kit

Audio and video calling for Flutter, split into packages you can adopt one at a time.

| Package | Description | Pub |
| --- | --- | --- |
| [call_native_kit](packages/call_native_kit) | The operating system's own call UI: CallKit and PushKit on iOS, full-screen incoming calls on Android, picture-in-picture, and manual-mode control of the WebRTC audio session. No opinion about how calls are signalled or carried. | not yet published |
| [call_engine_kit](packages/call_engine_kit) | A LiveKit-backed call engine: lifecycle state machine, timers, media controls, screen share, reconnection. Your backend goes behind one interface. | not yet published |
| [call_ui_kit](packages/call_ui_kit) | The call screens — incoming, outgoing and in-call, for personal and group calls. Depends on nothing but Flutter, so it is equally useful on its own. | [0.6.0](https://pub.dev/packages/call_ui_kit) |

Each is useful without the others. `call_native_kit` is the one to take if you
already have a media stack and only need the system call UI; `call_ui_kit` if
you only need screens.

## How the pieces fit

```
        your app
           │
      call_engine_kit ............. runs the call (LiveKit)
           │
           ├── call_ui_kit ........ screens, via the optional overlay
           │
     call_native_kit .............. talks to the operating system
```

`call_engine_kit` is headless by default. Import
`package:call_engine_kit/overlay.dart` to get the ready-made call screens, or
leave it out and render the state yourself.

## Try it

[`example/`](example) is a small messenger built on all three: sign in as
somebody, call somebody else, see the history, and watch what the operating
system is doing underneath. Two devices and a local LiveKit server, no backend:

```bash
docker run --rm -p 7880:7880 -p 7881:7881 -p 7882:7882/udp \
  livekit/livekit-server --dev --bind 0.0.0.0

cd example
flutter run --dart-define=LIVEKIT_URL=ws://192.168.1.10:7880
```

Each package also has its own example, narrower on purpose:

| | For |
| --- | --- |
| [`example/`](example) | how the three fit together — **start here** |
| [`packages/call_native_kit/example`](packages/call_native_kit/example) | the system call UI on its own: push simulator, picture-in-picture, audio diagnostics |
| [`packages/call_engine_kit/example`](packages/call_engine_kit/example) | the engine at its smallest: one button, one call |
| [`packages/call_ui_kit/example`](packages/call_ui_kit/example) | the screens as static layouts, no engine |

## Getting started

```yaml
dependencies:
  call_engine_kit: ^0.1.0
```

Then implement one interface — how your server creates, joins and ends calls:

```dart
class MySignaling implements CallSignalingClient { /* ... */ }
```

Eight methods, no assumptions about your paths, your body keys or your
spellings — the packages contain no request shape at all. A worked REST
implementation to copy and edit is in
[`example/lib/signaling/rest_call_signaling_client.dart`](example/lib/signaling/rest_call_signaling_client.dart).

Platform setup — the parts that cannot be automated, and why — is documented in each package's README.

## Working on this repo

Uses [Melos](https://melos.invertase.dev) on top of Dart pub workspaces.

```bash
dart pub global activate melos
melos bootstrap        # resolve every package at once
melos run verify       # format check, analyze, test
melos run publish-check
```

Individual packages build and test normally too:

```bash
cd packages/call_native_kit && flutter test
cd example && flutter run          # the manual test rig
```

## Status

Pre-1.0. All three packages build on both platforms, pass
`dart pub publish --dry-run` cleanly, and are covered by ~300 unit tests.

What has *not* happened yet is a call between two real devices. Everything a
unit test can reach is tested; everything it cannot — PushKit delivery, the
system call screen, audio-session handover, picture-in-picture, recovery after
the app is killed mid-call — needs the manual pass described in each example's
README before this is worth trusting in production.

## License

MIT — see [LICENSE](LICENSE).
