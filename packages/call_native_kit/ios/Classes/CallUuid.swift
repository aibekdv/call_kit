import CryptoKit
import Foundation

/// The Swift half of the call-id-to-UUID mapping.
///
/// **Must agree with Dart's `systemCallUuid`, byte for byte.** The duplication
/// is unavoidable: a PushKit call has to be reported to CallKit before any
/// Dart isolate exists, so this side computes the UUID on its own. If the two
/// ever disagree, the app holds a different identifier than the system does
/// and can no longer end the call it is in.
///
/// `CallUuidTests.swift` shares its golden vectors with
/// `test/call_uuid_test.dart` for exactly that reason.
enum CallUuid {

    /// UUID v5 over the URL namespace, lowercased. An input that already is a
    /// UUID passes through unchanged.
    static func from(_ callId: String) -> String {
        if UUID(uuidString: callId) != nil { return callId }

        let namespace = UUID(uuidString: "6ba7b811-9dad-11d1-80b4-00c04fd430c8")!
        var data = withUnsafeBytes(of: namespace.uuid) { Array($0) }
        data.append(contentsOf: Array(callId.utf8))

        let hash = Array(Insecure.SHA1.hash(data: data))
        var bytes = Array(hash.prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50  // version 5
        bytes[8] = (bytes[8] & 0x3F) | 0x80  // variant RFC 4122

        let uuid = UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3],
                               bytes[4], bytes[5], bytes[6], bytes[7],
                               bytes[8], bytes[9], bytes[10], bytes[11],
                               bytes[12], bytes[13], bytes[14], bytes[15]))
        return uuid.uuidString.lowercased()
    }
}
