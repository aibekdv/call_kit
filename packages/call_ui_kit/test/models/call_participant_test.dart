import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:call_ui_kit/call_ui_kit.dart';

void main() {
  group('CallParticipant', () {
    const base = CallParticipant(id: 'u1', displayName: 'Alice');

    test('defaults are correct', () {
      expect(base.isMuted, false);
      expect(base.isCameraOff, false);
      expect(base.isSpeaking, false);
      expect(base.isScreenSharing, false);
      expect(base.isHost, false);
      expect(base.isLocalUser, false);
      expect(base.signalStrength, SignalStrength.excellent);
      expect(base.avatarUrl, isNull);
      expect(base.videoWidget, isNull);
      expect(base.screenShareWidget, isNull);
    });

    test('copyWith replaces fields', () {
      final muted = base.copyWith(isMuted: true, isSpeaking: true);
      expect(muted.id, 'u1');
      expect(muted.displayName, 'Alice');
      expect(muted.isMuted, true);
      expect(muted.isSpeaking, true);
    });

    test('copyWith preserves unchanged fields', () {
      final copy = base.copyWith(displayName: 'Bob');
      expect(copy.id, 'u1');
      expect(copy.displayName, 'Bob');
      expect(copy.isMuted, false);
    });

    test('copyWith can set nullable fields to null explicitly', () {
      const withAvatar = CallParticipant(
        id: 'u1',
        displayName: 'Alice',
        avatarUrl: 'https://example.com/avatar.png',
      );
      final cleared = withAvatar.copyWith(avatarUrl: null);
      expect(cleared.avatarUrl, isNull);
    });

    test('copyWith preserves nullable field when absent (default)', () {
      const withAvatar = CallParticipant(
        id: 'u1',
        displayName: 'Alice',
        avatarUrl: 'https://example.com/avatar.png',
      );
      final copy = withAvatar.copyWith(isMuted: true);
      expect(copy.avatarUrl, 'https://example.com/avatar.png');
    });

    test('copyWith can set videoWidget to null explicitly', () {
      const withVideo = CallParticipant(
        id: 'u1',
        displayName: 'Alice',
        videoWidget: SizedBox(),
      );
      final cleared = withVideo.copyWith(videoWidget: null);
      expect(cleared.videoWidget, isNull);
    });

    group('equality', () {
      test('equal participants are equal', () {
        const a = CallParticipant(id: 'u1', displayName: 'Alice');
        const b = CallParticipant(id: 'u1', displayName: 'Alice');
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('different id makes unequal', () {
        const a = CallParticipant(id: 'u1', displayName: 'Alice');
        const b = CallParticipant(id: 'u2', displayName: 'Alice');
        expect(a, isNot(equals(b)));
      });

      test('different muted state makes unequal', () {
        const a = CallParticipant(id: 'u1', displayName: 'Alice');
        const b = CallParticipant(
          id: 'u1',
          displayName: 'Alice',
          isMuted: true,
        );
        expect(a, isNot(equals(b)));
      });

      test('videoWidget is excluded from equality', () {
        const a = CallParticipant(
          id: 'u1',
          displayName: 'Alice',
          videoWidget: SizedBox(),
        );
        const b = CallParticipant(id: 'u1', displayName: 'Alice');
        expect(a, equals(b));
      });
    });

    test('toString contains id and displayName', () {
      final str = base.toString();
      expect(str, contains('u1'));
      expect(str, contains('Alice'));
    });
  });

  group('CallStrings', () {
    test('english factory provides all required fields', () {
      final strings = CallStrings.english();
      expect(strings.calling, isNotEmpty);
      expect(strings.endCall, isNotEmpty);
      expect(strings.mute, isNotEmpty);
      expect(strings.unmute, isNotEmpty);
      expect(strings.speaker, isNotEmpty);
      expect(strings.camera, isNotEmpty);
      expect(strings.moreOptions, isNotEmpty);
    });

    test('englishDefaults is cached', () {
      final a = CallStrings.englishDefaults;
      final b = CallStrings.englishDefaults;
      expect(identical(a, b), true);
    });

    test('isSharingScreen callback works', () {
      final strings = CallStrings.english();
      expect(strings.isSharingScreen('Bob'), contains('Bob'));
    });

    test('participantsCount handles singular and plural', () {
      final strings = CallStrings.english();
      expect(strings.participantsCount(1), contains('1'));
      expect(strings.participantsCount(5), contains('5'));
    });
  });

  group('CallTheme', () {
    test('whatsApp preset has non-null colors', () {
      const theme = CallTheme.whatsApp();
      expect(theme.background, isNotNull);
      expect(theme.endCallColor, isNotNull);
      expect(theme.speakingColor, isNotNull);
    });

    test('copyWith replaces specific colors', () {
      const theme = CallTheme.whatsApp();
      final custom = theme.copyWith(endCallColor: const Color(0xFFFF0000));
      expect(custom.endCallColor, const Color(0xFFFF0000));
      expect(custom.background, theme.background);
    });

    test('toString contains key info', () {
      const theme = CallTheme.whatsApp();
      expect(theme.toString(), contains('CallTheme'));
    });
  });
}
