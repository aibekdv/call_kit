import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:call_ui_kit/call_ui_kit.dart';
import 'package:call_ui_kit/src/screens/layers/call_bottom_bar.dart';
import 'package:call_ui_kit/src/screens/layers/call_top_bar.dart';

Widget _app(Widget child) {
  return MaterialApp(home: child);
}

void main() {
  const theme = CallTheme.whatsApp();
  const localParticipant = CallParticipant(
    id: 'local',
    displayName: 'Me',
    isLocalUser: true,
  );

  group('CallScreen', () {
    testWidgets('renders caller name in top bar', (tester) async {
      await tester.pumpWidget(_app(
        CallScreen(
          callerName: 'Bob',
          localParticipant: localParticipant,
          theme: theme,
          onEndCall: () {},
          onToggleMute: () {},
          onToggleSpeaker: () {},
        ),
      ));

      expect(find.text('Bob'), findsWidgets);
    });

    testWidgets('renders bottom bar with controls', (tester) async {
      await tester.pumpWidget(_app(
        CallScreen(
          callerName: 'Bob',
          localParticipant: localParticipant,
          theme: theme,
          onEndCall: () {},
          onToggleMute: () {},
          onToggleSpeaker: () {},
        ),
      ));

      expect(find.byType(CallBottomBar), findsOneWidget);
      expect(find.byIcon(Icons.call_end), findsOneWidget);
    });

    testWidgets('calls onEndCall when end button tapped', (tester) async {
      var called = false;

      await tester.pumpWidget(_app(
        CallScreen(
          callerName: 'Bob',
          localParticipant: localParticipant,
          theme: theme,
          onEndCall: () => called = true,
          onToggleMute: () {},
          onToggleSpeaker: () {},
        ),
      ));

      await tester.tap(find.byIcon(Icons.call_end));
      expect(called, true);
    });

    testWidgets('controls auto-hide after 4 seconds', (tester) async {
      await tester.pumpWidget(_app(
        CallScreen(
          callerName: 'Bob',
          localParticipant: localParticipant,
          theme: theme,
          onEndCall: () {},
          onToggleMute: () {},
          onToggleSpeaker: () {},
        ),
      ));

      // Controls should be visible initially
      final topBarBefore = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byType(CallTopBar),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(topBarBefore.opacity, 1.0);

      // Advance past auto-hide delay (4 seconds)
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 300)); // animation

      final topBarAfter = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byType(CallTopBar),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(topBarAfter.opacity, 0.0);
    });

    testWidgets('tap toggles controls visibility', (tester) async {
      await tester.pumpWidget(_app(
        CallScreen(
          callerName: 'Bob',
          localParticipant: localParticipant,
          theme: theme,
          onEndCall: () {},
          onToggleMute: () {},
          onToggleSpeaker: () {},
        ),
      ));

      // Wait for auto-hide
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 300));

      // Tap to show controls
      await tester.tapAt(const Offset(200, 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final topBar = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byType(CallTopBar),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(topBar.opacity, 1.0);
    });

    testWidgets('shows call status text when provided', (tester) async {
      await tester.pumpWidget(_app(
        CallScreen(
          callerName: 'Bob',
          localParticipant: localParticipant,
          theme: theme,
          callStatusText: '04:23',
          onEndCall: () {},
          onToggleMute: () {},
          onToggleSpeaker: () {},
        ),
      ));

      expect(find.text('04:23'), findsOneWidget);
    });

    testWidgets('shows camera toggle when onToggleCamera provided',
        (tester) async {
      await tester.pumpWidget(_app(
        CallScreen(
          callerName: 'Bob',
          localParticipant: localParticipant,
          theme: theme,
          onEndCall: () {},
          onToggleMute: () {},
          onToggleSpeaker: () {},
          onToggleCamera: () {},
        ),
      ));

      expect(find.byIcon(Icons.videocam), findsOneWidget);
    });

    testWidgets('shows PiP view for personal video call', (tester) async {
      await tester.pumpWidget(_app(
        CallScreen(
          callerName: 'Bob',
          localParticipant: localParticipant,
          theme: theme,
          callType: CallType.video,
          localVideoWidget: Container(
            key: const Key('local-video'),
            color: Colors.green,
          ),
          onEndCall: () {},
          onToggleMute: () {},
          onToggleSpeaker: () {},
        ),
      ));

      expect(find.byType(FloatingPipView), findsOneWidget);
    });

    testWidgets('hides PiP view for audio call', (tester) async {
      await tester.pumpWidget(_app(
        CallScreen(
          callerName: 'Bob',
          localParticipant: localParticipant,
          theme: theme,
          callType: CallType.audio,
          onEndCall: () {},
          onToggleMute: () {},
          onToggleSpeaker: () {},
        ),
      ));

      expect(find.byType(FloatingPipView), findsNothing);
    });

    testWidgets('shows avatar when no remote video in personal call',
        (tester) async {
      await tester.pumpWidget(_app(
        CallScreen(
          callerName: 'Bob',
          callerAvatarUrl: null,
          localParticipant: localParticipant,
          theme: theme,
          callType: CallType.video,
          isCameraOff: true,
          onEndCall: () {},
          onToggleMute: () {},
          onToggleSpeaker: () {},
        ),
      ));

      expect(find.byType(CallAvatar), findsWidgets);
    });

    testWidgets('group call renders participant tiles', (tester) async {
      const participants = [
        CallParticipant(id: 'p1', displayName: 'Alice'),
        CallParticipant(id: 'p2', displayName: 'Charlie'),
        CallParticipant(id: 'p3', displayName: 'Diana'),
      ];

      await tester.pumpWidget(_app(
        CallScreen(
          callerName: 'Group',
          localParticipant: localParticipant,
          isGroupCall: true,
          participants: participants,
          theme: theme,
          onEndCall: () {},
          onToggleMute: () {},
          onToggleSpeaker: () {},
        ),
      ));

      // 4 participants total (3 remote + 1 local) → 2x2 grid
      expect(find.byType(ParticipantTile), findsNWidgets(4));
    });

    testWidgets('dispose does not throw', (tester) async {
      await tester.pumpWidget(_app(
        CallScreen(
          callerName: 'Bob',
          localParticipant: localParticipant,
          theme: theme,
          onEndCall: () {},
          onToggleMute: () {},
          onToggleSpeaker: () {},
        ),
      ));

      // Replace with empty widget to trigger dispose
      await tester.pumpWidget(_app(const SizedBox()));
    });
  });
}
