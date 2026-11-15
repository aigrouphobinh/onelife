import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/design_shell.dart';
import 'package:onelife/src/onelife_store.dart';

class MemoryTasks implements OneLifeStore {
  final items = <OneLifeTask>[
    OneLifeTask(
      id: 'task-1',
      title: 'Việc ban đầu',
      completed: false,
      dueAt: DateTime(2030, 1, 1, 9),
    ),
  ];

  @override
  Future<List<OneLifeTask>> loadTasks() async => List.of(items);

  @override
  Future<void> addTask({required String title, DateTime? dueAt}) async {
    items.add(OneLifeTask(
      id: 'task-new',
      title: title,
      completed: false,
      dueAt: dueAt,
    ));
  }

  @override
  Future<void> setTaskCompleted(String id, bool completed) async {
    final index = items.indexWhere((task) => task.id == id);
    final old = items[index];
    items[index] = OneLifeTask(
      id: old.id,
      title: old.title,
      completed: completed,
      dueAt: old.dueAt,
    );
  }

  @override
  Future<void> updateTask(
    String id, {
    required String title,
    DateTime? dueAt,
  }) async {
    final index = items.indexWhere((task) => task.id == id);
    final old = items[index];
    items[index] = OneLifeTask(
      id: old.id,
      title: title.trim(),
      completed: old.completed,
      dueAt: dueAt,
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    items.removeWhere((task) => task.id == id);
  }

  @override
  Future<String> selectedCharacter() async => 'brain';

  @override
  Future<void> selectCharacter(String id) async {}
}

void main() {
  testWidgets('edit task title, clear due date and confirm deletion', (
    tester,
  ) async {
    final store = MemoryTasks();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: OneLifeDesignShell(store: store),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Việc cần làm').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tùy chọn công việc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa công việc'));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ lịch hẹn'), findsOneWidget);
    await tester.tap(find.text('Bỏ lịch hẹn'));
    await tester.enterText(find.byType(TextFormField), 'Việc đã đổi');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(store.items.single.title, 'Việc đã đổi');
    expect(store.items.single.dueAt, isNull);

    await tester.tap(find.byTooltip('Tùy chọn công việc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa công việc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(store.items, hasLength(1));

    await tester.tap(find.byTooltip('Tùy chọn công việc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa công việc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(store.items, isEmpty);
    expect(find.text('Chưa có công việc trong mục này.'), findsOneWidget);
  });
}
