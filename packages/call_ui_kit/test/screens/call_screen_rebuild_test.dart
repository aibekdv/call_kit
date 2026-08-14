import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:call_ui_kit/call_ui_kit.dart';

/// Counts how often the host-provided video widget is rebuilt.
///
/// Deliberately non-const: real applications construct their renderer widget
/// (`RTCVideoView` and friends) inside `build`, so a new instance reaches the
/// kit on every host rebuild and Flutter cannot short-circuit the subtree.
class _CountingVideo extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _CountingVideo(); // must NOT be const — see the class doc.

  static int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    return const ColoredBox(color: Colors.teal);
  }
}

void main() {
  setUp(() => _CountingVideo.builds = 0);

  group('CallScreen — rebuild scope', () {
    testWidgets('pushing callStatusText rebuilds every video surface',
        (tester) async {
      Widget build(String status) => MaterialApp(
            home: CallScreen(
              callerName: 'Team',
              isGroupCall: true,
              callStatusText: status,
              localParticipant: const CallParticipant(
                id: 'l',
                displayName: 'Me',
                isLocalUser: true,
              ),
              participants: [
                for (final id in ['a', 'b', 'c'])
                  CallParticipant(
                    id: id,
                    displayName: id,
                    videoWidget: _CountingVideo(),
                  ),
              ],
              onEndCall: () {},
              onToggleMute: () {},
              onToggleSpeaker: () {},
            ),
          );

      await tester.pumpWidget(build('00:01'));
      await tester.pumpAndSettle();
      final atMount = _CountingVideo.builds;
      expect(atMount, 3);

      // Ten seconds of a ticking call-duration timer.
      for (var i = 2; i <= 11; i++) {
        await tester.pumpWidget(build('00:0$i'));
      }

      // Every tick re-runs CallScreen.build and with it the whole video tree.
      expect(_CountingVideo.builds, atMount + 3 * 10);
    });

    testWidgets('callStatusListenable leaves the video surfaces untouched',
        (tester) async {
      final status = ValueNotifier<String>('00:01');
      addTearDown(status.dispose);

      // Built once, exactly as an application should hold its renderers.
      final videos = [
        for (final id in ['a', 'b', 'c'])
          CallParticipant(
            id: id,
            displayName: id,
            videoWidget: _CountingVideo(),
          ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: CallScreen(
          callerName: 'Team',
          isGroupCall: true,
          callStatusListenable: status,
          localParticipant: const CallParticipant(
            id: 'l',
            displayName: 'Me',
            isLocalUser: true,
          ),
          participants: videos,
          onEndCall: () {},
          onToggleMute: () {},
          onToggleSpeaker: () {},
        ),
      ));
      await tester.pumpAndSettle();
      final atMount = _CountingVideo.builds;
      expect(atMount, 3);

      for (var i = 2; i <= 11; i++) {
        status.value = '00:0$i';
        await tester.pump();
      }

      // The status line rebuilt ten times; nothing else did.
      expect(_CountingVideo.builds, atMount);
      expect(find.text('00:011'), findsOneWidget);
    });
  });
}
