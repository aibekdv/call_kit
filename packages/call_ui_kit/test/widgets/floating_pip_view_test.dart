import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:call_ui_kit/call_ui_kit.dart';

Widget _app(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(children: [child]),
    ),
  );
}

void main() {
  const theme = CallTheme.whatsApp();
  final strings = CallStrings.englishDefaults;

  group('FloatingPipView', () {
    testWidgets('renders child when provided', (tester) async {
      await tester.pumpWidget(_app(
        FloatingPipView(
          displayName: 'Me',
          theme: theme,
          strings: strings,
          screenSize: const Size(400, 800),
          topBarHeight: 80,
          controlsHeight: 100,
          child: Container(key: const Key('pip-child'), color: Colors.blue),
        ),
      ));

      expect(find.byKey(const Key('pip-child')), findsOneWidget);
    });

    testWidgets('renders fallback when child is null', (tester) async {
      await tester.pumpWidget(_app(
        FloatingPipView(
          displayName: 'Me',
          theme: theme,
          strings: strings,
          screenSize: const Size(400, 800),
          topBarHeight: 80,
          controlsHeight: 100,
          child: null,
        ),
      ));

      // Should show "You" label in fallback
      expect(find.text(strings.you), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(_app(
        FloatingPipView(
          displayName: 'Me',
          theme: theme,
          strings: strings,
          screenSize: const Size(400, 800),
          topBarHeight: 80,
          controlsHeight: 100,
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(FloatingPipView));
      expect(tapped, true);
    });

    testWidgets('can be dragged', (tester) async {
      await tester.pumpWidget(_app(
        FloatingPipView(
          displayName: 'Me',
          theme: theme,
          strings: strings,
          screenSize: const Size(400, 800),
          topBarHeight: 80,
          controlsHeight: 100,
        ),
      ));

      // Perform a drag gesture
      final pip = find.byType(FloatingPipView);
      await tester.drag(pip, const Offset(-50, 50));
      await tester.pumpAndSettle();

      // Should snap to a corner after drag end
      // (no crash = success, snapping logic is tested in pip_snap_calculator_test)
    });

    testWidgets('dispose does not throw', (tester) async {
      await tester.pumpWidget(_app(
        FloatingPipView(
          displayName: 'Me',
          theme: theme,
          strings: strings,
          screenSize: const Size(400, 800),
          topBarHeight: 80,
          controlsHeight: 100,
        ),
      ));

      await tester.pumpWidget(_app(const SizedBox()));
    });
  });
}
