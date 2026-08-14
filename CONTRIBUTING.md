# Contributing

## Setup

```bash
dart pub global activate melos
melos bootstrap
```

One workspace, one lockfile: `melos bootstrap` resolves every package and
example together, so `call_engine_kit` always builds against the
`call_native_kit` in this checkout. There are no path overrides to add before
working and none to strip before publishing.

## Before opening a pull request

```bash
melos run verify   # format check, analyze, test
```

Anything touching native code has to be built as well — the analyzer never sees
Swift or Kotlin:

```bash
cd packages/call_native_kit/example
flutter build apk --debug
flutter build ios --debug --no-codesign
```

## What cannot be tested automatically

A VoIP stack has a large surface that only a real device exercises: PushKit
delivery, the system call screen, picture-in-picture, audio-session handover,
recovery after the app is killed mid-call. `packages/call_native_kit/example`
exists as the manual harness for exactly that, with a push simulator and a live
diagnostics panel. Please run the relevant parts of it and say so in the PR.

Two failure modes deserve particular care because neither shows up as an error:

* **A silent call.** If the host `AppDelegate` stops forwarding
  `didActivateAudioSession`, an iOS call accepted through CallKit connects,
  publishes tracks, reports healthy — and carries no audio. The diagnostics
  panel's activation count is how you see it.
* **UUID drift.** Dart and Swift compute call UUIDs independently, because a
  PushKit call is reported to CallKit before any Dart isolate exists. The golden
  vectors in `test/call_uuid_test.dart` and `example/ios/RunnerTests/RunnerTests.swift` must
  stay identical; a debug-build assertion compares them at runtime too.

## Dependency version ranges

`flutter_callkit_incoming` and `flutter_webrtc` are pinned with upper bounds
that look tighter than usual. That is deliberate: both are reached partly
through reflection — Java `Proxy` on Android, the Objective-C runtime on iOS —
so a compatible-looking upgrade can break at runtime without breaking the build.
Widen a bound only together with a device test.

## Commits and releases

Conventional Commits; Melos derives versions and changelogs from them.

```bash
melos version           # bump, changelog, tag
melos run publish-check # dry run
melos publish
```
