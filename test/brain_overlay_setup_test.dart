import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/brain_overlay_setup_page.dart';

void main() {
  const bridge = MethodChannel('onelife/quick_capture');

  testWidgets(
      'Brain overlay never requests special permission or starts itself', (
    tester,
  ) async {
    final binary = tester.binding.defaultBinaryMessenger;
    var starts = 0;
    var permissionOpens = 0;
    binary.setMockMethodCallHandler(bridge, (call) async {
      if (call.method == 'overlayStatus') {
        return <String, Object>{
          'supported': true,
          'permissionGranted': false,
          'running': false,
        };
      }
      if (call.method == 'requestOverlayPermission') {
        permissionOpens++;
        return 'opened'; // Opening Settings is not granting permission.
      }
      if (call.method == 'startBrainOverlay') {
        starts++;
        return 'permission_required';
      }
      return null;
    });
    addTearDown(() => binary.setMockMethodCallHandler(bridge, null));

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const BrainOverlaySetupPage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(starts, 0);
    expect(permissionOpens, 0);
    expect(find.text('Mở cài đặt cấp quyền'), findsOneWidget);
    expect(find.text('Hiện Brain nổi'), findsNothing);

    await tester.tap(find.text('Mở cài đặt cấp quyền'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(permissionOpens, 1);
    expect(starts, 0);
    expect(find.text('Mở cài đặt cấp quyền'), findsOneWidget);
  });

  testWidgets('Brain overlay only starts and stops on visible button taps', (
    tester,
  ) async {
    final binary = tester.binding.defaultBinaryMessenger;
    var running = false;
    var startCalls = 0;
    var stopCalls = 0;
    binary.setMockMethodCallHandler(bridge, (call) async {
      if (call.method == 'overlayStatus') {
        return <String, Object>{
          'supported': true,
          'permissionGranted': true,
          'running': running,
        };
      }
      if (call.method == 'startBrainOverlay') {
        startCalls++;
        running = true;
        return 'requested';
      }
      if (call.method == 'stopBrainOverlay') {
        stopCalls++;
        running = false;
        return 'requested';
      }
      return null;
    });
    addTearDown(() => binary.setMockMethodCallHandler(bridge, null));

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const BrainOverlaySetupPage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(startCalls, 0);
    expect(find.text('Hiện Brain nổi'), findsOneWidget);

    await tester.tap(find.text('Hiện Brain nổi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(startCalls, 1);
    expect(find.text('Ẩn Brain nổi'), findsOneWidget);

    await tester.tap(find.text('Ẩn Brain nổi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(stopCalls, 1);
    expect(find.text('Hiện Brain nổi'), findsOneWidget);
  });

  testWidgets('iOS does not offer a fake floating system overlay', (
    tester,
  ) async {
    final binary = tester.binding.defaultBinaryMessenger;
    var touchedNative = false;
    binary.setMockMethodCallHandler(bridge, (call) async {
      touchedNative = true;
      return null;
    });
    addTearDown(() => binary.setMockMethodCallHandler(bridge, null));

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      home: const BrainOverlaySetupPage(),
    ));
    await tester.pump();
    expect(touchedNative, isFalse);
    expect(find.text('Hiện Brain nổi'), findsNothing);
    expect(find.textContaining('iOS không cho phép'), findsOneWidget);
  });
}
