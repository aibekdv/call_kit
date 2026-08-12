import Foundation

/// The Dart-side `CallNativeConfig`, as seen from Swift.
///
/// A PushKit call is handled entirely here, with no Dart isolate running, so
/// every string and every timing this side needs has to have been written down
/// while the app was last alive. `CallNativeKit.configure` does that; this
/// reads it back.
///
/// Falls back to English defaults, which is what a device sees between install
/// and the first launch.
struct NativeConfig {

    struct Strings {
        var audioCallHandle = "Audio call"
        var videoCallHandle = "Video call"
        var incomingCallFallbackName = "Incoming call"
    }

    struct Timeouts {
        var pushStaleThreshold: TimeInterval = 60
        var pushClockSkew: TimeInterval = 5
        var burstSuppressionWindow: TimeInterval = 5
        var pendingCallTtl: TimeInterval = 90
    }

    struct PushFields {
        var type = "type"
        var callId = "call_id"
        var callType = "call_type"
        var callerName = "caller_name"
        var callerId = "caller_id"
        var isGroup = "is_group"
        var avatarUrl = "caller_avatar"
        var createdAt = "created_at"
        var timeoutAt = "timeout_at"
        var roomName = "livekit_room"
        var roomNameTemplate = "call_{callId}"
        var videoValue = "video"
        var incomingTypes: Set<String> = ["incoming_call"]
        var cancelledTypes: Set<String> = ["cancelled_call", "call_cancelled"]

        func roomName(forCallId callId: String) -> String {
            roomNameTemplate.replacingOccurrences(of: "{callId}", with: callId)
        }
    }

    var strings = Strings()
    var timeouts = Timeouts()
    var pushFields = PushFields()

    // MARK: - Storage

    private static let configKey = "dev.aibekdv.call_native_kit.config"

    private(set) static var current = NativeConfig.load()

    /// Called from Dart on `configure`.
    static func store(json: String) {
        UserDefaults.standard.set(json, forKey: configKey)
        current = decode(json) ?? NativeConfig()
    }

    private static func load() -> NativeConfig {
        guard let json = UserDefaults.standard.string(forKey: configKey) else {
            return NativeConfig()
        }
        return decode(json) ?? NativeConfig()
    }

    private static func decode(_ json: String) -> NativeConfig? {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        var config = NativeConfig()

        if let s = root["strings"] as? [String: Any] {
            config.strings.audioCallHandle =
                s["audioCallHandle"] as? String ?? config.strings.audioCallHandle
            config.strings.videoCallHandle =
                s["videoCallHandle"] as? String ?? config.strings.videoCallHandle
            config.strings.incomingCallFallbackName =
                s["incomingCallFallbackName"] as? String
                ?? config.strings.incomingCallFallbackName
        }

        if let t = root["timeouts"] as? [String: Any] {
            func seconds(_ key: String, _ fallback: TimeInterval) -> TimeInterval {
                guard let ms = t[key] as? NSNumber else { return fallback }
                return ms.doubleValue / 1000
            }
            config.timeouts.pushStaleThreshold =
                seconds("pushStaleThresholdMs", config.timeouts.pushStaleThreshold)
            config.timeouts.pushClockSkew =
                seconds("pushClockSkewMs", config.timeouts.pushClockSkew)
            config.timeouts.burstSuppressionWindow =
                seconds("burstSuppressionWindowMs", config.timeouts.burstSuppressionWindow)
            config.timeouts.pendingCallTtl =
                seconds("pendingCallTtlMs", config.timeouts.pendingCallTtl)
        }

        if let f = root["pushFields"] as? [String: Any] {
            func str(_ key: String, _ fallback: String) -> String {
                f[key] as? String ?? fallback
            }
            func set(_ key: String, _ fallback: Set<String>) -> Set<String> {
                guard let list = f[key] as? [String] else { return fallback }
                return Set(list)
            }
            config.pushFields.type = str("type", config.pushFields.type)
            config.pushFields.callId = str("callId", config.pushFields.callId)
            config.pushFields.callType = str("callType", config.pushFields.callType)
            config.pushFields.callerName = str("callerName", config.pushFields.callerName)
            config.pushFields.callerId = str("callerId", config.pushFields.callerId)
            config.pushFields.isGroup = str("isGroup", config.pushFields.isGroup)
            config.pushFields.avatarUrl = str("avatarUrl", config.pushFields.avatarUrl)
            config.pushFields.createdAt = str("createdAt", config.pushFields.createdAt)
            config.pushFields.timeoutAt = str("timeoutAt", config.pushFields.timeoutAt)
            config.pushFields.roomName = str("roomName", config.pushFields.roomName)
            config.pushFields.roomNameTemplate =
                str("roomNameTemplate", config.pushFields.roomNameTemplate)
            config.pushFields.videoValue = str("videoValue", config.pushFields.videoValue)
            config.pushFields.incomingTypes =
                set("incomingTypes", config.pushFields.incomingTypes)
            config.pushFields.cancelledTypes =
                set("cancelledTypes", config.pushFields.cancelledTypes)
        }

        return config
    }
}
