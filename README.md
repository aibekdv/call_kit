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

## Getting started

```yaml
dependencies:
  call_engine_kit: ^0.1.0
```

Then implement one interface — how your server creates, joins and ends calls:

```dart
class MySignaling implements CallSignalingClient { /* ... */ }
```

If your API looks like `POST /calls`, `POST /calls/{id}/join`, `POST /calls/{id}/end`, start from `RestCallSignalingClient` instead and pass it your own HTTP transport; the package brings no HTTP client of its own.

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
