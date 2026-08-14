# call_kit

Audio and video calling for Flutter, split into packages you can adopt one at a time.

| Package | Description | Pub |
| --- | --- | --- |
| [call_native_kit](packages/call_native_kit) | The operating system's own call UI: CallKit and PushKit on iOS, full-screen incoming calls on Android, picture-in-picture, and manual-mode control of the WebRTC audio session. No opinion about how calls are signalled or carried. | not yet published |
| [call_engine_kit](packages/call_engine_kit) | A LiveKit-backed call engine: lifecycle state machine, timers, media controls, screen share, reconnection. Your backend goes behind one interface. | not yet published |

The call screens live in [call_ui_kit](https://github.com/aibekdv/call_ui_kit), which is published separately and has no dependency on either of these — use it, or bring your own UI.

## How the pieces fit

```
        your app
           │
           ├── call_ui_kit ......... screens
           │
      call_engine_kit ............. runs the call (LiveKit)
           │
     call_native_kit .............. talks to the operating system
```

`call_native_kit` is useful on its own if you already have a media stack and only need the system call UI. `call_engine_kit` depends on it.

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

Pre-1.0 and not yet on pub.dev. `call_native_kit` is complete and builds on both
platforms; `call_engine_kit` is in progress.

## License

MIT — see [LICENSE](LICENSE).
