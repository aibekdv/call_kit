import Foundation

/// A call push, as Swift understands it.
///
/// Mirrors Dart's `IncomingCallPush`, and its `asHandleDictionary` produces
/// exactly what `CallHandle.fromJson` expects — that dictionary is what
/// travels as the CallKit `extra` and is what Dart reads after the user
/// accepts.
struct CallFields {
    let callId: String
    let roomName: String
    let displayName: String
    let isVideo: Bool
    let isGroup: Bool
    let avatarUrl: String?
    let raw: [String: Any]

    var asHandleDictionary: [String: Any] {
        var payload: [String: Any] = [
            "callId": callId,
            "roomName": roomName,
            "displayName": displayName,
            "isVideo": isVideo,
            "isGroup": isGroup,
        ]
        if let avatarUrl { payload["avatarUrl"] = avatarUrl }
        if !raw.isEmpty { payload["extra"] = raw }
        return payload
    }
}

/// Reads a push payload using the field names the host declared.
enum CallPushParser {

    static func kind(of userInfo: [AnyHashable: Any]) -> PushKind {
        let fields = NativeConfig.current.pushFields
        let type = (userInfo[fields.type] as? String)?.lowercased() ?? ""
        if fields.incomingTypes.contains(type) { return .incoming }
        if fields.cancelledTypes.contains(type) { return .cancelled }
        return .other
    }

    enum PushKind {
        case incoming
        case cancelled
        case other
    }

    static func parse(_ userInfo: [AnyHashable: Any]) -> CallFields {
        let config = NativeConfig.current
        let fields = config.pushFields

        let callId = string(userInfo[fields.callId]) ?? ""
        let explicitRoom = string(userInfo[fields.roomName])?
            .trimmingCharacters(in: .whitespaces)

        return CallFields(
            callId: callId,
            roomName: (explicitRoom?.isEmpty == false)
                ? explicitRoom!
                : fields.roomName(forCallId: callId),
            displayName: string(userInfo[fields.callerName])
                ?? config.strings.incomingCallFallbackName,
            isVideo: string(userInfo[fields.callType])?.lowercased()
                == fields.videoValue.lowercased(),
            isGroup: bool(userInfo[fields.isGroup]),
            avatarUrl: string(userInfo[fields.avatarUrl]),
            raw: userInfo.reduce(into: [String: Any]()) { result, entry in
                result["\(entry.key)"] = entry.value
            }
        )
    }

    /// The CallKit handle line: what the system shows under the caller name.
    static func handle(isVideo: Bool) -> String {
        let strings = NativeConfig.current.strings
        return isVideo ? strings.videoCallHandle : strings.audioCallHandle
    }

    // MARK: - Staleness

    /// Whether the call this push announces has already stopped ringing.
    ///
    /// Server timestamps win; the delivery timestamp is a fallback for servers
    /// that send none. With neither, the push is treated as fresh — dropping
    /// every call is worse than ringing for one that has ended.
    static func isStale(_ userInfo: [AnyHashable: Any], now: Date = Date()) -> Bool {
        let config = NativeConfig.current
        let fields = config.pushFields

        if let deadline = date(userInfo[fields.timeoutAt]) {
            return now > deadline.addingTimeInterval(config.timeouts.pushClockSkew)
        }
        if let created = date(userInfo[fields.createdAt]) {
            return now.timeIntervalSince(created) > config.timeouts.pushStaleThreshold
        }
        if let sent = deliveryTime(userInfo) {
            return now.timeIntervalSince(sent) > config.timeouts.pushStaleThreshold
        }
        return false
    }

    /// When the transport says the push was sent. `sent_at` is a server
    /// convention; `google.c.a.ts` is what FCM adds on its way through.
    private static func deliveryTime(_ userInfo: [AnyHashable: Any]) -> Date? {
        for key in ["sent_at", "google.c.a.ts"] {
            if let raw = userInfo[key], let date = epoch(raw) { return date }
        }
        return nil
    }

    private static func epoch(_ raw: Any) -> Date? {
        let value: Double
        switch raw {
        case let double as Double: value = double
        case let int as Int: value = Double(int)
        case let text as String:
            guard let parsed = Double(text) else { return nil }
            value = parsed
        default: return nil
        }
        // Anything past 10^12 is milliseconds; seconds would be year 33658.
        return value >= 1_000_000_000_000
            ? Date(timeIntervalSince1970: value / 1000)
            : Date(timeIntervalSince1970: value)
    }

    private static let iso8601WithFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func date(_ raw: Any?) -> Date? {
        guard let text = raw as? String, !text.isEmpty else { return nil }
        return iso8601WithFraction.date(from: text) ?? iso8601.date(from: text)
    }

    private static func string(_ raw: Any?) -> String? {
        guard let raw else { return nil }
        let text = "\(raw)"
        return text.isEmpty ? nil : text
    }

    private static func bool(_ raw: Any?) -> Bool {
        if let value = raw as? Bool { return value }
        return "\(raw ?? "")".lowercased() == "true"
    }
}
