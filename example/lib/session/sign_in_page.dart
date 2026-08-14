import 'package:flutter/material.dart';

import '../contacts/demo_contacts.dart';
import 'app_session.dart';

/// Asks who you are.
///
/// A call needs two identities, and a demo that assumes one can never be run
/// on two devices. Pick a different person on each.
class SignInPage extends StatefulWidget {
  const SignInPage({required this.session, super.key});

  final AppSession session;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late final TextEditingController _server = TextEditingController(
    text: widget.session.serverUrl,
  );
  String? _identity;

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 32),
              Text('call_kit',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Pick who you are on this device. Run the app on a second device '
                'as somebody else and call between them.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              RadioGroup<String>(
                groupValue: _identity,
                onChanged: (value) => setState(() => _identity = value),
                child: Column(
                  children: [
                    for (final contact in demoContacts)
                      RadioListTile<String>(
                        value: contact.id,
                        title: Text(contact.name),
                        subtitle: Text(contact.title),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _server,
                decoration: const InputDecoration(
                  labelText: 'LiveKit server (optional)',
                  hintText: 'ws://192.168.1.10:7880',
                  border: OutlineInputBorder(),
                  helperText: 'Leave empty to use --dart-define=LIVEKIT_URL',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _identity == null
                    ? null
                    : () => widget.session.signIn(
                          _identity!,
                          serverUrl: _server.text.trim(),
                        ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      );
}
