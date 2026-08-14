## 0.1.0

Initial release.

### Added
* `CallNativeKit` — a single facade over the system call UI, PushKit, picture-in-picture and the WebRTC audio session.
* `CallUiPlatform` — show, start, connect, transition and end system calls; `actions` stream replaces subscribing to `flutter_callkit_incoming` directly.
* `PipController` — Android system picture-in-picture and true native iOS PiP that renders a WebRTC video track through `AVSampleBufferDisplayLayer`.
* `CallAudioSession` — manual-mode `RTCAudioSession` control with `awaitActive()` so a CallKit-accepted call does not double-activate `AVAudioSession`, plus `diagnostics()`.
* `CallNativeConfig` — strings, branding, timeouts, storage keys and push field names are all injected; nothing is hardcoded and nothing depends on a localization package.
* `handleBackgroundCallPush` — FCM background-isolate entry point that rehydrates the persisted config.
* `CallNativeKitAppDelegate` / `CallNativeKitHost` (iOS) and `CallNativeKitActivity` (Android) to shrink host setup.
