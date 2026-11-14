import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/glossy_sprite.dart';

void main() {
  test('one-shot sprite indices clamp to real frame boundaries', () {
    expect(glossyFrameIndex(-1, 12), 0);
    expect(glossyFrameIndex(0, 12), 0);
    expect(glossyFrameIndex(0.49, 12), 5);
    expect(glossyFrameIndex(0.999, 12), 11);
    expect(glossyFrameIndex(1, 12), 11);
    expect(glossyFrameIndex(5, 12), 11);
    expect(glossyFrameIndex(double.nan, 12), 0);
  });

  testWidgets('Dog Recovering uses committed PNG frames with semantics',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlossySprite(
            spec: GlossySpriteSpec.dogRecovering,
            semanticLabel: 'Chó đang vươn vai',
            size: 96,
          ),
        ),
      ),
    );
    expect(find.byType(GlossySprite), findsOneWidget);
    expect(find.bySemanticsLabel('Chó đang vươn vai'), findsOneWidget);
    // One-shot playback stops after 12x130ms, so pumpAndSettle must finish.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('respects OS reduced-motion preference', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: GlossySprite(
              spec: GlossySpriteSpec.dogRecovering,
              semanticLabel: 'Chó đang nghỉ ngơi',
              size: 96,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GlossySprite), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
