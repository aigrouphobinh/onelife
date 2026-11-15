import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/local_search.dart';
import 'package:onelife/src/note_repository.dart';
import 'package:onelife/src/onelife_store.dart';

import 'task_management_test.dart' show MemoryTasks;

class SearchNotes extends NoteRepository {
  List<Note> items = [];
  @override
  Future<List<Note>> search(String query) async => List.of(items);
}

void main() {
  test('Vietnamese accents, combining marks, whitespace and case normalize',
      () {
    expect(normalizeSearch('  ĐẶT  LỊCH\nHỌP '), 'dat lich hop');
    expect(normalizeSearch('Ghi chu\u0301'), 'ghi chu');
  });

  test('search matches note bodies and all words; symbols stay literal',
      () async {
    final store = MemoryTasks();
    store.items
      ..clear()
      ..add(const OneLifeTask(
          id: 'shared', title: 'Đặt lịch họp', completed: true));
    final notes = SearchNotes()
      ..items = [
        const Note(
            id: 'shared',
            title: 'Ghi chú',
            body: 'LỊCH họp có mã 50%_x',
            updatedAt: '2030-01-01T00:00:00Z'),
      ];
    final search = LocalSearch(store: store, notes: notes);
    final matches = await search.search('hop lich');
    expect(matches.map((r) => r.key), ['task:shared', 'note:shared']);
    expect(matches.first.task!.completed, true);
    expect((await search.search('50%_x')).single.note!.id, 'shared');
    expect(await search.search('%missing'), isEmpty);
    expect(await search.search('hop nowhere'), isEmpty);
    notes.items.clear();
    expect(await search.search('ghi chu'), isEmpty);
  });

  test('task order puts unfinished deadlines first and refresh sees edits',
      () async {
    final store = MemoryTasks();
    store.items
      ..clear()
      ..addAll([
        const OneLifeTask(id: 'done', title: 'Done', completed: true),
        const OneLifeTask(id: 'undated', title: 'Undated', completed: false),
        OneLifeTask(
            id: 'due', title: 'Due', completed: false, dueAt: DateTime(2030)),
      ]);
    final search = LocalSearch(store: store, notes: SearchNotes());
    expect((await search.search('')).map((r) => r.task!.id),
        ['due', 'undated', 'done']);
    await store.updateTask('due', title: 'Đã đổi');
    expect(await search.search('Due'), isEmpty);
    expect((await search.search('da doi')).single.task!.id, 'due');
  });
}
