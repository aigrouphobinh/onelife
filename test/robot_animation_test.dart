import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/robot_animation_gallery.dart';

void main() {
  test('Robot gallery is exactly 12 source-backed entries', () {
    expect(robotAnimationEntries.length, 12);
    final ids = robotAnimationEntries.map((e) => e.id).toSet();
    expect(ids.length, 12);
    expect(ids.contains('thinking'), isTrue);
    for (final item in robotAnimationEntries) {
      expect(
        item.sprite.assetPath,
        'assets/characters-v2/robot/${item.id}/sheet.png',
      );
      expect(item.sprite.frames, inInclusiveRange(8, 12));
      expect(item.sprite.columns, 4);
      expect(item.sprite.frameWidth, 256);
      expect(item.sprite.frameHeight, 256);
    }
    expect(ids.contains('sad'), isFalse);
    expect(ids.contains('balanced'), isFalse);
    expect(ids.contains('strained'), isFalse);
  });

  testWidgets(
    'Every bundled Robot atlas has genuine alpha and frame geometry',
    (tester) async {
      for (final item in robotAnimationEntries) {
        final spec = item.sprite;
        final bytes = await rootBundle.load(spec.assetPath);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        final image = (await codec.getNextFrame()).image;
        try {
          final expectedRows = (spec.frames + spec.columns - 1) ~/ spec.columns;
          expect(image.width, spec.frameWidth * spec.columns, reason: item.id);
          expect(
            image.height,
            spec.frameHeight * expectedRows,
            reason: item.id,
          );

          final rgba = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          expect(rgba, isNotNull, reason: item.id);
          final pixels = rgba!;
          final width = image.width;
          // Check the background inside every frame, not merely atlas corner.
          for (var frame = 0; frame < spec.frames; frame++) {
            final x = (frame % spec.columns) * spec.frameWidth + 1;
            final y = (frame ~/ spec.columns) * spec.frameHeight + 1;
            expect(
              pixels.getUint8((y * width + x) * 4 + 3),
              0,
              reason: '${item.id} frame $frame top-left alpha',
            );
          }
          // Sample a reasonably dense grid to confirm visible sprite art.
          var visible = 0;
          for (var y = 32; y < image.height; y += 64) {
            for (var x = 32; x < image.width; x += 64) {
              if (pixels.getUint8((y * width + x) * 4 + 3) > 40) visible++;
            }
          }
          expect(visible, greaterThan(0), reason: item.id);
        } finally {
          image.dispose();
          codec.dispose();
        }
      }
    },
  );
}
