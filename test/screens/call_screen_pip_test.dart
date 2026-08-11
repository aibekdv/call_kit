import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:call_ui_kit/call_ui_kit.dart';
import 'package:call_ui_kit/src/screens/layers/call_bottom_bar.dart';
import 'package:call_ui_kit/src/screens/layers/call_right_buttons.dart';
import 'package:call_ui_kit/src/screens/layers/call_top_bar.dart';

Widget _app(Widget child) => MaterialApp(home: child);

/// Mirrors the private geometry constants of `FloatingPipView`.
const _pipMargin = 16.0;
const _pipHeight = 120.0;

const _theme = CallTheme.whatsApp();
const _local = CallParticipant(
  id: 'local',
  displayName: 'Me',
  isLocalUser: true,
);

CallScreen _screen({
  Widget? localVideoWidget,
  Widget? remoteVideoWidget,
  Widget? screenShareWidget,
  bool isCameraOff = false,
  List<CallParticipant> participants = const [],
  bool isGroupCall = false,
  CallConnectionState connectionState = CallConnectionState.connected,
  VoidCallback? onEndCall,
}) {
  return CallScreen(
    callerName: 'Bob',
    localParticipant: _local,
    participants: participants,
    isGroupCall: isGroupCall,
    theme: _theme,
    localVideoWidget: localVideoWidget,
    remoteVideoWidget: remoteVideoWidget,
    screenShareWidget: screenShareWidget,
    isCameraOff: isCameraOff,
    connectionState: connectionState,
    onEndCall: onEndCall ?? () {},
    onToggleMute: () {},
    onToggleSpeaker: () {},
    onToggleCamera: () {},
  );
}

/// Whether [key] is currently rendered inside the floating PiP frame.
bool _inPip(WidgetTester tester, Key key) {
  return tester
      .widgetList(find.descendant(
        of: find.byType(FloatingPipView),
        matching: find.byKey(key),
      ))
      .isNotEmpty;
}

void main() {
  group('CallScreen — video widget replacement (reconnect)', () {
    testWidgets('swapping the local video widget updates the PiP',
        (tester) async {
      const first = Key('local-v1');
      const second = Key('local-v2');

      await tester.pumpWidget(_app(_screen(
        localVideoWidget: const ColoredBox(key: first, color: Colors.blue),
        remoteVideoWidget: const ColoredBox(color: Colors.teal),
      )));

      expect(_inPip(tester, first), isTrue);

      // A reconnect recreates the renderer widget.
      await tester.pumpWidget(_app(_screen(
        localVideoWidget: const ColoredBox(key: second, color: Colors.blue),
        remoteVideoWidget: const ColoredBox(color: Colors.teal),
      )));

      expect(find.byKey(first), findsNothing);
      expect(_inPip(tester, second), isTrue);
    });

    testWidgets('swapping the remote video widget updates the full screen',
        (tester) async {
      const first = Key('remote-v1');
      const second = Key('remote-v2');

      await tester.pumpWidget(_app(_screen(
        remoteVideoWidget: const ColoredBox(key: first, color: Colors.teal),
      )));
      expect(find.byKey(first), findsOneWidget);

      await tester.pumpWidget(_app(_screen(
        remoteVideoWidget: const ColoredBox(key: second, color: Colors.teal),
      )));

      expect(find.byKey(first), findsNothing);
      expect(find.byKey(second), findsOneWidget);
    });

    testWidgets('replacing a participant video widget updates the grid',
        (tester) async {
      const first = Key('p-v1');
      const second = Key('p-v2');

      final participants = <CallParticipant>[
        const CallParticipant(
          id: 'a',
          displayName: 'Alice',
          videoWidget: ColoredBox(key: first, color: Colors.teal),
        ),
        const CallParticipant(id: 'b', displayName: 'Bea'),
        const CallParticipant(id: 'c', displayName: 'Cara'),
      ];

      await tester.pumpWidget(_app(_screen(
        isGroupCall: true,
        participants: participants,
      )));
      expect(find.byKey(first), findsOneWidget);

      // The host mutates its list in place and rebuilds — a stale cache keyed
      // on list identity would keep the disposed renderer on screen.
      participants[0] = participants[0].copyWith(
        videoWidget: const ColoredBox(key: second, color: Colors.teal),
      );

      await tester.pumpWidget(_app(_screen(
        isGroupCall: true,
        participants: participants,
      )));

      expect(find.byKey(first), findsNothing);
      expect(find.byKey(second), findsOneWidget);
    });

    testWidgets('PiP keeps an opaque backing when the child paints nothing',
        (tester) async {
      await tester.pumpWidget(_app(_screen(
        localVideoWidget: const SizedBox.expand(),
        remoteVideoWidget: const ColoredBox(color: Colors.teal),
      )));

      expect(
        find.descendant(
          of: find.byType(FloatingPipView),
          matching: find.byType(VideoSurface),
        ),
        findsOneWidget,
      );

      final backing = tester.widgetList<ColoredBox>(find.descendant(
        of: find.byType(FloatingPipView),
        matching: find.byType(ColoredBox),
      ));

      expect(backing.any((b) => b.color == Colors.black), isTrue);
    });
  });

  group('CallScreen — camera off and swap', () {
    testWidgets('camera off blanks the PiP, remote stays full screen',
        (tester) async {
      const localKey = Key('local-v');
      const remoteKey = Key('remote-v');

      await tester.pumpWidget(_app(_screen(
        localVideoWidget: const ColoredBox(key: localKey, color: Colors.blue),
        remoteVideoWidget: const ColoredBox(key: remoteKey, color: Colors.teal),
        isCameraOff: true,
      )));

      expect(find.byKey(localKey), findsNothing);
      expect(find.byKey(remoteKey), findsOneWidget);
    });

    testWidgets('tapping the PiP swaps local and remote surfaces',
        (tester) async {
      const localKey = Key('local-v');
      const remoteKey = Key('remote-v');

      await tester.pumpWidget(_app(_screen(
        localVideoWidget: const ColoredBox(key: localKey, color: Colors.blue),
        remoteVideoWidget: const ColoredBox(key: remoteKey, color: Colors.teal),
      )));

      expect(_inPip(tester, localKey), isTrue);
      expect(_inPip(tester, remoteKey), isFalse);

      await tester.tap(find.byType(FloatingPipView));
      await tester.pumpAndSettle();

      expect(_inPip(tester, remoteKey), isTrue);
      expect(_inPip(tester, localKey), isFalse);
    });

    testWidgets('turning the camera off while swapped restores the remote view',
        (tester) async {
      const localKey = Key('local-v');
      const remoteKey = Key('remote-v');

      Widget build({required bool cameraOff}) => _app(_screen(
            localVideoWidget:
                const ColoredBox(key: localKey, color: Colors.blue),
            remoteVideoWidget:
                const ColoredBox(key: remoteKey, color: Colors.teal),
            isCameraOff: cameraOff,
          ));

      await tester.pumpWidget(build(cameraOff: false));
      await tester.tap(find.byType(FloatingPipView));
      await tester.pumpAndSettle();
      expect(_inPip(tester, remoteKey), isTrue);

      await tester.pumpWidget(build(cameraOff: true));
      await tester.pumpAndSettle();

      // Auto-unswap: the remote feed returns full screen rather than being
      // stranded in a PiP that the local camera flag would blank.
      expect(find.byKey(localKey), findsNothing);
      expect(_inPip(tester, remoteKey), isFalse);
      expect(find.byKey(remoteKey), findsOneWidget);
    });
  });

  group('CallScreen — PiP follows the controls', () {
    testWidgets('PiP rises when the controls hide and returns when they show',
        (tester) async {
      await tester.pumpWidget(_app(_screen(
        localVideoWidget: const ColoredBox(color: Colors.blue),
        remoteVideoWidget: const ColoredBox(color: Colors.teal),
      )));
      await tester.pumpAndSettle();

      final withControls = tester.getTopLeft(find.byType(FloatingPipView));
      expect(withControls.dy, CallTopBar.height + _pipMargin);

      // Auto-hide cycle: the top bar's space is now free.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      final withoutControls = tester.getTopLeft(find.byType(FloatingPipView));
      expect(withoutControls.dy, _pipMargin);
      expect(withoutControls.dx, withControls.dx);

      // Tap to bring the controls back.
      await tester.tapAt(const Offset(200, 400));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(FloatingPipView)), withControls);
    });

    testWidgets('PiP anchored to the bottom drops into the bar area',
        (tester) async {
      await tester.pumpWidget(_app(_screen(
        localVideoWidget: const ColoredBox(color: Colors.blue),
        remoteVideoWidget: const ColoredBox(color: Colors.teal),
      )));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(FloatingPipView), const Offset(0, 2000));
      await tester.pumpAndSettle();

      final screenHeight = tester.getSize(find.byType(CallScreen)).height;
      final withControls = tester.getTopLeft(find.byType(FloatingPipView)).dy;
      expect(
        withControls,
        screenHeight - _pipHeight - CallBottomBar.height - _pipMargin,
      );

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.byType(FloatingPipView)).dy,
        screenHeight - _pipHeight - _pipMargin,
      );
    });

    testWidgets('PiP keeps its corner across a hide/show cycle',
        (tester) async {
      await tester.pumpWidget(_app(_screen(
        localVideoWidget: const ColoredBox(color: Colors.blue),
        remoteVideoWidget: const ColoredBox(color: Colors.teal),
      )));
      await tester.pumpAndSettle();

      // Drag to the bottom-left corner.
      await tester.drag(
        find.byType(FloatingPipView),
        const Offset(-2000, 2000),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(FloatingPipView)).dx, _pipMargin);

      // Two full hide/show cycles must not drift the PiP to another corner.
      for (var i = 0; i < 2; i++) {
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byType(FloatingPipView)).dx, _pipMargin);

        await tester.tapAt(const Offset(400, 300));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byType(FloatingPipView)).dx, _pipMargin);
      }

      final screenHeight = tester.getSize(find.byType(CallScreen)).height;
      expect(
        tester.getTopLeft(find.byType(FloatingPipView)).dy,
        screenHeight - _pipHeight - CallBottomBar.height - _pipMargin,
      );
    });
  });

  group('CallScreen — PiP stability', () {
    testWidgets('PiP stays clear of the bottom bar after dragging down',
        (tester) async {
      await tester.pumpWidget(_app(_screen(
        localVideoWidget: const ColoredBox(color: Colors.blue),
        remoteVideoWidget: const ColoredBox(color: Colors.teal),
      )));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(FloatingPipView), const Offset(0, 2000));
      await tester.pumpAndSettle();

      final pipBottom = tester.getBottomLeft(find.byType(FloatingPipView)).dy;
      final barTop = tester.getTopLeft(find.byType(CallBottomBar)).dy;

      expect(pipBottom, lessThanOrEqualTo(barTop));
    });

    testWidgets('PiP starts below the side buttons when they are shown',
        (tester) async {
      await tester.pumpWidget(_app(CallScreen(
        callerName: 'Bob',
        localParticipant: _local,
        theme: _theme,
        localVideoWidget: const ColoredBox(color: Colors.blue),
        remoteVideoWidget: const ColoredBox(color: Colors.teal),
        onAddParticipant: () {},
        onEffects: () {},
        onEndCall: () {},
        onToggleMute: () {},
        onToggleSpeaker: () {},
      )));
      await tester.pumpAndSettle();

      final pipTop = tester.getTopLeft(find.byType(FloatingPipView)).dy;
      final buttonsBottom =
          tester.getBottomLeft(find.byType(CallRightButtons)).dy;

      expect(pipTop, greaterThanOrEqualTo(buttonsBottom));
    });

    testWidgets('survives a viewport smaller than the reserved areas',
        (tester) async {
      tester.view.physicalSize = const Size(320, 320);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(_screen(
        localVideoWidget: const ColoredBox(color: Colors.blue),
        remoteVideoWidget: const ColoredBox(color: Colors.teal),
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(FloatingPipView), findsOneWidget);
    });

    testWidgets('tapping the PiP after dragging it down still swaps',
        (tester) async {
      const localKey = Key('local-v');
      const remoteKey = Key('remote-v');

      await tester.pumpWidget(_app(_screen(
        localVideoWidget: const ColoredBox(key: localKey, color: Colors.blue),
        remoteVideoWidget: const ColoredBox(key: remoteKey, color: Colors.teal),
      )));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(FloatingPipView), const Offset(0, 2000));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingPipView));
      await tester.pumpAndSettle();

      expect(_inPip(tester, remoteKey), isTrue);
    });
  });

  group('CallScreen — controls interactivity', () {
    testWidgets('a fading-out button still fires', (tester) async {
      var ended = false;

      await tester.pumpWidget(_app(_screen(onEndCall: () => ended = true)));

      // Trigger the auto-hide, then tap mid-fade while the button is still
      // plainly visible.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.call_end));
      expect(ended, isTrue);
    });

    testWidgets('a fully hidden bar is inert and the tap reveals controls',
        (tester) async {
      var ended = false;

      await tester.pumpWidget(_app(_screen(onEndCall: () => ended = true)));

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.call_end), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(ended, isFalse);

      final opacity = tester.widget<AnimatedOpacity>(find.ancestor(
        of: find.byType(CallBottomBar),
        matching: find.byType(AnimatedOpacity),
      ));
      expect(opacity.opacity, 1.0);
    });
  });

  group('CallScreen — modal sheets', () {
    testWidgets('auto-hide is paused while a sheet is open', (tester) async {
      await tester.pumpWidget(_app(CallScreen(
        callerName: 'Bob',
        localParticipant: _local,
        theme: _theme,
        onEndCall: () {},
        onToggleMute: () {},
        onToggleSpeaker: () {},
        moreSheetBuilder: (_, __) => const Text('sheet body'),
      )));

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      expect(find.text('sheet body'), findsOneWidget);

      // Well past the 4s auto-hide delay.
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.text('sheet body'))).pop();
      await tester.pumpAndSettle();

      final opacity = tester.widget<AnimatedOpacity>(find.ancestor(
        of: find.byType(CallBottomBar),
        matching: find.byType(AnimatedOpacity),
      ));
      expect(opacity.opacity, 1.0);
    });

    testWidgets('an open participants panel reflects later state changes',
        (tester) async {
      // Speaker view (7+ participants) is what exposes the "+N more" entry
      // point into the participants panel.
      Widget build(bool muted) => _app(CallScreen(
            callerName: 'Team',
            isGroupCall: true,
            localParticipant: _local,
            participants: [
              CallParticipant(id: 'a', displayName: 'Alice', isMuted: muted),
              for (var i = 1; i < 8; i++)
                CallParticipant(id: 'p$i', displayName: 'Person $i'),
            ],
            theme: _theme,
            onEndCall: () {},
            onToggleMute: () {},
            onToggleSpeaker: () {},
          ));

      await tester.pumpWidget(build(false));

      // The floating bottom bar overlaps the thumbnail row, so let the
      // controls hide before reaching for the "+N more" entry.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(CallStrings.englishDefaults.moreParticipants(2)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ParticipantsPanel), findsOneWidget);
      final unmutedIcons = find.descendant(
        of: find.byType(ParticipantsPanel),
        matching: find.byIcon(Icons.mic_off),
      );
      final before = tester.widgetList(unmutedIcons).length;

      // The host mutes Alice while the panel is open.
      await tester.pumpWidget(build(true));
      await tester.pumpAndSettle();

      expect(tester.widgetList(unmutedIcons).length, greaterThan(before));
    });
  });

  group('CallScreen — connection state', () {
    testWidgets('shows a banner while reconnecting', (tester) async {
      await tester.pumpWidget(_app(
        _screen(connectionState: CallConnectionState.reconnecting),
      ));

      expect(find.byType(ConnectionStateBanner), findsOneWidget);
      expect(
          find.text(CallStrings.englishDefaults.reconnecting), findsOneWidget);
    });

    testWidgets('shows nothing when connected', (tester) async {
      await tester.pumpWidget(_app(_screen()));

      expect(find.text(CallStrings.englishDefaults.reconnecting), findsNothing);
      expect(find.text(CallStrings.englishDefaults.connecting), findsNothing);
    });

    testWidgets('reconnecting banner survives the controls auto-hide',
        (tester) async {
      await tester.pumpWidget(_app(
        _screen(connectionState: CallConnectionState.reconnecting),
      ));

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(
          find.text(CallStrings.englishDefaults.reconnecting), findsOneWidget);
    });
  });

  group('CallScreen — screen share', () {
    testWidgets('personal call shows the share banner with the caller name',
        (tester) async {
      await tester.pumpWidget(_app(_screen(
        screenShareWidget: const ColoredBox(color: Colors.grey),
      )));

      expect(find.byType(ScreenShareBanner), findsOneWidget);
      expect(
        find.text(CallStrings.englishDefaults.isSharingScreen('Bob')),
        findsOneWidget,
      );
    });

    testWidgets('PiP is hidden while a screen share is on screen',
        (tester) async {
      await tester.pumpWidget(_app(_screen(
        localVideoWidget: const ColoredBox(color: Colors.blue),
        screenShareWidget: const ColoredBox(color: Colors.grey),
      )));

      expect(find.byType(FloatingPipView), findsNothing);
    });
  });

  group('CallScreen — personal fallback', () {
    testWidgets('does not claim the remote camera is off', (tester) async {
      await tester.pumpWidget(_app(_screen(isCameraOff: true)));

      expect(find.text(CallStrings.englishDefaults.cameraIsOff), findsNothing);
      expect(find.text('Bob'), findsWidgets);
    });
  });
}
