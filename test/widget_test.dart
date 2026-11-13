import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/home_page.dart';
import 'package:onelife/src/note_repository.dart';

// Smoke test avoids opening a real SQLite database in the widget test process.
class FakeRepository extends NoteRepository {
  @override
  Future<List<Note>> search(String query) async => [];
}

void main() {
  testWidgets('shows OneLife empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(home: HomePage(repository: FakeRepository())));
    await tester.pumpAndSettle();
    expect(find.text('OneLife'), findsOneWidget);
    expect(find.text('Chưa có ghi chú. Nhấn + để bắt đầu.'), findsOneWidget);
  });
}
