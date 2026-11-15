import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/note_actions.dart';

import 'note_management_test.dart' show MemoryNotes;

class FailingNotes extends MemoryNotes {
  bool fail = true;
  @override
  Future<void> update(
      {required String id, required String title, required String body}) async {
    if (fail) throw StateError('database unavailable');
    await super.update(id: id, title: title, body: body);
  }
}

void main() {
  testWidgets(
      'failed save preserves input and allows retry without dismissing editor',
      (tester) async {
    final notes = FailingNotes();
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () =>
                          showNoteEditor(context, notes, note: notes.current),
                      child: const Text('Mở')),
                ))));
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Nội dung mới');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nội dung vẫn được giữ'), findsOneWidget);
    expect(find.text('Nội dung mới'), findsOneWidget);
    notes.fail = false;
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Sửa ghi chú'), findsNothing);
    expect(notes.current!.title, 'Nội dung mới');
    expect(tester.takeException(), isNull);
  });
}
