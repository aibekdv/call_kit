## 0.1.0

Initial, incomplete release. Not usable end to end yet — see the README.

### Added
* `CallSignalingClient` — the single interface between the engine and your backend.
* `RestCallSignalingClient` — a ready-made adapter for the `POST /calls`, `POST /calls/{id}/join` shape, taking a transport function rather than an HTTP client so the package forces neither `dio` nor `http` on you.
* `CallStateMachine` — validated lifecycle transitions. A call may end from anywhere and be revived from nowhere.
* `CallTimerManager` — ringing, connecting, reconnect, answer-guard and heartbeat deadlines, all injected through `CallTimeouts` and driven by `fake_async` in tests.
* `CallSnapshotPublisher` — six separate listenables plus an aggregate `CallSnapshot` stream.
* Value-compared state entities: `CallSessionState`, `CallMediaState`, `CallParticipantsState`, `CallScreenShareState`, `CallViewState`, `CallTimingState`.
* `CallRoomService` and `CallPermissionsDelegate` ports, so the engine can be exercised without a media server or a device.
* `CallEngineStrings` behind a resolver, so a locale change takes effect mid-call.
