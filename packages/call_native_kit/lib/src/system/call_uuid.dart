import 'package:uuid/uuid.dart';

const _uuid = Uuid();

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Converts any call id into the UUID iOS CallKit requires.
///
/// Deterministic — the same id always maps to the same UUID, on every
/// platform and in every isolate. That matters because the same call is
/// identified independently by Dart, by Swift (which must compute the UUID
/// from a PushKit payload before Dart exists) and by Kotlin.
///
/// The algorithm is part of the public contract, not an implementation
/// detail:
///
/// 1. an input that already is a UUID passes through unchanged;
/// 2. otherwise, UUID v5 over the URL namespace
///    (`6ba7b811-9dad-11d1-80b4-00c04fd430c8`), lowercased.
///
/// `CallUuid.swift` mirrors it, and `test/call_uuid_test.dart` shares its
/// golden vectors with `example/ios/RunnerTests/RunnerTests.swift` so the two cannot
/// drift apart silently.
String systemCallUuid(String callId) {
  if (_uuidPattern.hasMatch(callId)) return callId;
  return _uuid.v5(Namespace.url.value, callId);
}
