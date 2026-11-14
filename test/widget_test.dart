import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/home_page.dart';
import 'package:onelife/src/glossy_sprite.dart';
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

  testWidgets('switches two real Glossy Kawaii dog states on Home',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomePage(repository: FakeRepository())),
    );
    await tester.pumpAndSettle();

    GlossySprite sprite = tester.widget(find.byType(GlossySprite));
    expect(sprite.spec.assetPath,
        'assets/characters-v2/dog/recovering/sheet.png');
    expect(find.text('Hồi phục'), findsOneWidget);
    expect(find.text('Tập trung'), findsOneWidget);

    await tester.tap(find.text('Tập trung'));
    await tester.pumpAndSettle();
    sprite = tester.widget(find.byType(GlossySprite));
    expect(sprite.spec.assetPath,
        'assets/characters-v2/dog/focus/sheet.png');

    await tester.tap(find.text('Hồi phục'));
    await tester.pumpAndSettle();
    sprite = tester.widget(find.byType(GlossySprite));
    expect(sprite.spec.assetPath,
        'assets/characters-v2/dog/recovering/sheet.png');

    // The underlying notes workflow is still available.
    expect(find.text('Chưa có ghi chú. Nhấn + để bắt đầu.'),
        findsOneWidget);
    expect(find.byTooltip('Thêm ghi chú'), findsOneWidget);
  });
}
