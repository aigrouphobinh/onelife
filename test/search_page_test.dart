import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/local_search.dart';
import 'package:onelife/src/note_repository.dart';
import 'package:onelife/src/onelife_store.dart';
import 'package:onelife/src/search_page.dart';

class ControlledSearch extends SearchSource {
  final pending = <String, Completer<List<SearchResult>>>{};
  final queries = <String>[];
  List<SearchResult> results = [];
  bool controlled = false;
  bool fail = false;
  @override
  Future<List<SearchResult>> search(String query) async {
    queries.add(query);
    if (fail) throw StateError('read failed');
    if (!controlled) return List.of(results);
    return (pending[query] = Completer<List<SearchResult>>()).future;
  }
}

const task = SearchResult.task(
    OneLifeTask(id: '1', title: 'Công việc gốc', completed: false));
const note = SearchResult.note(Note(
    id: '1',
    title: 'Ghi chú gốc',
    body: 'Nội dung',
    updatedAt: '2030-01-01T00:00:00Z'));

void main() {
  Future<void> mount(WidgetTester tester, ControlledSearch source,
      {Future<void> Function(OneLifeTask)? toggle,
      Future<void> Function(Note)? create}) async {
    await tester.pumpWidget(MaterialApp(
        home: SearchPage(
      source: source,
      onEditTask: (_) async {},
      onDeleteTask: (_) async {},
      onToggleTask: toggle ?? (_) async {},
      onEditNote: (_) async {},
      onDeleteNote: (_) async {},
      onCreateTask: create ?? (_) async {},
    )));
    await tester.pump();
  }

  testWidgets(
      'late search results cannot replace newer query, even during debounce',
      (tester) async {
    final source = ControlledSearch()..controlled = true;
    await mount(tester, source);
    await tester.enterText(find.byType(TextField), 'old');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'new');
    source.pending['old']!.complete([task]);
    await tester.pump();
    expect(find.text('Công việc gốc'), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    source.pending['new']!.complete([note]);
    await tester.pumpAndSettle();
    source.pending['']!.complete([task]);
    await tester.pumpAndSettle();
    expect(find.text('Ghi chú gốc'), findsOneWidget);
    expect(find.text('Công việc gốc'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('filters keep types distinct and actions refresh saved state',
      (tester) async {
    final source = ControlledSearch()..results = [task, note];
    var created = 0;
    await mount(tester, source, toggle: (_) async {
      source.results = [note];
    }, create: (value) async {
      expect(value.id, '1');
      created++;
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Công việc'));
    await tester.pumpAndSettle();
    expect(find.text('Ghi chú gốc'), findsNothing);
    await tester.tap(find.byTooltip('Thao tác kết quả'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoàn thành'));
    await tester.pumpAndSettle();
    expect(find.text('Không có kết quả phù hợp.'), findsOneWidget);
    await tester.tap(find.text('Ghi chú'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thao tác kết quả'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo việc từ ghi chú'));
    await tester.pumpAndSettle();
    expect(created, 1);
  });

  testWidgets('read failure retries, clear resets query, resume rereads data',
      (tester) async {
    final source = ControlledSearch()..fail = true;
    await mount(tester, source);
    await tester.pumpAndSettle();
    expect(find.text('Không có kết quả phù hợp.'), findsNothing);
    source.fail = false;
    source.results = [task];
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'word');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xóa từ khóa'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(source.queries.last, '');
    source.results = [];
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Công việc gốc'), findsNothing);
  });
}
