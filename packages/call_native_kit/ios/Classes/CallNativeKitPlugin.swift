import Flutter
import UIKit

/// iOS half of `call_native_kit`.
///
/// Two channels, matching Dart's `CallNativeChannels`: the main one, and a
/// separate one for picture-in-picture so each side owns a single handler.
public class CallNativeKitPlugin: NSObject, FlutterPlugin {

    private var channel: FlutterMethodChannel?
    private var pipChannel: FlutterMethodChannel?

    /// Typed as `Any` so the iOS 15 availability gate stays at the one place
    /// it is created — a stored property of the real type would raise the
    /// whole plugin's deployment target.
    private var pip: Any?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "dev.aibekdv.call_native_kit",
            binaryMessenger: registrar.messenger()
        )
        let pipChannel = FlutterMethodChannel(
            name: "dev.aibekdv.call_native_kit/pip",
            binaryMessenger: registrar.messenger()
        )

        let instance = CallNativeKitPlugin()
        instance.channel = channel
        instance.pipChannel = pipChannel

        if #available(iOS 15.0, *) {
            instance.pip = CallPipController(channel: pipChannel)
        }

        CallPushRegistry.shared.onPushToken = { [weak channel] token in
            channel?.invokeMethod("onVoipPushToken", arguments: token)
        }

        registrar.addMethodCallDelegate(instance, channel: channel)
        pipChannel.setMethodCallHandler { [weak instance] call, result in
            instance?.handlePip(call, result: result)
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {
        case "configure":
            if let json = args["config"] as? String { NativeConfig.store(json: json) }
            result(nil)

        case "initialize":
            CallPushRegistry.shared.setup()
            CallAudioSession.configureManualMode()
            result(nil)

        // iOS persists the pending call from the push handler itself, which
        // runs before any Dart isolate exists. Dart calling this is harmless.
        case "savePendingCall":
            result(nil)

        case "getPendingAcceptedCall":
            let pending = CallStore.pendingCall()
            result(pending?["isAccepted"] as? Bool == true ? pending : nil)

        case "markPendingCallAccepted":
            CallStore.markPendingCallAccepted()
            result(nil)

        case "clearPendingCall":
            CallStore.clearPendingCall()
            result(nil)

        case "setActiveCall":
            CallStore.setInActiveCall(args["active"] as? Bool ?? false)
            result(nil)

        case "getVoipPushToken":
            result(CallPushRegistry.shared.currentToken())

        case "activateAudio":
            CallAudioSession.activateForCall(
                defaultToSpeaker: args["defaultToSpeaker"] as? Bool ?? true
            )
            result(nil)

        case "deactivateAudio":
            CallAudioSession.deactivateForCall()
            result(nil)

        case "awaitAudioSessionActive":
            CallAudioSession.awaitActive(timeoutMs: args["timeoutMs"] as? Int ?? 500) {
                result($0)
            }

        case "audioDiagnostics":
            result(CallAudioSession.diagnostics())

        // Android-only: iOS CallKit transitions an incoming call to ongoing
        // through setCallConnected, with no simulation needed.
        case "simulateSystemAccept":
            result("notAndroid")

        // Drift guard — see CallUuid. Dart sends ids, this returns what Swift
        // computes for them, and Dart asserts the two agree.
        case "computeCallUuids":
            let ids = args["callIds"] as? [String] ?? []
            result(ids.map { CallUuid.from($0) })

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handlePip(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 15.0, *), let pip = pip as? CallPipController else {
            // Below iOS 15 there is no AVPictureInPictureVideoCallViewController.
            // Report "not in picture-in-picture" rather than failing, so the
            // Dart side simply never offers it.
            result(call.method == "enterPip" || call.method == "isInPip" ? false : nil)
            return
        }

        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "setActiveVideoCall":
            pip.setActiveVideoCall(
                active: args["active"] as? Bool ?? false,
                aspectWidth: args["aspectWidth"] as? Int ?? 9,
                aspectHeight: args["aspectHeight"] as? Int ?? 16
            )
            result(nil)

        case "enterPip":
            result(pip.enterPip())

        case "closePip":
            pip.closePip()
            result(nil)

        case "attachTrack":
            pip.attachTrack(id: args["trackId"] as? String ?? "")
            result(nil)

        // Android needs a pull model because it renders the Flutter tree in
        // the window; iOS renders its own surface and always knows.
        case "isInPip":
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
