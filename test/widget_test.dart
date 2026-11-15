import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/home_page.dart';
import 'package:onelife/src/glossy_sprite.dart';
import 'package:onelife/src/dog_animation_gallery.dart';
import 'package:onelife/src/robot_animation_gallery.dart';
import 'package:onelife/src/note_repository.dart';

// Smoke test avoids opening a real SQLite database in the widget test process.
class FakeRepository extends NoteRepository {
  @override
  Future<List<Note>> search(String query) async => [];
}

void main() {
  testWidgets('shows OneLife empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomePage(repository: FakeRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.text('OneLife'), findsOneWidget);
    expect(find.text('Chưa có ghi chú. Nhấn + để bắt đầu.'), findsOneWidget);
  });

  testWidgets('switches five real Glossy Kawaii dog states on Home', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: HomePage(repository: FakeRepository())),
    );
    await tester.pumpAndSettle();

    GlossySprite sprite = tester.widget(find.byType(GlossySprite));
    expect(
      sprite.spec.assetPath,
      'assets/characters-v2/dog/recovering/sheet.png',
    );
    expect(find.text('Hồi phục'), findsOneWidget);
    expect(find.text('Tập trung'), findsOneWidget);

    await tester.tap(find.text('Tập trung'));
    await tester.pumpAndSettle();
    sprite = tester.widget(find.byType(GlossySprite));
    expect(sprite.spec.assetPath, 'assets/characters-v2/dog/focus/sheet.png');

    await tester.tap(find.text('Học tập'));
    await tester.pumpAndSettle();
    sprite = tester.widget(find.byType(GlossySprite));
    expect(sprite.spec.assetPath, 'assets/characters-v2/dog/study/sheet.png');

    await tester.tap(find.text('Hoàn thành'));
    await tester.pumpAndSettle();
    sprite = tester.widget(find.byType(GlossySprite));
    expect(sprite.spec.assetPath, 'assets/characters-v2/dog/done/sheet.png');

    await tester.tap(find.text('Suy nghĩ'));
    await tester.pumpAndSettle();
    sprite = tester.widget(find.byType(GlossySprite));
    expect(
      sprite.spec.assetPath,
      'assets/characters-v2/dog/thinking/sheet.png',
    );

    await tester.tap(find.text('Hồi phục'));
    await tester.pumpAndSettle();
    sprite = tester.widget(find.byType(GlossySprite));
    expect(
      sprite.spec.assetPath,
      'assets/characters-v2/dog/recovering/sheet.png',
    );

    // The underlying notes workflow is still available.
    expect(find.text('Chưa có ghi chú. Nhấn + để bắt đầu.'), findsOneWidget);
    expect(find.byTooltip('Thêm ghi chú'), findsOneWidget);
  });

  testWidgets('gallery exposes all 15 Dog states and imports the last three', (
    tester,
  ) async {
    expect(dogAnimationEntries.length, 15);
    expect(dogAnimationEntries.map((entry) => entry.id).toSet().length, 15);
    await tester.pumpWidget(
      MaterialApp(home: HomePage(repository: FakeRepository())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chó · 15 hoạt ảnh'));
    await tester.pumpAndSettle();

    expect(find.byType(DogAnimationGalleryPage), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(15));
    for (final pair in [
      ('Buồn', 'sad'),
      ('Cân bằng', 'balanced'),
      ('Căng nhẹ', 'strained'),
    ]) {
      final choice = find.text(pair.$1);
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      await tester.tap(choice);
      await tester.pumpAndSettle();
      final spriteFinder = find.descendant(
        of: find.byType(DogAnimationGalleryPage),
        matching: find.byType(GlossySprite),
      );
      final sprite = tester.widget<GlossySprite>(spriteFinder);
      expect(
        sprite.spec.assetPath,
        'assets/characters-v2/dog/${pair.$2}/sheet.png',
      );
      expect(sprite.spec.frames, 12);
    }
  });

  testWidgets('Robot gallery displays exactly the committed 12 real sources', (
    tester,
  ) async {
    expect(robotAnimationEntries.length, 12);
    expect(robotAnimationEntries.map((entry) => entry.id).toSet().length, 12);
    for (final item in robotAnimationEntries) {
      expect(
        item.sprite.assetPath,
        'assets/characters-v2/robot/${item.id}/sheet.png',
      );
    }
    await tester.pumpWidget(
      MaterialApp(home: HomePage(repository: FakeRepository())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Robot · 12 hoạt ảnh'));
    await tester.pumpAndSettle();
    expect(find.byType(RobotAnimationGalleryPage), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(12));
    expect(find.textContaining('12/15 animation nguồn Robot'), findsOneWidget);
    final robotSprite = tester.widget<GlossySprite>(
      find.descendant(
        of: find.byType(RobotAnimationGalleryPage),
        matching: find.byType(GlossySprite),
      ),
    );
    expect(
      robotSprite.spec.assetPath,
      'assets/characters-v2/robot/thinking/sheet.png',
    );
    expect(robotSprite.spec.frameDurationMs, 145);
  });
}
