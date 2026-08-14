/// Field names in your server's call push payload.
///
/// The four that decide whether a push is a call at all — [type], [callId],
/// [incomingTypes] and [cancelledTypes] — are required, deliberately. Getting
/// them wrong fails silently: the payload is not recognised as a call, the
/// phone never rings, and nothing says why. Naming them makes you look at your
/// own payload once instead of debugging that later.
///
/// The rest have defaults, because a wrong caller name is visible and a wrong
/// call id is not.
///
/// If your payload is not flat — nested, or a JSON string inside a `metadata`
/// field — implement [CallPushMapper] instead; this class only renames keys.
///
/// Native code reads the same names from `Info.plist` / `<meta-data>`, so
/// there is exactly one declared source of truth per app.
class CallPushFieldNames {
  const CallPushFieldNames({
    required this.type,
    required this.callId,
    required this.incomingTypes,
    required this.cancelledTypes,
    this.callType = 'call_type',
    this.callerName = 'caller_name',
    this.callerId = 'caller_id',
    this.isGroup = 'is_group',
    this.avatarUrl = 'caller_avatar',
    this.reason = 'reason',
    this.createdAt = 'created_at',
    this.timeoutAt = 'timeout_at',
    this.roomName = 'livekit_room',
    this.roomNameTemplate = 'call_{callId}',
    this.videoValue = 'video',
  });

  /// The snake-cased shape this plugin was extracted from:
  ///
  /// ```json
  /// {"type": "incoming_call", "call_id": "314", "call_type": "video",
  ///  "caller_name": "Aibek", "is_group": false,
  ///  "livekit_room": "call_314", "timeout_at": "2026-08-12T09:00:40Z"}
  /// ```
  ///
  /// Named rather than default so that choosing it is a decision somebody
  /// made, visible at the call site.
  const CallPushFieldNames.snakeCase()
      : type = 'type',
        callId = 'call_id',
        incomingTypes = const {'incoming_call'},
        cancelledTypes = const {'cancelled_call', 'call_cancelled'},
        callType = 'call_type',
        callerName = 'caller_name',
        callerId = 'caller_id',
        isGroup = 'is_group',
        avatarUrl = 'caller_avatar',
        reason = 'reason',
        createdAt = 'created_at',
        timeoutAt = 'timeout_at',
        roomName = 'livekit_room',
        roomNameTemplate = 'call_{callId}',
        videoValue = 'video';

  final String type;
  final String callId;
  final String callType;
  final String callerName;
  final String callerId;
  final String isGroup;
  final String avatarUrl;
  final String reason;
  final String createdAt;
  final String timeoutAt;

  /// Preferred field carrying the media room name.
  final String roomName;

  /// Fallback used when [roomName] is absent. `{callId}` is substituted.
  ///
  /// Prefer sending [roomName] explicitly — a template is a convention two
  /// systems have to keep agreeing on.
  final String roomNameTemplate;

  /// Value of [callType] that means "video".
  final String videoValue;

  /// Values of [type] that start a call.
  final Set<String> incomingTypes;

  /// Values of [type] that cancel one.
  final Set<String> cancelledTypes;

  /// Room name for [callId], honouring [roomNameTemplate].
  String roomNameFor(String callId) =>
      roomNameTemplate.replaceAll('{callId}', callId);

  Map<String, Object?> toJson() => {
        'type': type,
        'callId': callId,
        'callType': callType,
        'callerName': callerName,
        'callerId': callerId,
        'isGroup': isGroup,
        'avatarUrl': avatarUrl,
        'reason': reason,
        'createdAt': createdAt,
        'timeoutAt': timeoutAt,
        'roomName': roomName,
        'roomNameTemplate': roomNameTemplate,
        'videoValue': videoValue,
        'incomingTypes': incomingTypes.toList(),
        'cancelledTypes': cancelledTypes.toList(),
      };

  factory CallPushFieldNames.fromJson(Map<String, Object?> json) {
    // Per-field fallback for anything the persisted config did not carry.
    const fallback = CallPushFieldNames.snakeCase();
    String read(String key, String or) => json[key] as String? ?? or;
    Set<String> readSet(String key, Set<String> or) {
      final raw = json[key];
      if (raw is! List) return or;
      return raw.whereType<String>().toSet();
    }

    return CallPushFieldNames(
      type: read('type', fallback.type),
      callId: read('callId', fallback.callId),
      callType: read('callType', fallback.callType),
      callerName: read('callerName', fallback.callerName),
      callerId: read('callerId', fallback.callerId),
      isGroup: read('isGroup', fallback.isGroup),
      avatarUrl: read('avatarUrl', fallback.avatarUrl),
      reason: read('reason', fallback.reason),
      createdAt: read('createdAt', fallback.createdAt),
      timeoutAt: read('timeoutAt', fallback.timeoutAt),
      roomName: read('roomName', fallback.roomName),
      roomNameTemplate: read('roomNameTemplate', fallback.roomNameTemplate),
      videoValue: read('videoValue', fallback.videoValue),
      incomingTypes: readSet('incomingTypes', fallback.incomingTypes),
      cancelledTypes: readSet('cancelledTypes', fallback.cancelledTypes),
    );
  }
}
