import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:call_ui_kit/call_ui_kit.dart';

/// Wraps [child] in a minimal Material app for widget testing.
Widget _app(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 200, height: 200, child: child),
    ),
  );
}

void main() {
  const theme = CallTheme.whatsApp();
  final strings = CallStrings.englishDefaults;

  group('ParticipantTile', () {
    testWidgets('shows avatar when camera is off', (tester) async {
      const participant = CallParticipant(
        id: 'u1',
        displayName: 'Alice',
        isCameraOff: true,
      );

      await tester.pumpWidget(_app(
        ParticipantTile(
            participant: participant, theme: theme, strings: strings),
      ));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.byType(CallAvatar), findsOneWidget);
    });

    testWidgets('shows video widget when camera is on', (tester) async {
      final participant = CallParticipant(
        id: 'u1',
        displayName: 'Alice',
        videoWidget: Container(key: const Key('video'), color: Colors.blue),
      );

      await tester.pumpWidget(_app(
        ParticipantTile(
            participant: participant, theme: theme, strings: strings),
      ));

      expect(find.byKey(const Key('video')), findsOneWidget);
    });

    testWidgets('shows mute icon when muted', (tester) async {
      const participant = CallParticipant(
        id: 'u1',
        displayName: 'Alice',
        isMuted: true,
      );

      await tester.pumpWidget(_app(
        ParticipantTile(
            participant: participant, theme: theme, strings: strings),
      ));

      expect(find.byIcon(Icons.mic_off), findsOneWidget);
    });

    testWidgets('hides mute icon when not muted', (tester) async {
      const participant = CallParticipant(
        id: 'u1',
        displayName: 'Alice',
      );

      await tester.pumpWidget(_app(
        ParticipantTile(
            participant: participant, theme: theme, strings: strings),
      ));

      expect(find.byIcon(Icons.mic_off), findsNothing);
    });

    testWidgets('shows signal strength when degraded', (tester) async {
      const participant = CallParticipant(
        id: 'u1',
        displayName: 'Alice',
        signalStrength: SignalStrength.poor,
      );

      await tester.pumpWidget(_app(
        ParticipantTile(
            participant: participant, theme: theme, strings: strings),
      ));

      expect(find.byType(SignalStrengthIcon), findsOneWidget);
    });

    testWidgets('hides signal strength when excellent', (tester) async {
      const participant = CallParticipant(
        id: 'u1',
        displayName: 'Alice',
        signalStrength: SignalStrength.excellent,
      );

      await tester.pumpWidget(_app(
        ParticipantTile(
            participant: participant, theme: theme, strings: strings),
      ));

      expect(find.byType(SignalStrengthIcon), findsNothing);
    });

    testWidgets('shows screen share icon when sharing', (tester) async {
      const participant = CallParticipant(
        id: 'u1',
        displayName: 'Alice',
        isScreenSharing: true,
      );

      await tester.pumpWidget(_app(
        ParticipantTile(
            participant: participant, theme: theme, strings: strings),
      ));

      expect(find.byIcon(Icons.screen_share), findsOneWidget);
    });

    testWidgets('calls onTap callback', (tester) async {
      var tapped = false;
      const participant = CallParticipant(
        id: 'u1',
        displayName: 'Alice',
      );

      await tester.pumpWidget(_app(
        ParticipantTile(
          participant: participant,
          theme: theme,
          strings: strings,
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(ParticipantTile));
      expect(tapped, true);
    });

    testWidgets('has semantics label with name and status', (tester) async {
      const participant = CallParticipant(
        id: 'u1',
        displayName: 'Alice',
        isMuted: true,
      );

      await tester.pumpWidget(_app(
        ParticipantTile(
            participant: participant, theme: theme, strings: strings),
      ));

      final semantics = tester.getSemantics(find.byType(ParticipantTile));
      expect(semantics.label, contains('Alice'));
      expect(semantics.label, contains('Muted'));
    });

    testWidgets('speaking border animates when isSpeaking', (tester) async {
      const participant = CallParticipant(
        id: 'u1',
        displayName: 'Alice',
        isSpeaking: true,
        videoWidget: SizedBox.expand(),
      );

      await tester.pumpWidget(_app(
        ParticipantTile(
            participant: participant, theme: theme, strings: strings),
      ));

      // CustomPaint for speaking border should be present
      expect(find.byType(CustomPaint), findsWidgets);

      // Advance animation frames
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('video sits on an opaque surface', (tester) async {
      const participant = CallParticipant(
        id: 'u1',
        displayName: 'Alice',
        // A renderer that paints nothing, as happens while a texture is being
        // (re)attached after a reconnect.
        videoWidget: SizedBox.expand(),
      );

      await tester.pumpWidget(_app(
        ParticipantTile(
          participant: participant,
          theme: theme,
          strings: strings,
        ),
      ));

      final backing = tester.widgetList<ColoredBox>(find.descendant(
        of: find.byType(VideoSurface),
        matching: find.byType(ColoredBox),
      ));
      expect(backing.any((b) => b.color == Colors.black), isTrue);
    });
  });
}
