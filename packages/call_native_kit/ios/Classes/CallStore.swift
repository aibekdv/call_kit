import Foundation

/// Everything the iOS side has to remember across process deaths.
///
/// All of it lives under `dev.aibekdv.call_native_kit.*` in `UserDefaults` and
/// is owned by native code alone. That is a deliberate change from the obvious
/// design of sharing keys with Dart's `shared_preferences`: on iOS, call
/// pushes never reach Dart at all — PushKit is native, and the host
/// `AppDelegate` intercepts the FCM variant before Firebase forwards it — so
/// there is nothing to share, and mirroring `shared_preferences`' internal
/// `flutter.` key prefix would be a contract with an implementation detail.
enum CallStore {

    private static let pendingCallKey = "dev.aibekdv.call_native_kit.pendingCall"
    private static let activeCallKey = "dev.aibekdv.call_native_kit.isInActiveCall"
    private static let lastShownIdKey = "dev.aibekdv.call_native_kit.lastShownCallId"
    private static let lastShownAtKey = "dev.aibekdv.call_native_kit.lastShownCallAt"

    // MARK: - Active call

    /// Whether the user is already on a call. Read before ringing.
    static var isInActiveCall: Bool {
        UserDefaults.standard.bool(forKey: activeCallKey)
    }

    static func setInActiveCall(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: activeCallKey)
    }

    /// Clears the active-call flag at launch.
    ///
    /// A crash or a force-quit mid-call leaves the flag set, and a stuck flag
    /// silently suppresses every future incoming call until the user happens
    /// to place one themselves. A fresh process by definition has no call.
    static func resetActiveCallOnLaunch() {
        UserDefaults.standard.set(false, forKey: activeCallKey)
    }

    // MARK: - Pending call

    static func savePendingCall(_ fields: CallFields, uuid: String) {
        var payload = fields.asHandleDictionary
        payload["uuid"] = uuid
        payload["isAccepted"] = false
        payload["savedAt"] = Int(Date().timeIntervalSince1970 * 1000)
        UserDefaults.standard.set(payload, forKey: pendingCallKey)
    }

    static func markPendingCallAccepted() {
        guard var payload = UserDefaults.standard.dictionary(forKey: pendingCallKey)
        else { return }
        payload["isAccepted"] = true
        UserDefaults.standard.set(payload, forKey: pendingCallKey)
    }

    static func pendingCall() -> [String: Any]? {
        guard let payload = UserDefaults.standard.dictionary(forKey: pendingCallKey)
        else { return nil }

        let savedAtMs = (payload["savedAt"] as? NSNumber)?.doubleValue ?? 0
        let age = Date().timeIntervalSince1970 - savedAtMs / 1000
        if age > NativeConfig.current.timeouts.pendingCallTtl {
            clearPendingCall()
            return nil
        }
        return payload
    }

    static func clearPendingCall() {
        UserDefaults.standard.removeObject(forKey: pendingCallKey)
    }

    // MARK: - Burst suppression

    /// Whether another call rang within the suppression window.
    ///
    /// Servers routinely send the same call over both PushKit and FCM, and a
    /// device returning from offline receives a whole queue at once. Without
    /// this the user gets several full-screen call screens stacked up.
    static func isBurst(callId: String, now: Date = Date()) -> Bool {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: lastShownIdKey) != nil,
              let lastAt = defaults.object(forKey: lastShownAtKey) as? NSNumber
        else { return false }

        let elapsed = now.timeIntervalSince1970 - lastAt.doubleValue / 1000
        return elapsed >= 0
            && elapsed < NativeConfig.current.timeouts.burstSuppressionWindow
    }

    static func recordCallShown(_ callId: String, now: Date = Date()) {
        let defaults = UserDefaults.standard
        defaults.set(callId, forKey: lastShownIdKey)
        defaults.set(
            NSNumber(value: Int64(now.timeIntervalSince1970 * 1000)),
            forKey: lastShownAtKey
        )
    }
}
