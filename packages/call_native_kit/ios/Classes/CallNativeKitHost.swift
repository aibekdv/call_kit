import AVFAudio
import Flutter
import UIKit
import flutter_callkit_incoming

/// The iOS host wiring `call_native_kit` cannot do for you.
///
/// Two things have to happen in the app's own `AppDelegate`, and neither can
/// be intercepted from a plugin:
///
/// 1. `flutter_callkit_incoming` dispatches audio-session and call callbacks
///    by casting `UIApplication.shared.delegate` to `CallkitIncomingAppDelegate`.
///    If your delegate does not conform, `didActivateAudioSession` never
///    arrives — and a call accepted through CallKit connects with **no audio**
///    while every other signal looks healthy.
/// 2. PushKit must be registered during launch. iOS terminates an app that
///    receives a VoIP push without a registered delegate.
///
/// If you have no `AppDelegate` of your own, subclass
/// `CallNativeKitAppDelegate` and you are done. If you do — a shared engine, a
/// `SceneDelegate`, other plugins — conform to `CallkitIncomingAppDelegate`
/// yourself and forward to the four functions here.
///
/// ```swift
/// @main
/// class AppDelegate: FlutterAppDelegate, CallkitIncomingAppDelegate {
///   override func application(
///     _ application: UIApplication,
///     didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?
///   ) -> Bool {
///     CallNativeKitHost.didFinishLaunching()
///     GeneratedPluginRegistrant.register(with: self)
///     return super.application(application, didFinishLaunchingWithOptions: options)
///   }
///
///   override func application(
///     _ application: UIApplication,
///     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
///     fetchCompletionHandler completion: @escaping (UIBackgroundFetchResult) -> Void
///   ) {
///     if CallNativeKitHost.handleRemoteNotification(userInfo) {
///       completion(.newData)
///       return
///     }
///     super.application(application, didReceiveRemoteNotification: userInfo,
///                       fetchCompletionHandler: completion)
///   }
///
///   func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
///     CallNativeKitHost.didAcceptCall()
///   }
///   func onDecline(_ call: Call, _ action: CXEndCallAction) { CallNativeKitHost.didEndCall() }
///   func onEnd(_ call: Call, _ action: CXEndCallAction) { CallNativeKitHost.didEndCall() }
///   func onTimeOut(_ call: Call) { CallNativeKitHost.didEndCall() }
///   func providerDidReset() { CallNativeKitHost.didEndCall() }
///   func didActivateAudioSession(_ session: AVAudioSession) {
///     CallNativeKitHost.didActivateAudioSession(session)
///   }
///   func didDeactivateAudioSession(_ session: AVAudioSession) {
///     CallNativeKitHost.didDeactivateAudioSession(session)
///   }
/// }
/// ```
public enum CallNativeKitHost {

    /// Registers PushKit and puts WebRTC's audio session into manual mode.
    ///
    /// Call it first thing in `didFinishLaunchingWithOptions`, before plugin
    /// registration: a VoIP push can arrive during launch.
    public static func didFinishLaunching() {
        CallPushRegistry.shared.setup()
        CallAudioSession.configureManualMode()
    }

    /// Handles a call push delivered over FCM instead of PushKit.
    ///
    /// Returns `true` when the push was a call and has been dealt with — pass
    /// anything else on to Firebase.
    @discardableResult
    public static func handleRemoteNotification(
        _ userInfo: [AnyHashable: Any]
    ) -> Bool {
        CallPushRegistry.shared.handleRemoteNotification(userInfo)
    }

    /// Forward from `CallkitIncomingAppDelegate.onAccept`.
    ///
    /// This is what lets a call accepted on the lock screen survive to the
    /// cold start that follows.
    public static func didAcceptCall() {
        CallStore.markPendingCallAccepted()
    }

    /// Forward from `onDecline`, `onEnd` and `onTimeOut`.
    public static func didEndCall() {
        CallStore.clearPendingCall()
    }

    /// Forward from `CallkitIncomingAppDelegate.didActivateAudioSession`.
    ///
    /// Load-bearing: without it a CallKit-accepted call has no audio. See
    /// `CallAudioSession`.
    public static func didActivateAudioSession(_ session: AVAudioSession) {
        CallAudioSession.didActivate(session)
    }

    /// Forward from `CallkitIncomingAppDelegate.didDeactivateAudioSession`.
    public static func didDeactivateAudioSession(_ session: AVAudioSession) {
        CallAudioSession.didDeactivate(session)
    }
}
