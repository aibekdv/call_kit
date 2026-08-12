import XCTest

@testable import call_native_kit

/// The Swift half of the golden vectors in `test/call_uuid_test.dart`.
///
/// **The two tables must stay identical.** Dart and Swift compute call UUIDs
/// independently — Swift has to, because a PushKit call is reported to CallKit
/// long before any Dart isolate exists — so nothing but these tables stops the
/// two implementations from drifting apart. A drift does not crash: it produces
/// a call the app can never end, because it holds a different identifier than
/// the system does.
///
/// There is also a runtime guard: `CallNativeKit.initialize` compares a few
/// vectors across the channel in debug builds, which is what actually catches
/// drift for hosts that never wire up an Xcode test target.
final class CallUuidTests: XCTestCase {

    private let goldenVectors: [(String, String)] = [
        ("1", "b80c8fef-a677-5340-85fb-2c162d75df03"),
        ("42", "5c2b23de-4bad-58ee-a4b3-f22f3b9cfd7d"),
        ("314", "70a24e9e-788b-54e1-bea4-aa4f004f7bbc"),
        ("1001", "dacca10a-9ec0-5e4c-8c61-9f73c4f826bf"),
        ("9007199254740993", "14faa7de-9a99-5d33-a1f5-be26f83ad877"),
        ("abc", "68661508-f3c4-55b4-945d-ae2b4dfe5db4"),
        ("call_314", "ae13d5c5-64a4-59a0-8466-31b43c9c390e"),
        ("user-42@example.com", "f1ce6068-4fbd-5e92-9e18-dd1fe70dfcaa"),
        ("Привет", "b9be3511-b3be-5e1d-b703-42c05088d0fa"),
        ("", "1b4db7eb-4057-5ddf-91e0-36dec72071f5"),
        ("A1B2C3", "6fb17bb6-93e2-5b9b-8429-90305c8a07d9"),
        // Already a UUID — passes through untouched.
        ("6ba7b811-9dad-11d1-80b4-00c04fd430c8", "6ba7b811-9dad-11d1-80b4-00c04fd430c8"),
    ]

    func testMatchesDartGoldenVectors() {
        for (input, expected) in goldenVectors {
            XCTAssertEqual(CallUuid.from(input), expected, "input: \(input)")
        }
    }

    func testIsStable() {
        XCTAssertEqual(CallUuid.from("314"), CallUuid.from("314"))
    }

    func testIsCaseSensitive() {
        XCTAssertNotEqual(CallUuid.from("abc"), CallUuid.from("ABC"))
    }

    func testAcceptsUppercaseUuidUnchanged() {
        let upper = "6BA7B811-9DAD-11D1-80B4-00C04FD430C8"
        XCTAssertEqual(CallUuid.from(upper), upper)
    }
}
