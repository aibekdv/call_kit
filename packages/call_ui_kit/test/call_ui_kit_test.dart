import 'package:flutter_test/flutter_test.dart';

import 'package:call_ui_kit/call_ui_kit.dart';

void main() {
  test('barrel file exports GroupCallLayoutMode', () {
    // Verify the barrel export makes the enum accessible.
    expect(GroupCallLayoutMode.values, isNotEmpty);
  });

  test('barrel file exports CallParticipant', () {
    const participant = CallParticipant(id: '1', displayName: 'Test');
    expect(participant.id, '1');
    expect(participant.displayName, 'Test');
  });
}
