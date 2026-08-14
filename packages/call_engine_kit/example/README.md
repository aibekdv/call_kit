# call_engine_kit example

Runs a real call through the engine.

## Without a server

```bash
flutter run
```

Everything up to connecting works: placing a call, the outgoing screen, the
push gate, the system call UI, hanging up. The connect step fails, and the app
says so — there is no LiveKit server to connect to.

"Simulate incoming" feeds a payload through the same path a real push takes —
mapper, gate, system call UI, engine — and shows what the gate decided.

## With one

Get a room and two tokens from [LiveKit Cloud](https://cloud.livekit.io) — the
sandbox is free — and run on two devices:

```bash
flutter run \
  --dart-define=LIVEKIT_URL=wss://your-project.livekit.cloud \
  --dart-define=LIVEKIT_TOKEN=<token for device A> \
  --dart-define=LIVEKIT_ROOM=demo
```

Tokens are passed in rather than minted here on purpose: minting one needs an
API secret, and an API secret has no business being in an app.

## What to check on a device

The parts a unit test cannot reach, roughly in order of how quietly they break:

1. **Audio on an accepted call.** Accept from the lock screen and confirm you
   can hear the other side. This is the failure that looks like success
   everywhere else.
2. **Picture-in-picture.** Start a video call, then leave the app. iOS should
   show the remote video, not a black rectangle; Android should shrink the
   call, not the whole home screen.
3. **Cold start.** Force-quit, have the other side call you, accept from the
   lock screen. The app should launch straight into the call.
4. **Hang up and call again immediately.** Both sides should see video the
   second time — this is the case the serialized connect queue exists for.
5. **Screen share**, on both platforms, and stopping it from the system UI
   rather than from the app.
