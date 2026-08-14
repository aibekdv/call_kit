import 'package:call_ui_kit/call_ui_kit.dart';
import 'package:call_ui_kit/src/screens/layers/call_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _theme = CallTheme.whatsApp();
final _strings = CallStrings.english();

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

CallBottomBar _bottomBar(CallDimensions dimensions) => CallBottomBar(
      theme: _theme,
      dimensions: dimensions,
      strings: _strings,
      isMuted: false,
      isSpeakerOn: false,
      onResetHideTimer: () {},
      onToggleMute: () {},
      onToggleSpeaker: () {},
      onEndCall: () {},
    );

/// The end-call button's laid-out box.
Finder get _endCallButton => find
    .ancestor(
      of: find.byIcon(Icons.call_end),
      matching: find.byType(Container),
    )
    .first;

void main() {
  group('CallDimensions defaults', () {
    // These are the sizes the kit hard-coded before they became configurable.
    // Nothing here may change without a deliberate breaking release: an
    // existing consumer who never passes `dimensions` must see the same
    // layout. The goldens back this up visually; this test names the numbers.
    test('reproduce the kit\'s original metrics', () {
      const d = CallDimensions();

      expect(d.scale, 1.0);

      expect(d.topBar.height, 80);
      expect(d.topBar.minimizeIconSize, 24);
      expect(d.topBar.flipIconSize, 28);
      expect(d.topBar.nameFontSize, 16);
      expect(d.topBar.statusFontSize, 13);
      expect(d.topBar.countFontSize, 11);
      expect(d.topBar.nameGap, 2);
      expect(d.topBar.minTapTarget, kMinInteractiveDimension);

      expect(d.bottomBar.buttonSize, 50);
      expect(d.bottomBar.endCallButtonSize, 58);
      expect(d.bottomBar.iconSize, 22);
      expect(d.bottomBar.endCallIconSize, 26);
      expect(d.bottomBar.horizontalInset, 12);
      expect(d.bottomBar.innerHorizontal, 8);
      expect(d.bottomBar.verticalPadding, 12);
      expect(d.bottomBar.bottomInset, 20);
      expect(d.bottomBar.barRadius, 40);

      expect(d.rightButtons.buttonSize, 48);
      expect(d.rightButtons.spacing, 12);
      expect(d.rightButtons.iconSize, 22);
      expect(d.rightButtons.gapFromTopBar, 20);
      expect(d.rightButtons.insetFromEdge, 12);

      expect(d.videoContent.personalAvatarRadius, 40);
      expect(d.videoContent.personalAvatarNameGap, 12);
      expect(d.videoContent.personalNameFontSize, 20);
      expect(d.videoContent.personalAvatarFontRatio, 0.35);
      expect(d.videoContent.sharingIconSize, 48);
      expect(d.videoContent.sharingIconGap, 16);
      expect(d.videoContent.sharingLabelFontSize, 16);
      expect(d.videoContent.sharingLabelButtonGap, 24);
      expect(d.videoContent.sharingStopHorizontal, 24);
      expect(d.videoContent.sharingStopVertical, 10);
      expect(d.videoContent.sharingStopRadius, 24);
      expect(d.videoContent.sharingStopFontSize, 14);
      expect(d.videoContent.gridGutter, 1);

      expect(d.participantTile.padding, 4);
      expect(d.participantTile.avatarRadius, 24);
      expect(d.participantTile.avatarNameGap, 6);
      expect(d.participantTile.nameFontSize, 11);
      expect(d.participantTile.gradientHeight, 60);
      expect(d.participantTile.overlayInset, 8);
      expect(d.participantTile.mutedRightInset, 28);
      expect(d.participantTile.nameIndicatorGap, 4);
      expect(d.participantTile.speakingMaxHeight, 12);
      expect(d.participantTile.speakingMinHeight, 3);
      expect(d.participantTile.speakingBarWidth, 2.5);
      expect(d.participantTile.speakingBarGap, 2);
      expect(d.participantTile.speakingBorderWidth, 2.5);
      expect(d.participantTile.micOffIconSize, 14);
      expect(d.participantTile.signalIconSize, 12);
      expect(d.participantTile.signalInset, 6);
      expect(d.participantTile.screenShareIconSize, 14);

      expect(d.thumbnailRow.height, 90);
      expect(d.thumbnailRow.padding, 4);
      expect(d.thumbnailRow.tileWidth, 70);
      expect(d.thumbnailRow.tileMargin, 2);
      expect(d.thumbnailRow.tileRadius, 8);
      expect(d.thumbnailRow.moreFontSize, 12);

      expect(d.pip.size, const Size(90, 120));
      expect(d.pip.margin, 16);
      expect(d.pip.borderRadius, 12);
      expect(d.pip.borderWidth, 1.5);
      expect(d.pip.avatarRadius, 20);
      expect(d.pip.initialFontSize, 14);
      expect(d.pip.labelGap, 4);
      expect(d.pip.labelFontSize, 10);

      expect(d.connectionBanner.height, 36);
      expect(d.connectionBanner.horizontalPadding, 12);
      expect(d.connectionBanner.iconSize, 14);
      expect(d.connectionBanner.iconGap, 8);
      expect(d.connectionBanner.fontSize, 12);

      expect(d.screenShareBanner.height, 36);
      expect(d.screenShareBanner.horizontalPadding, 12);
      expect(d.screenShareBanner.iconSize, 14);
      expect(d.screenShareBanner.iconGap, 8);
      expect(d.screenShareBanner.fontSize, 12);
      expect(d.screenShareBanner.stopHorizontal, 10);
      expect(d.screenShareBanner.stopVertical, 3);
      expect(d.screenShareBanner.stopRadius, 4);
      expect(d.screenShareBanner.stopFontSize, 11);

      expect(d.participantsPanel.radius, 16);
      expect(d.participantsPanel.bottomPadding, 16);
      expect(d.participantsPanel.headerHorizontal, 16);
      expect(d.participantsPanel.headerVertical, 4);
      expect(d.participantsPanel.titleFontSize, 15);
      expect(d.participantsPanel.muteAllFontSize, 13);
      expect(d.participantsPanel.closeIconSize, 20);
      expect(d.participantsPanel.inviteHorizontal, 16);
      expect(d.participantsPanel.inviteTop, 8);
      expect(d.participantsPanel.inviteButtonHeight, 44);
      expect(d.participantsPanel.inviteIconSize, 20);
      expect(d.participantsPanel.inviteRadius, 22);
      expect(d.participantsPanel.rowHeight, 52);
      expect(d.participantsPanel.rowHorizontal, 16);
      expect(d.participantsPanel.rowAvatarRadius, 18);
      expect(d.participantsPanel.rowAvatarFontSize, 14);
      expect(d.participantsPanel.rowAvatarGap, 12);
      expect(d.participantsPanel.rowNameFontSize, 14);
      expect(d.participantsPanel.rowStatusFontSize, 11);
      expect(d.participantsPanel.rowIconSize, 18);
      expect(d.participantsPanel.rowHostIconSize, 16);
      expect(d.participantsPanel.rowIconGap, 8);
      expect(d.participantsPanel.hostActionsTop, 8);
      expect(d.participantsPanel.hostActionsHandleGap, 16);

      expect(d.moreSheet.radius, 16);
      expect(d.moreSheet.bottomPadding, 16);
      expect(d.moreSheet.lockIconSize, 14);
      expect(d.moreSheet.lockGap, 6);
      expect(d.moreSheet.encryptionFontSize, 13);
      expect(d.moreSheet.sectionGap, 12);
      expect(d.moreSheet.cancelMargin, 16);
      expect(d.moreSheet.cancelRadius, 12);
      expect(d.moreSheet.cancelFontSize, 16);

      expect(d.handleBar.width, 36);
      expect(d.handleBar.height, 4);
      expect(d.handleBar.verticalMargin, 10);

      expect(d.incoming.avatarRadius, 50);
      expect(d.incoming.avatarNameGap, 16);
      expect(d.incoming.nameFontSize, 24);
      expect(d.incoming.nameStatusGap, 8);
      expect(d.incoming.statusFontSize, 15);
      expect(d.incoming.bottomInset, 48);
      expect(d.incoming.actionButtonSize, 64);
      expect(d.incoming.actionIconSize, 28);
      expect(d.incoming.actionLabelGap, 8);
      expect(d.incoming.actionLabelFontSize, 13);

      expect(d.outgoing.minimizePadding, 12);
      expect(d.outgoing.minimizeIconSize, 28);
      expect(d.outgoing.avatarRadius, 50);
      expect(d.outgoing.avatarNameGap, 16);
      expect(d.outgoing.nameFontSize, 24);
      expect(d.outgoing.nameStatusGap, 8);
      expect(d.outgoing.statusFontSize, 15);
      expect(d.outgoing.bottomInset, 48);
      expect(d.outgoing.endCallSize, 50);
      expect(d.outgoing.endCallIconSize, 22);
      expect(d.outgoing.toggleSize, 50);
      expect(d.outgoing.toggleIconSize, 22);
    });

    test('the reserved areas match the numbers the kit shipped', () {
      const d = CallDimensions();

      expect(d.topBarHeight, 80);
      expect(d.connectionBannerHeight, 36);
      expect(d.bottomBarHeight, 102); // 20 + 12 * 2 + 58
      expect(d.rightButtonsHeight(hasAdd: true, hasEffects: true), 108);
      expect(d.rightButtonsHeight(hasAdd: true, hasEffects: false), 48);
      expect(d.rightButtonsHeight(hasAdd: false, hasEffects: false), 0);
    });
  });

  group('CallDimensions scale', () {
    test('the default scale leaves every metric untouched', () {
      const d = CallDimensions();
      expect(d.scaled(58), 58.0);
      expect(d.scaled(2.5), 2.5);
      expect(d.scaledSize(const Size(90, 120)), const Size(90, 120));
    });

    test('scaled multiplies by the scale', () {
      const d = CallDimensions(scale: 1.25);
      expect(d.scaled(50), 62.5);
      expect(d.scaled(0), 0.0);
      expect(d.scaledSize(const Size(90, 120)), const Size(112.5, 150));
    });

    test('the declared bar heights follow the scale', () {
      const compact = CallDimensions();
      const large = CallDimensions(scale: 1.25);

      expect(large.topBarHeight, compact.topBarHeight * 1.25);
      expect(large.bottomBarHeight, compact.bottomBarHeight * 1.25);
      expect(
        large.connectionBannerHeight,
        compact.connectionBannerHeight * 1.25,
      );
      expect(
        large.rightButtonsHeight(hasAdd: true, hasEffects: true),
        compact.rightButtonsHeight(hasAdd: true, hasEffects: true) * 1.25,
      );
    });

    test('a non-positive scale is rejected', () {
      expect(() => CallDimensions(scale: 0), throwsA(isA<AssertionError>()));
      expect(() => CallDimensions(scale: -1), throwsA(isA<AssertionError>()));
    });
  });

  group('CallDimensions value semantics', () {
    test('equality is by value, so a rebuilt instance is not a change', () {
      expect(const CallDimensions(), const CallDimensions());
      expect(const CallDimensions().hashCode, const CallDimensions().hashCode);
      expect(const CallDimensions(), isNot(const CallDimensions(scale: 1.25)));
    });

    test('a differing token makes the whole object differ', () {
      const custom = CallDimensions(
        bottomBar: CallBottomBarDimensions(endCallButtonSize: 72),
      );

      expect(custom, isNot(const CallDimensions()));
      expect(custom, const CallDimensions(
        bottomBar: CallBottomBarDimensions(endCallButtonSize: 72),
      ));
    });

    test('token classes compare by value too', () {
      expect(
        const CallBottomBarDimensions(buttonSize: 56),
        const CallBottomBarDimensions(buttonSize: 56),
      );
      expect(
        const CallBottomBarDimensions(buttonSize: 56).hashCode,
        const CallBottomBarDimensions(buttonSize: 56).hashCode,
      );
      expect(
        const CallBottomBarDimensions(buttonSize: 56),
        isNot(const CallBottomBarDimensions()),
      );
    });

    test('copyWith replaces only what it is given', () {
      const base = CallDimensions();
      final scaled = base.copyWith(scale: 2);

      expect(scaled.scale, 2.0);
      expect(scaled.bottomBar, base.bottomBar);

      final wider = base.copyWith(
        bottomBar: base.bottomBar.copyWith(endCallButtonSize: 72),
      );
      expect(wider.bottomBar.endCallButtonSize, 72);
      expect(wider.bottomBar.buttonSize, base.bottomBar.buttonSize);
      expect(wider.scale, base.scale);
    });
  });

  group('CallDimensions presets', () {
    test('compact is the kit\'s original layout', () {
      expect(const CallDimensions.compact(), const CallDimensions());
    });

    test('comfortable enlarges the controls a host aims at in a hurry', () {
      const comfortable = CallDimensions.comfortable();

      expect(comfortable, isNot(const CallDimensions()));
      expect(comfortable.scale, greaterThan(1.0));
      expect(
        comfortable.bottomBar.endCallButtonSize,
        greaterThan(const CallDimensions().bottomBar.endCallButtonSize),
      );
      expect(
        comfortable.incoming.actionButtonSize,
        greaterThan(const CallDimensions().incoming.actionButtonSize),
      );
    });
  });

  group('scaled layout', () {
    testWidgets('the bottom bar lays out at the declared scaled height',
        (tester) async {
      // The PiP keeps clear of dimensions.bottomBarHeight. If the
      // declared height and the real metrics drift apart under a scale, the
      // PiP silently starts overlapping the bar.
      const dimensions = CallDimensions(scale: 1.25);

      await tester.pumpWidget(_app(
        Align(
          alignment: Alignment.bottomCenter,
          child: _bottomBar(dimensions),
        ),
      ));

      expect(
        tester.getSize(find.byType(CallBottomBar)).height,
        dimensions.bottomBarHeight,
      );
    });

    testWidgets('the end-call button grows with the scale', (tester) async {
      Future<Size> buttonSize(CallDimensions dimensions) async {
        await tester.pumpWidget(_app(
          Align(
            alignment: Alignment.bottomCenter,
            child: _bottomBar(dimensions),
          ),
        ));
        return tester.getSize(_endCallButton);
      }

      final compact = await buttonSize(const CallDimensions());
      final large = await buttonSize(const CallDimensions(scale: 1.25));

      expect(compact.width, 58);
      expect(large.width, 58 * 1.25);
    });

    testWidgets('the PiP clears the scaled top bar', (tester) async {
      // The one place a forgotten `dimensions:` pass-down would surface as a
      // wrong number rather than a compile error.
      const dimensions = CallDimensions(scale: 1.25);

      await tester.pumpWidget(_app(
        CallScreen(
          callerName: 'Sarah',
          dimensions: dimensions,
          localParticipant: const CallParticipant(
            id: 'local',
            displayName: 'Me',
            isLocalUser: true,
          ),
          localVideoWidget: const ColoredBox(color: Colors.blue),
          remoteVideoWidget: const ColoredBox(color: Colors.teal),
          onEndCall: () {},
          onToggleMute: () {},
          onToggleSpeaker: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.byType(FloatingPipView)).dy,
        dimensions.topBarHeight + dimensions.scaled(dimensions.pip.margin),
      );
    });
  });

  group('per-metric overrides', () {
    testWidgets('an overridden button size reaches the laid-out widget',
        (tester) async {
      await tester.pumpWidget(_app(
        Align(
          alignment: Alignment.bottomCenter,
          child: _bottomBar(const CallDimensions(
            bottomBar: CallBottomBarDimensions(endCallButtonSize: 72),
          )),
        ),
      ));

      expect(tester.getSize(_endCallButton).width, 72);
    });

    testWidgets('an override composes with the scale', (tester) async {
      await tester.pumpWidget(_app(
        Align(
          alignment: Alignment.bottomCenter,
          child: _bottomBar(const CallDimensions(
            scale: 1.25,
            bottomBar: CallBottomBarDimensions(endCallButtonSize: 72),
          )),
        ),
      ));

      expect(tester.getSize(_endCallButton).width, 72 * 1.25);
    });

    testWidgets('a bar the override does not name keeps its own size',
        (tester) async {
      await tester.pumpWidget(_app(
        Align(
          alignment: Alignment.bottomCenter,
          child: _bottomBar(const CallDimensions(
            bottomBar: CallBottomBarDimensions(endCallButtonSize: 72),
          )),
        ),
      ));

      final mute = tester.getSize(
        find
            .ancestor(
              of: find.byIcon(Icons.mic),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(mute.width, 50);
    });

    testWidgets('the derived bar height follows an overridden token',
        (tester) async {
      // bottomBarHeight is composed, not declared. An override of any part of
      // it has to move the laid-out bar by the same amount, or the PiP inset
      // and the bar disagree.
      const dimensions = CallDimensions(
        bottomBar: CallBottomBarDimensions(
          endCallButtonSize: 72,
          verticalPadding: 16,
        ),
      );

      expect(dimensions.bottomBarHeight, 20 + 16 * 2 + 72);

      await tester.pumpWidget(_app(
        Align(
          alignment: Alignment.bottomCenter,
          child: _bottomBar(dimensions),
        ),
      ));

      expect(
        tester.getSize(find.byType(CallBottomBar)).height,
        dimensions.bottomBarHeight,
      );
    });

    testWidgets('a resized PiP is laid out and anchored at its new size',
        (tester) async {
      const dimensions = CallDimensions(
        pip: CallPipDimensions(size: Size(120, 160)),
      );

      await tester.pumpWidget(_app(
        CallScreen(
          callerName: 'Sarah',
          dimensions: dimensions,
          localParticipant: const CallParticipant(
            id: 'local',
            displayName: 'Me',
            isLocalUser: true,
          ),
          localVideoWidget: const ColoredBox(color: Colors.blue),
          remoteVideoWidget: const ColoredBox(color: Colors.teal),
          onEndCall: () {},
          onToggleMute: () {},
          onToggleSpeaker: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(FloatingPipView)),
        const Size(120, 160),
      );
    });
  });
}
