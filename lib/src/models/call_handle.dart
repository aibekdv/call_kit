/// A call as the operating system knows it.
///
/// Travels as the CallKit `extra` payload, so it must stay JSON-serializable
/// and small: it is what comes back when the user accepts a call on the lock
/// screen and the app then cold-starts.
class CallHandle {
  const CallHandle({
    required this.callId,
    required this.roomName,
    required this.displayName,
    required this.isVideo,
    this.isGroup = false,
    this.avatarUrl,
    this.extra = const {},
  });

  /// Your server's call id. A `String` throughout — the system UI, the push
  /// payload and CallKit all speak strings.
  final String callId;

  /// Name of the media room to join once the call is accepted.
  final String roomName;

  /// Caller or callee name shown by the system.
  final String displayName;

  final bool isVideo;
  final bool isGroup;
  final String? avatarUrl;

  /// Untouched extra fields from the push payload, carried through so the app
  /// can read whatever the plugin does not model.
  final Map<String, Object?> extra;

  CallHandle copyWith({
    String? callId,
    String? roomName,
    String? displayName,
    bool? isVideo,
    bool? isGroup,
    String? avatarUrl,
    Map<String, Object?>? extra,
  }) =>
      CallHandle(
        callId: callId ?? this.callId,
        roomName: roomName ?? this.roomName,
        displayName: displayName ?? this.displayName,
        isVideo: isVideo ?? this.isVideo,
        isGroup: isGroup ?? this.isGroup,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        extra: extra ?? this.extra,
      );

  Map<String, Object?> toJson() => {
        'callId': callId,
        'roomName': roomName,
        'displayName': displayName,
        'isVideo': isVideo,
        'isGroup': isGroup,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (extra.isNotEmpty) 'extra': extra,
      };

  static CallHandle? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final callId = json['callId'];
    if (callId is! String || callId.isEmpty) return null;
    final rawExtra = json['extra'];
    return CallHandle(
      callId: callId,
      roomName: json['roomName'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      isVideo: json['isVideo'] as bool? ?? false,
      isGroup: json['isGroup'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String?,
      extra: rawExtra is Map ? rawExtra.cast<String, Object?>() : const {},
    );
  }

  /// Parses the CallKit `extra` field.
  ///
  /// iOS hands it over as `Map<String, dynamic>` and Android as
  /// `Map<Object?, Object?>`, so both shapes are normalized here rather than
  /// at every call site.
  static CallHandle? fromSystemExtra(Object? extra) {
    if (extra is Map<String, Object?>) return fromJson(extra);
    if (extra is Map) {
      return fromJson(
        extra.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return null;
  }

  @override
  String toString() => 'CallHandle(callId: $callId, roomName: $roomName, '
      'displayName: $displayName, isVideo: $isVideo, isGroup: $isGroup)';
}
