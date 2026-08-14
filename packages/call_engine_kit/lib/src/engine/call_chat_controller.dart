import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import '../domain/entities/call_chat_message.dart';
import '../ports/call_logger.dart';

/// In-call chat, carried on the media connection itself.
///
/// Uses LiveKit text streams rather than a separate transport, so it needs no
/// server of its own and works for any call. The trade is that messages exist
/// only while the call does.
class CallChatController {
  CallChatController({
    required String? Function(String identity) nameFor,
    CallLogger logger = const SilentCallLogger(),
  })  : _nameFor = nameFor,
        _logger = logger;

  static const _topic = 'lk.chat';

  final String? Function(String identity) _nameFor;
  final CallLogger _logger;

  final ValueNotifier<List<CallChatMessage>> messages = ValueNotifier(const []);

  Room? _attachedRoom;

  void attach(Room room) {
    if (_attachedRoom == room) return;
    _attachedRoom = room;
    try {
      room.registerTextStreamHandler(_topic, _onReceived);
    } catch (e) {
      // Already registered on this room. Not fatal — sending still works, and
      // the existing handler is ours.
      _logger.log('chat handler already registered: $e');
    }
  }

  void detach(Room room) {
    if (_attachedRoom != room) return;
    room.unregisterTextStreamHandler(_topic);
    _attachedRoom = null;
  }

  Future<void> sendMessage(
    Room room,
    String text, {
    required String localName,
  }) async {
    final local = room.localParticipant;
    if (local == null) {
      _logger.log('chat: no local participant, dropping message');
      return;
    }

    final writer = await local.streamText(
      StreamTextOptions(topic: _topic, totalSize: utf8.encode(text).length),
    );
    await writer.write(text);
    await writer.close();

    _append(
      CallChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}-${local.identity}',
        senderIdentity: local.identity,
        senderName: localName,
        text: text,
        timestamp: DateTime.now(),
        isLocal: true,
      ),
    );
  }

  Future<void> _onReceived(
    TextStreamReader reader,
    String participantIdentity,
  ) async {
    final text = await reader.readAll();
    _append(
      CallChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}-$participantIdentity',
        senderIdentity: participantIdentity,
        senderName: _nameFor(participantIdentity) ?? participantIdentity,
        text: text,
        timestamp: DateTime.now(),
        isLocal: false,
      ),
    );
  }

  void _append(CallChatMessage message) {
    messages.value = [...messages.value, message];
  }

  void reset() => messages.value = const [];

  void dispose() => messages.dispose();
}
