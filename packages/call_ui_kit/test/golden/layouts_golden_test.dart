@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:call_ui_kit/call_ui_kit.dart';

/// Visual regression coverage for the layouts the kit resolves automatically.
///
/// Presence-based widget tests cannot catch a layer moving, overlapping or
/// losing its space — which is exactly the class of bug this kit has hit. The
/// goldens are rendered with the default test font, and avatars use initials
/// (never a network image), so they are deterministic.
///
/// Regenerate after an intentional visual change:
///
/// ```sh
/// flutter test --update-goldens --tags golden
/// ```
void main() {
  const theme = CallTheme.whatsApp();
  const local = CallParticipant(
    id: 'local',
    displayName: 'Me',
    isLocalUser: true,
  );

  Widget wrap(Widget child) => MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: child,
        ),
      );

  Future<void> expectGolden(WidgetTester tester, String name) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CallScreen),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  List<CallParticipant> remotes(int count) => [
        for (var i = 0; i < count; i++)
          CallParticipant(
            id: 'p$i',
            displayName: 'Person $i',
            isMuted: i.isEven,
            videoWidget: ColoredBox(
              color: Color(0xFF204040 + i * 0x001010),
            ),
          ),
      ];

  CallScreen screen({
    bool isGroupCall = false,
    List<CallParticipant> participants = const [],
    Widget? localVideoWidget,
    Widget? remoteVideoWidget,
    Widget? screenShareWidget,
    CallConnectionState connectionState = CallConnectionState.connected,
    CallDimensions dimensions = const CallDimensions(),
  }) {
    return CallScreen(
      callerName: isGroupCall ? 'Design Review' : 'Alex Rivera',
      isGroupCall: isGroupCall,
      participants: participants,
      localParticipant: local,
      theme: theme,
      dimensions: dimensions,
      localVideoWidget: localVideoWidget,
      remoteVideoWidget: remoteVideoWidget,
      screenShareWidget: screenShareWidget,
      connectionState: connectionState,
      callStatusText: '04:23',
      onEndCall: () {},
      onToggleMute: () {},
      onToggleSpeaker: () {},
      onToggleCamera: () {},
      onFlipCamera: () {},
    );
  }

  group('golden', () {
    testWidgets('personal video call with PiP', (tester) async {
      await tester.pumpWidget(wrap(screen(
        localVideoWidget: const ColoredBox(color: Color(0xFF37474F)),
        remoteVideoWidget: const ColoredBox(color: Color(0xFF00695C)),
      )));
      await expectGolden(tester, 'personal_video_call');
    });

    testWidgets('personal call while reconnecting', (tester) async {
      await tester.pumpWidget(wrap(screen(
        localVideoWidget: const ColoredBox(color: Color(0xFF37474F)),
        remoteVideoWidget: const ColoredBox(color: Color(0xFF00695C)),
        connectionState: CallConnectionState.reconnecting,
      )));
      await expectGolden(tester, 'personal_video_call_reconnecting');
    });

    testWidgets('group grid 2x2', (tester) async {
      await tester.pumpWidget(wrap(screen(
        isGroupCall: true,
        participants: remotes(3),
      )));
      await expectGolden(tester, 'group_grid_2x2');
    });

    testWidgets('group speaker view', (tester) async {
      await tester.pumpWidget(wrap(screen(
        isGroupCall: true,
        participants: remotes(8),
      )));
      await expectGolden(tester, 'group_speaker_view');
    });

    testWidgets('screen share', (tester) async {
      await tester.pumpWidget(wrap(screen(
        isGroupCall: true,
        participants: remotes(3),
        screenShareWidget: const ColoredBox(color: Color(0xFF263238)),
      )));
      await expectGolden(tester, 'screen_share');
    });

    // The numeric tests prove the tokens multiply correctly; only a golden
    // catches a scaled layout breaking visually — text overflowing the
    // fixed-height bars, say, or the PiP colliding with the controls.
    testWidgets('personal video call at the comfortable preset',
        (tester) async {
      await tester.pumpWidget(wrap(screen(
        localVideoWidget: const ColoredBox(color: Color(0xFF37474F)),
        remoteVideoWidget: const ColoredBox(color: Color(0xFF00695C)),
        dimensions: const CallDimensions.comfortable(),
      )));
      await expectGolden(tester, 'personal_video_call_comfortable');
    });

    testWidgets('group grid at the comfortable preset', (tester) async {
      await tester.pumpWidget(wrap(screen(
        isGroupCall: true,
        participants: remotes(3),
        dimensions: const CallDimensions.comfortable(),
      )));
      await expectGolden(tester, 'group_grid_2x2_comfortable');
    });

    testWidgets('personal call with controls hidden', (tester) async {
      await tester.pumpWidget(wrap(screen(
        localVideoWidget: const ColoredBox(color: Color(0xFF37474F)),
        remoteVideoWidget: const ColoredBox(color: Color(0xFF00695C)),
      )));
      // Past the 4s auto-hide: the bars are gone and the PiP has moved up.
      await tester.pump(const Duration(seconds: 5));
      await expectGolden(tester, 'personal_video_call_controls_hidden');
    });
  });
}
