/// Somebody to call.
///
/// [id] doubles as the LiveKit identity, so signing in as `alice` and calling
/// `bob` from the other device puts you both in the same room.
class DemoContact {
  const DemoContact({
    required this.id,
    required this.name,
    required this.title,
  });

  final String id;
  final String name;
  final String title;

  String get initials => name.isEmpty ? '?' : name[0].toUpperCase();
}

const demoContacts = <DemoContact>[
  DemoContact(id: 'alice', name: 'Alice', title: 'Design'),
  DemoContact(id: 'bob', name: 'Bob', title: 'Backend'),
  DemoContact(id: 'carol', name: 'Carol', title: 'Support'),
  DemoContact(id: 'dave', name: 'Dave', title: 'QA'),
];

/// The room two people share, whoever calls first.
///
/// Sorted so both sides compute the same name — without that, Alice calling
/// Bob and Bob calling Alice end up in two different rooms, each alone.
String roomForPair(String a, String b) {
  final pair = [a, b]..sort();
  return 'demo-${pair.join('-')}';
}
