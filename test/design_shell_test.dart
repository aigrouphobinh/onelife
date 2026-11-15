import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
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

  testWidgets('Today filter and native QS agree on local midnight', (
    tester,
  ) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final fake = FakeOneLifeStore();
    fake.items.addAll([
      OneLifeTask(
        id: 'before',
        title: 'Trước nửa đêm',
        completed: false,
        dueAt: tomorrow.subtract(const Duration(seconds: 1)),
      ),
      OneLifeTask(
        id: 'at',
        title: 'Đúng nửa đêm',
        completed: false,
        dueAt: tomorrow,
      ),
    ]);

    await tester.pumpWidget(MaterialApp(home: OneLifeDesignShell(store: fake)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Việc cần làm'));
    await tester.pump();

    expect(find.text('Trước nửa đêm'), findsOneWidget);
    expect(find.text('Đúng nửa đêm'), findsNothing);
    await tester.tap(find.text('Sắp tới'));
    await tester.pump();
    expect(find.text('Đúng nửa đêm'), findsOneWidget);
    expect(find.text('Trước nửa đêm'), findsNothing);
  });

  testWidgets('Android Quick Capture intent saves a real local task', (
    tester,
  ) async {
    const captureChannel = MethodChannel('onelife/quick_capture');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(captureChannel, (call) async {
      if (call.method == 'consumeLaunchAction') return 'capture';
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(captureChannel, null);
    });

    final fake = FakeOneLifeStore();
    await tester.pumpWidget(MaterialApp(home: OneLifeDesignShell(store: fake)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Thêm việc mới'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Việc ghi nhanh');
    await tester.pump();
    await tester.tap(find.text('Lưu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(fake.items.single.title, 'Việc ghi nhanh');
    expect(fake.items.single.completed, false);
  });

  testWidgets('Android Today Tasks cold launch opens real local task list', (
    tester,
  ) async {
    const channel = MethodChannel('onelife/quick_capture');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'consumeLaunchAction') return 'tasks';
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
    });

    final fake = FakeOneLifeStore();
    fake.items.add(
      const OneLifeTask(
        id: 'today-1',
        title: 'Việc chưa hoàn thành',
        completed: false,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: OneLifeDesignShell(store: fake)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Danh sách (1)'), findsOneWidget);
    expect(find.text('Việc chưa hoàn thành'), findsOneWidget);
    expect(find.text('Việc cần làm'), findsWidgets);
    expect(find.text('Thêm việc mới'), findsNothing);
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

  testWidgets('V3.4 setup asks Android for the official Focus tile', (
    tester,
  ) async {
    const channel = MethodChannel('onelife/quick_capture');
    final messenger = tester.binding.defaultBinaryMessenger;
    final requests = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'requestAddTile') {
        final args = call.arguments as Map<dynamic, dynamic>;
        requests.add(args['tile'] as String);
        return 'added';
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
    });

    final fake = FakeOneLifeStore();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: OneLifeDesignShell(store: fake),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Tôi'));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Điều khiển nhanh Android'),
      140,
      scrollable: find.byType(Scrollable).last,
    );
    // On the 600px widget-test viewport this tile is initially covered by
    // the bottom NavigationBar. Scroll it into the tappable content region.
    await tester.drag(
      find.byType(Scrollable).last,
      const Offset(0, -260),
    );
    await tester.pump();
    await tester.tap(find.text('Điều khiển nhanh Android'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Tập trung · 25 phút'), findsOneWidget);

    // Match the OS-tile setup button, not the 'Thêm' bottom navigation
    // destination retained below this route in the Navigator.
    final focusAddButton = find.widgetWithText(OutlinedButton, 'Thêm').first;
    await tester.ensureVisible(focusAddButton);
    await tester.pump();
    await tester.tap(focusAddButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(requests, ['focus']);
    final todayAddButton = find.widgetWithText(OutlinedButton, 'Thêm').at(1);
    await tester.ensureVisible(todayAddButton);
    await tester.pump();
    await tester.tap(todayAddButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(requests, ['focus', 'today']);
  });
}
