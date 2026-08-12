import Flutter
import UIKit
import call_native_kit

/// Subclassing [CallNativeKitAppDelegate] is the entire iOS setup when the app
/// has no delegate work of its own. See `CallNativeKitHost` for the version
/// that keeps your own delegate.
@main
@objc class AppDelegate: CallNativeKitAppDelegate, FlutterImplicitEngineDelegate {
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
