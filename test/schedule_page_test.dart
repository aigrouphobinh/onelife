import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/onelife_store.dart';
import 'package:onelife/src/schedule_page.dart';

import 'task_management_test.dart' show MemoryTasks;

class ScheduleStore extends MemoryTasks {
  bool fail = false;

  @override
  Future<List<OneLifeTask>> loadTasks() async {
    if (fail) throw StateError('offline database unavailable');
    return super.loadTasks();
  }
}

void main() {
  final now = DateTime(2030, 1, 2, 12);
  OneLifeTask task(String id, DateTime? due, {bool completed = false}) =>
      OneLifeTask(id: id, title: id, completed: completed, dueAt: due);

  Future<void> mount(WidgetTester tester, ScheduleStore store) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SchedulePage(
          store: store,
          now: () => now,
          onAdd: () async {},
          onEdit: (task) => store.updateTask(task.id, title: 'Đã sửa'),
          onDelete: (task) => store.deleteTask(task.id),
          onComplete: (task) => store.setTaskCompleted(task.id, true),
          onReminderSettings: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('local day boundaries, overdue and unscheduled exclusions', (
    tester,
  ) async {
    final store = ScheduleStore();
    store.items
      ..clear()
      ..addAll([
        task('yesterday', DateTime(2030, 1, 1, 23, 59)),
        task('midnight', DateTime(2030, 1, 2)),
        task('tonight', DateTime(2030, 1, 2, 23, 59)),
        task('tomorrow', DateTime(2030, 1, 3)),
        task('no-date', null),
        task('finished', now, completed: true),
      ]);
    await mount(tester, store);
    expect(find.text('midnight'), findsOneWidget);
    expect(find.text('tonight'), findsOneWidget);
    expect(find.text('yesterday'), findsNothing);
    expect(find.text('tomorrow'), findsNothing);
    expect(find.text('no-date'), findsNothing);
    expect(find.text('finished'), findsNothing);

    await tester.tap(find.text('Quá hạn'));
    await tester.pumpAndSettle();
    expect(find.text('yesterday'), findsOneWidget);
    expect(find.text('midnight'), findsOneWidget);
    expect(find.text('tonight'), findsNothing);

    await tester.tap(find.text('Tất cả'));
    await tester.pumpAndSettle();
    expect(find.text('tomorrow'), findsOneWidget);
    expect(find.text('no-date'), findsNothing);
    expect(find.text('finished'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('date picker selects a day and cancellation preserves it',
      (tester) async {
    final store = ScheduleStore();
    store.items
      ..clear()
      ..addAll([
        task('today-task', now),
        task('selected-day-task', DateTime(2030, 1, 3, 9)),
      ]);
    await mount(tester, store);
    await tester.tap(find.text('Chọn ngày'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('03/01/2030'), findsOneWidget);
    expect(find.text('selected-day-task'), findsOneWidget);
    expect(find.text('today-task'), findsNothing);
    await tester.tap(find.text('03/01/2030'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('selected-day-task'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('completion and clearing a deadline refresh the visible agenda', (
    tester,
  ) async {
    final store = ScheduleStore();
    store.items
      ..clear()
      ..addAll([task('first', now), task('second', now)]);
    await mount(tester, store);
    await tester.tap(find.byTooltip('Thao tác lịch').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoàn thành'));
    await tester.pumpAndSettle();
    expect(store.items.first.completed, isTrue);
    expect(find.text('first'), findsNothing);
    await tester.tap(find.text('second'));
    await tester.pumpAndSettle();
    expect(store.items.last.dueAt, isNull);
    expect(find.text('Không có công việc trong khoảng này.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('failed load offers retry and resume reads native changes', (
    tester,
  ) async {
    final store = ScheduleStore()..fail = true;
    store.items
      ..clear()
      ..add(task('native-task', now));
    await mount(tester, store);
    expect(find.text('Không tải được lịch. Hãy thử lại.'), findsOneWidget);
    store.fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('native-task'), findsOneWidget);
    store.items.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('native-task'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
