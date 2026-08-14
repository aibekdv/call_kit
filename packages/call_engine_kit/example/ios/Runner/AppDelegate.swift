import Flutter
import UIKit
import call_native_kit

/// Subclassing [CallNativeKitAppDelegate] is the entire iOS setup when the app
/// has no delegate work of its own — including the `didActivateAudioSession`
/// forwarding that a CallKit-accepted call needs to have audio at all.
@main
@objc class AppDelegate: CallNativeKitAppDelegate, FlutterImplicitEngineDelegate {
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
