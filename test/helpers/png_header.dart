import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Verify the packaged PNG header without decoding a full 4x3 atlas in the
/// Flutter software renderer. Pixel-level transparency and SHA checks belong
/// to Python/Pillow asset QA, not slow UI tests.
Future<void> expectRgbaSpriteHeader(
  String asset, {
  required int width,
  required int height,
}) async {
  final bytes = await rootBundle.load(asset);
  expect(bytes.lengthInBytes, greaterThan(33), reason: asset);
  const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  for (var i = 0; i < signature.length; i++) {
    expect(bytes.getUint8(i), signature[i], reason: '$asset PNG signature');
  }
  expect(bytes.getUint32(8, Endian.big), 13, reason: '$asset IHDR size');
  expect(bytes.getUint32(12, Endian.big), 0x49484452,
      reason: '$asset IHDR chunk');
  expect(bytes.getUint32(16, Endian.big), width, reason: '$asset width');
  expect(bytes.getUint32(20, Endian.big), height, reason: '$asset height');
  expect(bytes.getUint8(25), 6, reason: '$asset must be RGBA PNG');
}
