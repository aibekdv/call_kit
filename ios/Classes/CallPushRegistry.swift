import Flutter
import PushKit
import UIKit
import flutter_callkit_incoming

/// PushKit, and the rules for turning a push into a ringing phone.
///
/// On iOS this runs with no Flutter engine involved: iOS wakes the app for a
/// VoIP push, and the call must be reported to CallKit before the delegate
/// returns. Everything the decision needs therefore comes from
/// `NativeConfig` and `CallStore`, both of which were written while the app
/// was last alive.
public final class CallPushRegistry: NSObject, PKPushRegistryDelegate {

    public static let shared = CallPushRegistry()

    private var registry: PKPushRegistry?
    private var shownCallIds = Set<String>()

    /// Set by the plugin so a PushKit token can be delivered to Dart.
    var onPushToken: ((String) -> Void)?

    private override init() { super.init() }

    // MARK: - Setup

    /// Registers for VoIP pushes. Must run early in
    /// `application(_:didFinishLaunchingWithOptions:)` — iOS terminates an app
    /// that receives a VoIP push without a registered PushKit delegate.
    public func setup() {
        guard registry == nil else { return }

        CallStore.resetActiveCallOnLaunch()

        let registry = PKPushRegistry(queue: .main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
        self.registry = registry
    }

    /// The current PushKit token, or nil before iOS has issued one.
    public func currentToken() -> String? {
        registry?.pushToken(for: .voIP)?.hexString
    }

    // MARK: - PKPushRegistryDelegate

    public func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate credentials: PKPushCredentials,
        for type: PKPushType
    ) {
        let token = credentials.token.hexString
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
        onPushToken?(token)
    }

    public func pushRegistry(
        _ registry: PKPushRegistry,
        didInvalidatePushTokenFor type: PKPushType
    ) {
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
        onPushToken?("")
    }

    public func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        guard type == .voIP else {
            completion()
            return
        }

        let userInfo = payload.dictionaryPayload
        let fields = CallPushParser.parse(userInfo)

        if shownCallIds.contains(fields.callId) {
            completion()
            return
        }

        // Every VoIP push must report a call to CallKit before this delegate
        // returns — iOS revokes the PushKit token otherwise, and then no calls
        // arrive at all. So a push we do not want to ring for is still
        // reported, and immediately ended: PushKit stays healthy, the user
        // sees nothing.
        let suppressed = CallPushParser.isStale(userInfo)
            || CallStore.isBurst(callId: fields.callId)
            || CallStore.isInActiveCall

        if suppressed {
            reportAndEndImmediately(fields, completion: completion)
            return
        }

        markShown(fields.callId)

        let uuid = CallUuid.from(fields.callId)
        CallStore.savePendingCall(fields, uuid: uuid)

        SwiftFlutterCallkitIncomingPlugin.sharedInstance?
            .showCallkitIncoming(callKitData(fields, uuid: uuid), fromPushKit: true) {
                completion()
            }
    }

    // MARK: - FCM

    /// Handles a call push that arrived over FCM rather than PushKit.
    ///
    /// Forward it from `application(_:didReceiveRemoteNotification:)` before
    /// Firebase sees it — see `CallNativeKitHost`. Returns whether the push
    /// was a call.
    @discardableResult
    public func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
        switch CallPushParser.kind(of: userInfo) {
        case .incoming:
            let fields = CallPushParser.parse(userInfo)
            guard !fields.callId.isEmpty else { return true }

            // Unlike PushKit, FCM imposes no reporting requirement, so a push
            // we do not want can simply be dropped.
            guard !shownCallIds.contains(fields.callId),
                  !CallStore.isInActiveCall,
                  !CallPushParser.isStale(userInfo),
                  !CallStore.isBurst(callId: fields.callId)
            else { return true }

            markShown(fields.callId)
            let uuid = CallUuid.from(fields.callId)
            CallStore.savePendingCall(fields, uuid: uuid)
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?
                .showCallkitIncoming(callKitData(fields, uuid: uuid), fromPushKit: true)
            return true

        case .cancelled:
            let fields = CallPushParser.parse(userInfo)
            guard !fields.callId.isEmpty else { return true }
            let data = flutter_callkit_incoming.Data(
                id: CallUuid.from(fields.callId),
                nameCaller: "",
                handle: "",
                type: 0
            )
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(data)
            return true

        case .other:
            return false
        }
    }

    // MARK: - Private

    private func reportAndEndImmediately(
        _ fields: CallFields,
        completion: @escaping () -> Void
    ) {
        let stub = flutter_callkit_incoming.Data(
            id: CallUuid.from(fields.callId),
            nameCaller: fields.displayName,
            handle: fields.displayName,
            type: fields.isVideo ? 1 : 0
        )
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?
            .showCallkitIncoming(stub, fromPushKit: true) {
                SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(stub)
                completion()
            }
    }

    private func callKitData(
        _ fields: CallFields,
        uuid: String
    ) -> flutter_callkit_incoming.Data {
        let data = flutter_callkit_incoming.Data(
            id: uuid,
            nameCaller: fields.displayName,
            handle: CallPushParser.handle(isVideo: fields.isVideo),
            type: fields.isVideo ? 1 : 0
        )
        // Must match Dart's CallHandle.fromJson — this is what the app reads
        // after the user accepts.
        data.extra = fields.asHandleDictionary as NSDictionary
        return data
    }

    private func markShown(_ callId: String) {
        shownCallIds.insert(callId)
        if shownCallIds.count > 50 { shownCallIds.removeAll() }
        CallStore.recordCallShown(callId)
    }
}

// Fully qualified: `flutter_callkit_incoming` also exports a type called
// `Data`, so the bare name is ambiguous in this file.
private extension Foundation.Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
