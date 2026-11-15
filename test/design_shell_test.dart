import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/design_shell.dart';
import 'package:onelife/src/onelife_store.dart';

class FakeOneLifeStore implements OneLifeStore {
  final items = <OneLifeTask>[];
  String character = 'brain';

  @override
  Future<List<OneLifeTask>> loadTasks() async => List.of(items);

  @override
  Future<void> addTask({required String title, DateTime? dueAt}) async {
    items.add(
      OneLifeTask(
        id: (items.length + 1).toString(),
        title: title,
        dueAt: dueAt,
        completed: false,
      ),
    );
  }

  @override
  Future<void> setTaskCompleted(String id, bool completed) async {
    final index = items.indexWhere((task) => task.id == id);
    if (index < 0) throw StateError('Missing fake task');
    final previous = items[index];
    items[index] = OneLifeTask(
      id: id,
      title: previous.title,
      dueAt: previous.dueAt,
      completed: completed,
    );
  }

  @override
  Future<String> selectedCharacter() async => character;

  @override
  Future<void> selectCharacter(String id) async {
    character = id;
  }
}

void main() {
  testWidgets('V2 home uses Brain, local data and honest usage empty state', (
    tester,
  ) async {
    final fake = FakeOneLifeStore();
    await tester.pumpWidget(MaterialApp(home: OneLifeDesignShell(store: fake)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Chào bạn 👋'), findsOneWidget);
    expect(
      find.textContaining('Chưa có dữ liệu thời gian sử dụng'),
      findsOneWidget,
    );
    expect(find.text('4 giờ 20 phút'), findsNothing);
    expect(find.text('Việc cần làm'), findsOneWidget);
  });

  testWidgets('V2 tasks tab supports real completion instead of mock data', (
    tester,
  ) async {
    final fake = FakeOneLifeStore();
    fake.items.add(
      const OneLifeTask(
        id: 'one',
        title: 'Kiểm tra giao diện',
        completed: false,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: OneLifeDesignShell(store: fake)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Việc cần làm'));
    await tester.pump();
    expect(find.text('Kiểm tra giao diện'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(fake.items.single.completed, isTrue);
  });

  testWidgets('V2 settings opens five real mascot options', (tester) async {
    final fake = FakeOneLifeStore();
    await tester.pumpWidget(MaterialApp(home: OneLifeDesignShell(store: fake)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Tôi'));
    await tester.pump();
    expect(find.text('Nhân vật trợ lý'), findsOneWidget);
    await tester.tap(find.text('Bộ Não').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Chọn nhân vật'), findsOneWidget);
    // The five character options live in a lazily built ListView; scroll
    // rather than asserting an offscreen item is immediately rendered.
    await tester.scrollUntilVisible(
      find.text('Mầm Xanh'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Mầm Xanh'), findsOneWidget);
    await tester.tap(find.text('Mầm Xanh'));
    await tester.pump();
    expect(fake.character, 'sprout');
  });
}
