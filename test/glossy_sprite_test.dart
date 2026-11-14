import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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
    final semantics = tester.ensureSemantics();
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
    semantics.dispose();
  });

  testWidgets('Dog Recovering and Focus PNG atlases keep true alpha',
      (tester) async {
    for (final spec in [
      GlossySpriteSpec.dogRecovering,
      GlossySpriteSpec.dogFocus,
    ]) {
      final bytes = await rootBundle.load(spec.assetPath);
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final image = (await codec.getNextFrame()).image;
      expect(image.width, 1024);
      expect(image.height, 768);
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(rgba, isNotNull);
      // Four bytes per pixel: first atlas pixel is fully transparent.
      expect(rgba!.getUint8(3), 0, reason: spec.assetPath);
      // The first illustrated cell has opaque art near its center.
      final centerAlphaOffset = (128 * image.width + 128) * 4 + 3;
      expect(rgba.getUint8(centerAlphaOffset), greaterThan(20),
          reason: spec.assetPath);
      image.dispose();
      codec.dispose();
    }
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
