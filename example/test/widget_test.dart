import 'package:call_native_kit_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the manual test rig', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Show incoming'), findsOneWidget);
    expect(find.text('Simulate push'), findsOneWidget);
  });
}
