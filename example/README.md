# call_kit example

A small messenger that puts all three packages together: sign in as somebody,
call somebody else, see what happened, and watch what the operating system is
doing underneath.

This is the app to read first. The per-package examples exist to exercise one
package in isolation; this one shows how they fit.

## Run it

Two devices, one LiveKit server, no backend:

```bash
# on your machine
docker run --rm -p 7880:7880 -p 7881:7881 -p 7882:7882/udp \
  livekit/livekit-server --dev --bind 0.0.0.0

# on each device — use your machine's address on the network, not localhost
flutter run --dart-define=LIVEKIT_URL=ws://192.168.1.10:7880
```

Sign in as **Alice** on one and **Bob** on the other, then call across. Both
sides derive the same room name from the pair, so it does not matter who calls
first.

The server address can also be typed on the sign-in screen, which is easier
than rebuilding when your laptop changes networks.

### Against a real server

```bash
flutter run \
  --dart-define=LIVEKIT_URL=wss://your-project.livekit.cloud \
  --dart-define=LIVEKIT_TOKEN=<a join token>
```

A token you pass in always wins over the one the app mints.

## What each package is doing

**`call_native_kit`** — the system call screen, PushKit, picture-in-picture and
the audio session. The **Diagnostics** tab shows its state, and the language
switch there re-runs `CallNativeKit.configure`. That is not decoration: the
config is persisted, and a call arriving while the app is dead is drawn from
whatever was written last. Switch to Русский, force-quit, simulate a push —
the system screen is in Russian.

**`call_engine_kit`** — `CallEngine.create` in `main.dart`, and one call to
`startOutgoingCall` in `contacts_page.dart`. That is the whole integration.
History is written by the app from `controller.session`, because the engine
does not store any and should not.

**`call_ui_kit`** — the call screens, with a theme that is deliberately not the
default and strings in two languages, passed through `CallOverlay`. Minimizing
a call hands control back to the app through `minimizedBuilder`.

## What it cannot do, and why

There is no signalling server, so **calling somebody really means joining the
room you share with them**. A phone rings only when a server tells it to.

The **Simulate a push** control on the Diagnostics tab covers that path
instead: it feeds the engine the same payload FCM would deliver, through the
same mapper and the same gate, and shows the gate's decision. That is how the
incoming-call flow — system screen, accept, join, cold-start recovery — gets
exercised without a backend.

## About the token

In development the app signs its own LiveKit token, with the published
`devkey`/`secret` that `livekit-server --dev` starts with. That is why it runs
in one command.

**Do not copy that part.** `dev_token_minter.dart` explains why at length and
throws in release builds rather than relying on the explanation. A real app
gets its token from a server, which is what `CallSignalingClient` is for.

## Manual checks

The parts no unit test reaches, roughly in order of how quietly they break:

1. **Audio on an accepted call.** Accept from the lock screen; confirm you can
   hear the other side. The one failure that looks like success everywhere
   else. Diagnostics shows the audio session's activation count — zero during
   a CallKit call means the delegate chain is broken.
2. **Picture-in-picture.** Video call, then leave the app. iOS should show the
   remote video; Android should shrink the call, not the home screen.
3. **Cold start.** Force-quit, have the other side call, accept from the lock
   screen — the app should launch straight into the call.
4. **Hang up and call again immediately.** Video should work the second time
   too; this is what the serialized connect queue in `LiveKitRoomService` is
   for.
5. **Language switch**, then the next incoming call — the system screen should
   follow.
6. **Screen share** on both platforms, stopped from the system UI rather than
   from the app.
