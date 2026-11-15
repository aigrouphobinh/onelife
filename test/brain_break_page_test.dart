import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/brain_break_page.dart';

void main() {
  const bridge = MethodChannel('onelife/quick_capture');

  Map<String, Object?> state(
    String phase, {
    int sequence = 1,
    int duration = 5,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return <String, Object?>{
      'phase': phase,
      'sequence': sequence,
      'durationMinutes': phase == 'idle' ? 0 : duration,
      'remainingSeconds': phase == 'resting' ? duration * 60 : 0,
      'deadlineMs': phase == 'resting' ? now + duration * 60000 : 0,
      'recoveryStartMs': phase == 'recovering' ? now : 0,
      'recoveryDurationMs': 1500,
    };
  }

  testWidgets(
      'break timer is idle until explicitly started and not Usage Access gated',
      (
    tester,
  ) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    var starts = 0;
    var permissionReads = 0;
    messenger.setMockMethodCallHandler(bridge, (call) async {
      if (call.method == 'breakSnapshot') return state('idle');
      if (call.method == 'startBrainBreak') {
        starts++;
        expect((call.arguments as Map)['minutes'], 10);
        return state('resting', duration: 10);
      }
      if (call.method == 'usageSnapshot' ||
          call.method == 'openUsageAccessSettings') {
        permissionReads++;
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(bridge, null));

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const BrainBreakPage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(starts, 0);
    expect(permissionReads, 0);
    expect(find.text('Bắt đầu nghỉ 5 phút'), findsOneWidget);

    await tester.ensureVisible(find.text('10 phút'));
    await tester.tap(find.text('10 phút'));
    await tester.pump();
    await tester.ensureVisible(find.text('Bắt đầu nghỉ 10 phút'));
    await tester.tap(find.text('Bắt đầu nghỉ 10 phút'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(starts, 1);
    expect(permissionReads, 0);
    expect(find.text('Brain đang thư giãn'), findsOneWidget);
    expect(find.text('Kết thúc nghỉ'), findsOneWidget);
  });

  testWidgets('finishing an active rest shows Recovering one-shot, not cancel',
      (
    tester,
  ) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    var finishCalls = 0;
    var cancelCalls = 0;
    messenger.setMockMethodCallHandler(bridge, (call) async {
      if (call.method == 'breakSnapshot') return state('resting');
      if (call.method == 'finishBrainBreak') {
        finishCalls++;
        return state('recovering');
      }
      if (call.method == 'cancelBrainBreak') {
        cancelCalls++;
        return state('idle');
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(bridge, null));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const BrainBreakPage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    await tester.ensureVisible(find.text('Kết thúc nghỉ'));
    await tester.tap(find.text('Kết thúc nghỉ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(finishCalls, 1);
    expect(cancelCalls, 0);
    expect(find.text('Nghỉ xong — trở lại nhịp của bạn'), findsOneWidget);
    expect(find.text('Hoạt ảnh Recovering phát đúng một lần.'), findsOneWidget);
  });

  testWidgets('cancelling rest never plays completion animation', (
    tester,
  ) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    var finishCalls = 0;
    var cancelCalls = 0;
    messenger.setMockMethodCallHandler(bridge, (call) async {
      if (call.method == 'breakSnapshot') return state('resting');
      if (call.method == 'finishBrainBreak') {
        finishCalls++;
        return state('recovering');
      }
      if (call.method == 'cancelBrainBreak') {
        cancelCalls++;
        return state('idle');
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(bridge, null));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const BrainBreakPage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    await tester.ensureVisible(find.text('Hủy phiên nghỉ'));
    await tester.tap(find.text('Hủy phiên nghỉ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(cancelCalls, 1);
    expect(finishCalls, 0);
    expect(find.text('Bắt đầu nghỉ 5 phút'), findsOneWidget);
    expect(find.text('Nghỉ xong — trở lại nhịp của bạn'), findsNothing);
  });

  testWidgets(
      'iOS does not invoke Android break service or show start controls', (
    tester,
  ) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    var nativeCalls = 0;
    messenger.setMockMethodCallHandler(bridge, (call) async {
      nativeCalls++;
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(bridge, null));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      home: const BrainBreakPage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 130));
    expect(nativeCalls, 0);
    expect(find.text('Bắt đầu nghỉ 5 phút'), findsNothing);
    expect(find.textContaining('iOS chưa được tích hợp'), findsOneWidget);
  });

  testWidgets('a late native snapshot never replaces a newer user action',
      (tester) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    final oldSnapshot = Completer<Map<String, Object?>>();
    var reads = 0;
    var starts = 0;
    messenger.setMockMethodCallHandler(bridge, (call) async {
      if (call.method == 'breakSnapshot') {
        reads++;
        return reads == 1 ? state('idle') : oldSnapshot.future;
      }
      if (call.method == 'startBrainBreak') {
        starts++;
        return state('resting');
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(bridge, null));

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const BrainBreakPage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('Bắt đầu nghỉ 5 phút'), findsOneWidget);

    // A real inactive-to-resumed transition initiates a pending snapshot.
    // This is deterministic even if the test binding starts already resumed.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(reads, 2);

    await tester.ensureVisible(find.text('Bắt đầu nghỉ 5 phút'));
    await tester.pump();
    await tester.tap(find.text('Bắt đầu nghỉ 5 phút'));
    await tester.pump();
    expect(starts, 1);
    expect(find.text('Brain đang thư giãn'), findsOneWidget);

    // The earlier idle read must not roll back the confirmed rest action.
    oldSnapshot.complete(state('idle'));
    await tester.pump();
    expect(find.text('Brain đang thư giãn'), findsOneWidget);
    expect(find.text('Kết thúc nghỉ'), findsOneWidget);
  });

  testWidgets('an empty native response exits loading with a real error',
      (tester) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(bridge, (call) async => null);
    addTearDown(() => messenger.setMockMethodCallHandler(bridge, null));

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const BrainBreakPage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Android chưa trả trạng thái phiên nghỉ.'),
        findsOneWidget);
    expect(find.text('Bắt đầu nghỉ 5 phút'), findsNothing);
  });
  testWidgets(
      'native elapsed remaining takes precedence over user-edited phone clock',
      (tester) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(bridge, (call) async {
      if (call.method == 'breakSnapshot') {
        return <String, Object?>{
          ...state('resting'),
          // Simulate a phone clock changed by one hour. The native
          // monotonic duration must win; do not declare a false expiry.
          'deadlineMs': DateTime.now()
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch,
          'remainingMs': 90000,
        };
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(bridge, null));

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const BrainBreakPage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('01:30'), findsOneWidget);
    expect(find.text('Brain đang thư giãn'), findsOneWidget);
    expect(find.text('Nghỉ xong — trở lại nhịp của bạn'), findsNothing);
  });

}
