import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/backup_data.dart';
import 'package:onelife/src/backup_repository.dart';
import 'package:onelife/src/note_repository.dart';
import 'package:onelife/src/onelife_store.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'backup_data_test.dart' show backupFixture;

void main() {
  late Directory directory;
  late SqliteOneLifeStore store;
  late NoteRepository notes;
  late SqliteBackupRepository repository;

  setUp(() async {
    sqfliteFfiInit();
    sql.databaseFactory = databaseFactoryFfi;
    directory = await Directory.systemTemp.createTemp('onelife-backup-test-');
    await sql.databaseFactory.setDatabasesPath(directory.path);
    store = SqliteOneLifeStore();
    notes = NoteRepository();
    repository = SqliteBackupRepository.local(store);
  });

  tearDown(() async {
    await notes.close();
    await store.close();
    await directory.delete(recursive: true);
  });

  test('export actual stores and restore exact rows after removal', () async {
    await store.addTask(title: 'Việc của tôi', dueAt: DateTime.utc(2030, 2, 1));
    await notes.save(title: 'Nội dung Việt', body: '🌱\nDòng hai');
    final before = await repository.export();
    await (await store.database).delete('tasks');
    await (await notes.database).delete('notes');
    final result = await repository.restore(before);
    expect(result.tasksAdded, 1);
    expect(result.notesAdded, 1);
    expect(result.skipped, 0);
    final after = await repository.export();
    expect(after.tasks, before.tasks);
    expect(after.notes, before.notes);
  });

  test('repeat import is idempotent and never reverts existing edits',
      () async {
    final backup = BackupData.parse(jsonEncode(backupFixture()));
    await repository.restore(backup);
    await store.updateTask('task-one', title: 'Giữ bản trên máy');
    await store.setTaskCompleted('task-one', true);
    await notes.update(
        id: 'note-one', title: 'Đã sửa', body: 'Giữ nội dung này');
    final result = await repository.restore(backup);
    expect(result.tasksAdded, 0);
    expect(result.notesAdded, 0);
    expect(result.skipped, 2);
    final tasks = await store.loadTasks();
    expect(tasks.single.title, 'Giữ bản trên máy');
    expect(tasks.single.completed, true);
    expect(tasks.single.dueAt, isNull);
    expect((await notes.search('')).single.body, 'Giữ nội dung này');
  });

  test('note write failure rolls back task writes in attached transaction',
      () async {
    await store.addTask(title: 'Việc đã có');
    await notes.save(title: 'Ghi chú đã có', body: 'Giữ nguyên');
    final before = await repository.export();
    await (await notes.database).execute(
      "CREATE TRIGGER reject_import BEFORE INSERT ON notes "
      "WHEN NEW.id = 'note-one' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(
      repository.restore(BackupData.parse(jsonEncode(backupFixture()))),
      throwsA(isA<DatabaseException>()),
    );
    final after = await repository.export();
    expect(after.tasks, before.tasks);
    expect(after.notes, before.notes);
  });
}
