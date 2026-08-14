import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:call_ui_kit/call_ui_kit.dart';

Widget _app(Widget child) {
  return MaterialApp(home: child);
}

void main() {
  const theme = CallTheme.whatsApp();
  final strings = CallStrings.englishDefaults;

  group('IncomingCallScreen', () {
    testWidgets('shows caller name', (tester) async {
      await tester.pumpWidget(_app(
        IncomingCallScreen(
          callerName: 'Alice',
          theme: theme,
          strings: strings,
          callType: CallType.audio,
          onAccept: () {},
          onDecline: () {},
        ),
      ));

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('shows audio call status for audio type', (tester) async {
      await tester.pumpWidget(_app(
        IncomingCallScreen(
          callerName: 'Alice',
          theme: theme,
          strings: strings,
          callType: CallType.audio,
          onAccept: () {},
          onDecline: () {},
        ),
      ));

      expect(find.text(strings.incomingAudioCall), findsOneWidget);
    });

    testWidgets('shows video call status for video type', (tester) async {
      await tester.pumpWidget(_app(
        IncomingCallScreen(
          callerName: 'Alice',
          theme: theme,
          strings: strings,
          callType: CallType.video,
          onAccept: () {},
          onDecline: () {},
        ),
      ));

      expect(find.text(strings.incomingVideoCall), findsOneWidget);
    });

    testWidgets('calls onAccept when accept tapped', (tester) async {
      var accepted = false;

      await tester.pumpWidget(_app(
        IncomingCallScreen(
          callerName: 'Alice',
          theme: theme,
          strings: strings,
          callType: CallType.audio,
          onAccept: () => accepted = true,
          onDecline: () {},
        ),
      ));

      await tester.tap(find.text(strings.accept));
      expect(accepted, true);
    });

    testWidgets('calls onDecline when decline tapped', (tester) async {
      var declined = false;

      await tester.pumpWidget(_app(
        IncomingCallScreen(
          callerName: 'Alice',
          theme: theme,
          strings: strings,
          callType: CallType.audio,
          onAccept: () {},
          onDecline: () => declined = true,
        ),
      ));

      await tester.tap(find.text(strings.decline));
      expect(declined, true);
    });

    testWidgets('shows avatar', (tester) async {
      await tester.pumpWidget(_app(
        IncomingCallScreen(
          callerName: 'Alice',
          theme: theme,
          strings: strings,
          callType: CallType.audio,
          onAccept: () {},
          onDecline: () {},
        ),
      ));

      expect(find.byType(CallAvatar), findsOneWidget);
    });
  });

  group('OutgoingCallScreen', () {
    testWidgets('shows caller name', (tester) async {
      await tester.pumpWidget(_app(
        OutgoingCallScreen(
          callerName: 'Bob',
          theme: theme,
          strings: strings,
          onEndCall: () {},
        ),
      ));

      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows calling status text', (tester) async {
      await tester.pumpWidget(_app(
        OutgoingCallScreen(
          callerName: 'Bob',
          theme: theme,
          strings: strings,
          onEndCall: () {},
        ),
      ));

      expect(find.text(strings.calling), findsOneWidget);
    });

    testWidgets('shows custom status text when provided', (tester) async {
      await tester.pumpWidget(_app(
        OutgoingCallScreen(
          callerName: 'Bob',
          theme: theme,
          strings: strings,
          callStatusText: 'Ringing...',
          onEndCall: () {},
        ),
      ));

      expect(find.text('Ringing...'), findsOneWidget);
    });

    testWidgets('calls onEndCall when end button tapped', (tester) async {
      var ended = false;

      await tester.pumpWidget(_app(
        OutgoingCallScreen(
          callerName: 'Bob',
          theme: theme,
          strings: strings,
          onEndCall: () => ended = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.call_end));
      expect(ended, true);
    });

    testWidgets('shows mute toggle when callback provided', (tester) async {
      await tester.pumpWidget(_app(
        OutgoingCallScreen(
          callerName: 'Bob',
          theme: theme,
          strings: strings,
          onEndCall: () {},
          onToggleMute: () {},
        ),
      ));

      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('shows speaker toggle when callback provided', (tester) async {
      await tester.pumpWidget(_app(
        OutgoingCallScreen(
          callerName: 'Bob',
          theme: theme,
          strings: strings,
          onEndCall: () {},
          onToggleSpeaker: () {},
        ),
      ));

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });
  });
}
