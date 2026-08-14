import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:flutter/material.dart';

import '../session/app_session.dart';
import '../signaling/dev_signaling_client.dart';
import 'demo_contacts.dart';

/// Who you can call.
///
/// The whole integration is the one method below: build a
/// [CallInitiationRequest], hand `startOutgoingCall` something that returns a
/// connection, and the engine does the rest — permissions, the system call
/// entry, the media room, the timeouts.
class ContactsPage extends StatelessWidget {
  const ContactsPage({
    required this.engine,
    required this.session,
    required this.signaling,
    super.key,
  });

  final CallEngine engine;
  final AppSession session;
  final DevSignalingClient signaling;

  Future<void> _call(
    BuildContext context,
    DemoContact contact, {
    required bool isVideo,
  }) async {
    final me = session.identity;
    if (me == null) return;

    // Both sides derive the same room from the pair, so it does not matter
    // who calls first.
    final room = roomForPair(me, contact.id);

    await engine.controller.startOutgoingCall(
      fetchConnection: () => signaling.initiateCall(
        CallInitiationRequest(
          participantIds: [contact.id],
          isVideo: isVideo,
          externalId: room,
          participantNames: {contact.id: contact.name},
        ),
      ),
      roomName: room,
      displayName: contact.name,
      isVideo: isVideo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final others = demoContacts
        .where((contact) => contact.id != session.identity)
        .toList();

    return ListView(
      children: [
        for (final contact in others)
          ListTile(
            leading: CircleAvatar(child: Text(contact.initials)),
            title: Text(contact.name),
            subtitle: Text(contact.title),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.call),
                  tooltip: 'Audio call',
                  onPressed: () => _call(context, contact, isVideo: false),
                ),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  tooltip: 'Video call',
                  onPressed: () => _call(context, contact, isVideo: true),
                ),
              ],
            ),
          ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'With no signalling server, calling somebody really means joining '
            'the room you share with them. Their phone rings only if a server '
            'tells it to — see Diagnostics to exercise that path.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
