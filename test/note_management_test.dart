import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/home_page.dart';
import 'package:onelife/src/note_repository.dart';

class MemoryNotes extends NoteRepository {
  Note? current = const Note(
    id: 'note-1',
    title: 'Ghi chú ban đầu',
    body: 'Nội dung quan trọng',
    updatedAt: '2026-11-15T00:00:00Z',
  );

  @override
  Future<List<Note>> search(String query) async {
    final note = current;
    if (note == null) return [];
    if (query.isEmpty ||
        note.title.contains(query) ||
        note.body.contains(query)) {
      return [note];
    }
    return [];
  }

  @override
  Future<void> update({
    required String id,
    required String title,
    required String body,
  }) async {
    if (id != current?.id) throw StateError('Missing note');
    current = Note(
      id: id,
      title: title.trim(),
      body: body.trim(),
      updatedAt: '2026-11-15T00:00:01Z',
    );
  }

  @override
  Future<void> delete(String id) async {
    if (id == current?.id) current = null;
  }
}

void main() {
  testWidgets('note edits retain identity and can create real task request', (
    tester,
  ) async {
    final notes = MemoryNotes();
    Note? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          repository: notes,
          onCreateTask: (note) async {
            captured = note;
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.text('Ghi chú ban đầu'));
    await tester.pump(const Duration(milliseconds: 200));
    final dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.first, 'Ghi chú đã sửa');
    await tester.tap(find.text('Lưu'));
    await tester.pump(const Duration(milliseconds: 220));
    expect(notes.current?.id, 'note-1');
    expect(notes.current?.title, 'Ghi chú đã sửa');

    await tester.tap(find.byTooltip('Tùy chọn ghi chú'));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.tap(find.text('Tạo việc từ ghi chú'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(captured?.id, 'note-1');
    expect(captured?.title, 'Ghi chú đã sửa');
    expect(notes.current, isNotNull);
  });
}
