import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/robot_animation_gallery.dart';

import 'helpers/png_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  test('All 12 Robot atlases bundle valid RGBA PNG geometry', () async {
    // Full-pixel checks are performed by tools/check_runtime_sprite_alpha.py
    // on GitHub's Asset QA workflow; avoid 12 huge UI decoder allocations.
    for (final entry in robotAnimationEntries) {
      final spec = entry.sprite;
      await expectRgbaSpriteHeader(
        spec.assetPath,
        width: spec.frameWidth * spec.columns,
        height: spec.frameHeight * ((spec.frames + spec.columns - 1) ~/ spec.columns),
      );
    }
  });
}
