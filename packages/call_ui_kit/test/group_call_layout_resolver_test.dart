import 'package:flutter_test/flutter_test.dart';
import 'package:call_ui_kit/call_ui_kit.dart';

void main() {
  group('GroupCallLayoutResolver', () {
    test('returns screenShare when hasScreenShare is true', () {
      final result = GroupCallLayoutResolver.resolve(
        totalCount: 5,
        hasScreenShare: true,
      );
      expect(result, GroupCallLayoutMode.screenShare);
    });

    test('returns fullScreenPip for 2 participants', () {
      final result = GroupCallLayoutResolver.resolve(
        totalCount: 2,
        hasScreenShare: false,
      );
      expect(result, GroupCallLayoutMode.fullScreenPip);
    });

    test('returns grid2x2 for 3 participants', () {
      final result = GroupCallLayoutResolver.resolve(
        totalCount: 3,
        hasScreenShare: false,
      );
      expect(result, GroupCallLayoutMode.grid2x2);
    });

    test('returns grid2x2 for 4 participants', () {
      final result = GroupCallLayoutResolver.resolve(
        totalCount: 4,
        hasScreenShare: false,
      );
      expect(result, GroupCallLayoutMode.grid2x2);
    });

    test('returns grid2x3 for 5 participants', () {
      final result = GroupCallLayoutResolver.resolve(
        totalCount: 5,
        hasScreenShare: false,
      );
      expect(result, GroupCallLayoutMode.grid2x3);
    });

    test('returns grid2x3 for 6 participants', () {
      final result = GroupCallLayoutResolver.resolve(
        totalCount: 6,
        hasScreenShare: false,
      );
      expect(result, GroupCallLayoutMode.grid2x3);
    });

    test('returns speakerView for 7 participants', () {
      final result = GroupCallLayoutResolver.resolve(
        totalCount: 7,
        hasScreenShare: false,
      );
      expect(result, GroupCallLayoutMode.speakerView);
    });

    test('returns speakerView for 20 participants', () {
      final result = GroupCallLayoutResolver.resolve(
        totalCount: 20,
        hasScreenShare: false,
      );
      expect(result, GroupCallLayoutMode.speakerView);
    });

    test('screenShare takes priority over participant count', () {
      final result = GroupCallLayoutResolver.resolve(
        totalCount: 4,
        hasScreenShare: true,
      );
      expect(result, GroupCallLayoutMode.screenShare);
    });
  });
}
