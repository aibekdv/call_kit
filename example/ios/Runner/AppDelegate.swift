import Flutter
import UIKit
import call_native_kit

/// Subclassing [CallNativeKitAppDelegate] is the entire iOS setup — including
/// the `didActivateAudioSession` forwarding without which a CallKit-accepted
/// call connects and carries no audio.
@main
@objc class AppDelegate: CallNativeKitAppDelegate, FlutterImplicitEngineDelegate {
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
