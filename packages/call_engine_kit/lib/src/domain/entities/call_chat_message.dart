import 'package:equatable/equatable.dart';

/// A message in the in-call chat.
///
/// Ephemeral by design: it lives on the media connection and is gone when the
/// call ends. Persisting it would mean a second chat system alongside whatever
/// the host app already has.
class CallChatMessage extends Equatable {
  const CallChatMessage({
    required this.id,
    required this.senderIdentity,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isLocal,
  });

  final String id;
  final String senderIdentity;
  final String senderName;
  final String text;
  final DateTime timestamp;

  /// Whether the local user sent it.
  final bool isLocal;

  @override
  List<Object?> get props => [
        id,
        senderIdentity,
        senderName,
        text,
        timestamp,
        isLocal,
      ];
}
