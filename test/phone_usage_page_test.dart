import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/phone_usage_page.dart';

void main() {
  const bridge = MethodChannel('onelife/quick_capture');

  testWidgets('no Android usage permission never invents screen-time minutes', (
    tester,
  ) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    var opened = 0;
    messenger.setMockMethodCallHandler(bridge, (call) async {
      if (call.method == 'usageSnapshot') {
        return <String, Object?>{
          'granted': false,
          'available': false,
          'minutes': null,
          'tier': 'unknown',
        };
      }
      if (call.method == 'openUsageAccessSettings') {
        opened++;
        return 'opened';
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(bridge, null));

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const PhoneUsagePage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Mở Cài đặt quyền sử dụng'), findsOneWidget);
    expect(find.textContaining('0 giờ'), findsNothing);
    expect(opened, 0);

    await tester.tap(find.text('Mở Cài đặt quyền sử dụng'));
    await tester.pump();
    expect(opened, 1);
    // Opening system Settings is only a request, not a granted permission.
    expect(find.text('Mở Cài đặt quyền sử dụng'), findsOneWidget);
  });

  testWidgets('foreground evidence is displayed with explicit approximate tier',
      (
    tester,
  ) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(bridge, (call) async {
      if (call.method == 'usageSnapshot') {
        return <String, Object?>{
          'granted': true,
          'available': true,
          'minutes': 205,
          'goalMinutes': 180,
          'tier': 'overloaded',
        };
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(bridge, null));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const PhoneUsagePage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('3 giờ 25 phút'), findsOneWidget);
    expect(
        find.text('Đã đạt mục tiêu bạn chọn — cân nhắc nghỉ'), findsOneWidget);
    expect(find.text('Mở Cài đặt quyền sử dụng'), findsNothing);
  });

  testWidgets('personal goal is absent by default and removable on device', (
    tester,
  ) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    int? chosen;
    var saveCount = 0;
    messenger.setMockMethodCallHandler(bridge, (call) async {
      if (call.method == 'usageSnapshot') {
        return <String, Object?>{
          'granted': true,
          'available': true,
          'minutes': 100,
          'goalMinutes': chosen,
          'tier': chosen == null
              ? 'unknown'
              : (100 >= chosen! ? 'overloaded' : 'balanced'),
        };
      }
      if (call.method == 'setUsageDailyGoal') {
        saveCount++;
        chosen = (call.arguments as Map)['minutes'] as int?;
        return true;
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(bridge, null));

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const PhoneUsagePage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('Chưa đặt mục tiêu riêng'), findsOneWidget);
    expect(saveCount, 0);
    await tester.ensureVisible(find.text('2 giờ'));
    await tester.pump(); // apply the ListView scroll offset before hit testing
    await tester.tap(find.text('2 giờ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(chosen, 120);
    expect(find.text('Tắt mục tiêu'), findsOneWidget);
    await tester.ensureVisible(find.text('Tắt mục tiêu'));
    await tester.pump();
    await tester.tap(find.text('Tắt mục tiêu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(chosen, isNull);
    expect(saveCount, 2);
    // The no-goal explanation sits above the goal chooser in the scrolled
    // ListView; return to that region before checking its rendered copy.
    await tester.drag(find.byType(Scrollable).last, const Offset(0, 750));
    await tester.pump();
    expect(find.textContaining('Chưa đặt mục tiêu riêng'), findsOneWidget);
  });

  testWidgets('permission granted but no events shows unknown, not zero', (
    tester,
  ) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(bridge, (call) async {
      if (call.method == 'usageSnapshot') {
        return <String, Object?>{
          'granted': true,
          'available': false,
          'minutes': null,
          'tier': 'unknown',
        };
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(bridge, null));

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: const PhoneUsagePage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('Thiếu dữ liệu không có nghĩa'), findsOneWidget);
    expect(find.text('Dưới 1 phút quan sát được'), findsNothing);
  });

  testWidgets('iOS does not call unsupported Android usage service', (
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
      home: const PhoneUsagePage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.textContaining('iOS yêu cầu tích hợp Screen Time'),
        findsOneWidget);
    expect(nativeCalls, 0);
  });
}
