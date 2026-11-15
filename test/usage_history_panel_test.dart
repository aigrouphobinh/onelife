import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/usage_history_panel.dart';

void main() {
  const channel = MethodChannel('onelife/quick_capture');

  Widget app({TargetPlatform platform = TargetPlatform.android}) => MaterialApp(
        theme: ThemeData(platform: platform),
        home: const Scaffold(body: UsageHistoryPanel()),
      );

  testWidgets('permission denied never manufactures screen-use minutes', (
    tester,
  ) async {
    var readCount = 0;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'usageHistory') {
        readCount++;
        return <String, Object?>{
          'granted': false,
          'available': false,
          'days': <Object>[],
        };
      }
      return 'opened';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(readCount, 1);
    expect(find.text('Mở Cài đặt quyền sử dụng'), findsOneWidget);
    expect(find.textContaining('3 giờ'), findsNothing);
  });

  testWidgets('1/7/30 days requests only selected Android periods', (
    tester,
  ) async {
    final periods = <int>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'usageHistory') return null;
      final period = (call.arguments as Map)['days'] as int;
      periods.add(period);
      return <String, Object?>{
        'granted': true,
        'available': true,
        'days': <Map<String, Object?>>[
          {'date': '2026-11-14', 'minutes': null},
          {'date': '2026-11-15', 'minutes': 205},
        ],
      };
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('3 giờ 25 phút'), findsWidgets);
    expect(find.text('Chưa có dữ liệu'), findsWidgets);
    expect(periods, [1]);

    await tester.tap(find.text('7 ngày'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(periods, [1, 7]);
    expect(find.textContaining('1/7 ngày có dữ liệu'), findsOneWidget);

    await tester.tap(find.text('30 ngày'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(periods, [1, 7, 30]);
    expect(find.textContaining('1/30 ngày có dữ liệu'), findsOneWidget);
    // The missing day is not counted in the observed total or average.
    expect(
        find.text('Trung bình ngày có dữ liệu: 3 giờ 25 phút'), findsOneWidget);
  });

  testWidgets('granted but empty events reports unknown, not zero', (
    tester,
  ) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        channel,
        (call) async => {
              'granted': true,
              'available': false,
              'days': <Map<String, Object?>>[
                {'date': '2026-11-15', 'minutes': null},
              ],
            });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('Không có dữ liệu không đồng nghĩa 0 phút'),
        findsOneWidget);
    expect(find.text('0 giờ 0 phút'), findsNothing);
  });

  testWidgets('late results cannot overwrite a newer selected period', (
    tester,
  ) async {
    final first = Completer<Map<String, Object?>>();
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'usageHistory') return null;
      final period = (call.arguments as Map)['days'] as int;
      if (period == 1) return first.future;
      return <String, Object?>{
        'granted': true,
        'available': true,
        'days': <Map<String, Object?>>[
          {'date': '2026-11-15', 'minutes': 70},
        ],
      };
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.tap(find.text('7 ngày'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(find.text('1 giờ 10 phút'), findsWidgets);

    first.complete(<String, Object?>{
      'granted': true,
      'available': true,
      'days': <Map<String, Object?>>[
        {'date': '2026-11-15', 'minutes': 12},
      ],
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(find.text('1 giờ 10 phút'), findsWidgets);
    expect(find.text('12 phút'), findsNothing);
  });

  testWidgets('iOS does not invoke unsupported Android UsageEvents', (
    tester,
  ) async {
    var nativeCalls = 0;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async {
      nativeCalls++;
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(app(platform: TargetPlatform.iOS));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('iOS cần tích hợp Screen Time'), findsOneWidget);
    expect(nativeCalls, 0);
  });
}
