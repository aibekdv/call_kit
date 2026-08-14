import AVFAudio
import CallKit
import Flutter
import UIKit
import flutter_callkit_incoming

/// A `FlutterAppDelegate` with the call wiring already in place.
///
/// ```swift
/// @main
/// @objc class AppDelegate: CallNativeKitAppDelegate {}
/// ```
///
/// Use it when you have no delegate of your own. If you do — a shared engine,
/// a `SceneDelegate`, other plugins that need `didFinishLaunchingWithOptions`
/// — keep yours and forward to `CallNativeKitHost` instead; the class
/// documentation there has a full example.
///
/// Everything here is `open`, so overriding a single method and calling
/// `super` works too.
open class CallNativeKitAppDelegate: FlutterAppDelegate, CallkitIncomingAppDelegate {

    open override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Before plugin registration: a VoIP push can arrive during launch,
        // and PushKit has to be listening by then.
        CallNativeKitHost.didFinishLaunching()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    open override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Call pushes are intercepted here rather than handed to Firebase, so
        // the system call screen appears instead of a banner.
        if CallNativeKitHost.handleRemoteNotification(userInfo) {
            completionHandler(.newData)
            return
        }
        super.application(
            application,
            didReceiveRemoteNotification: userInfo,
            fetchCompletionHandler: completionHandler
        )
    }

    // MARK: - CallkitIncomingAppDelegate

    open func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
        CallNativeKitHost.didAcceptCall()
    }

    open func onDecline(_ call: Call, _ action: CXEndCallAction) {
        CallNativeKitHost.didEndCall()
    }

    open func onEnd(_ call: Call, _ action: CXEndCallAction) {
        CallNativeKitHost.didEndCall()
    }

    open func onTimeOut(_ call: Call) {
        CallNativeKitHost.didEndCall()
    }

    open func providerDidReset() {
        CallNativeKitHost.didEndCall()
    }

    open func didActivateAudioSession(_ audioSession: AVAudioSession) {
        CallNativeKitHost.didActivateAudioSession(audioSession)
    }

    open func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
        CallNativeKitHost.didDeactivateAudioSession(audioSession)
    }
}
