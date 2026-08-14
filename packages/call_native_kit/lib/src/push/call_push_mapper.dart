import '../config/call_push_field_names.dart';
import '../models/call_push_message.dart';

/// Turns your server's push payload into a [CallPushMessage].
///
/// Implement it when your payload does not fit
/// [CallPushFieldNames] — for instance when the call data is nested, or
/// arrives as a JSON string in a `metadata` field.
abstract interface class CallPushMapper {
  /// Cheap check run on every push, including the ones that are not calls.
  bool isCallPush(Map<String, Object?> data);

  /// Returns `null` when [data] is not a call push or has no usable call id.
  CallPushMessage? parse(
    Map<String, Object?> data, {
    String? fallbackCallerName,
  });
}

/// Reads a flat payload described by [CallPushFieldNames].
class DefaultCallPushMapper implements CallPushMapper {
  const DefaultCallPushMapper({
    this.fields = const CallPushFieldNames(),
    this.incomingCallFallbackName = 'Incoming call',
  });

  final CallPushFieldNames fields;

  /// Caller name used when the payload carries none.
  final String incomingCallFallbackName;

  @override
  bool isCallPush(Map<String, Object?> data) {
    final type = _type(data);
    if (type == null) return false;
    return fields.incomingTypes.contains(type) ||
        fields.cancelledTypes.contains(type);
  }

  @override
  CallPushMessage? parse(
    Map<String, Object?> data, {
    String? fallbackCallerName,
  }) {
    final type = _type(data);
    if (type == null) return null;

    final callId = data[fields.callId]?.toString();
    if (callId == null || callId.isEmpty) return null;

    final roomName = data[fields.roomName]?.toString().trim().nullIfEmpty ??
        fields.roomNameFor(callId);

    if (fields.cancelledTypes.contains(type)) {
      return CallCancelledPush(
        callId: callId,
        raw: data,
        roomName: roomName,
        reason: data[fields.reason]?.toString(),
      );
    }
    if (!fields.incomingTypes.contains(type)) return null;

    return IncomingCallPush(
      callId: callId,
      raw: data,
      callerName: fallbackCallerName ??
          data[fields.callerName]?.toString().trim().nullIfEmpty ??
          incomingCallFallbackName,
      roomName: roomName,
      isVideo: data[fields.callType]?.toString().toLowerCase() ==
          fields.videoValue.toLowerCase(),
      callerId: data[fields.callerId]?.toString(),
      isGroup: _bool(data[fields.isGroup]),
      avatarUrl: data[fields.avatarUrl]?.toString().trim().nullIfEmpty,
      createdAt: _utc(data[fields.createdAt]),
      timeoutAt: _utc(data[fields.timeoutAt]),
    );
  }

  String? _type(Map<String, Object?> data) =>
      data[fields.type]?.toString().toLowerCase();

  /// FCM data payloads are string-typed, so `is_group` arrives as `"true"`
  /// over the wire and as `true` from a native bridge.
  static bool _bool(Object? raw) =>
      raw is bool ? raw : raw?.toString().toLowerCase() == 'true';

  static DateTime? _utc(Object? raw) =>
      DateTime.tryParse(raw?.toString() ?? '')?.toUtc();
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
