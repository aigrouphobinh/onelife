import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'backup_data.dart';
import 'note_repository.dart';
import 'onelife_store.dart';

class RestoreResult {
  const RestoreResult(this.tasksAdded, this.notesAdded, this.skipped);
  final int tasksAdded;
  final int notesAdded;
  final int skipped;
}

abstract class BackupRepository {
  Future<BackupData> export();
  Future<RestoreResult> restore(BackupData backup);
}

/// The connection owns main.tasks and an attached notes_db.notes database.
/// A transaction rolls back both sets of inserts if any write fails.
class SqliteBackupRepository implements BackupRepository {
  SqliteBackupRepository({required this.openConnection});

  factory SqliteBackupRepository.local(SqliteOneLifeStore store) {
    return SqliteBackupRepository(openConnection: () async {
      final tasks = await store.database;
      final notes = NoteRepository(singleInstance: false);
      late final String notesPath;
      try {
        notesPath = (await notes.database).path;
      } finally {
        await notes.close();
      }
      final connection = await openDatabase(tasks.path, singleInstance: false);
      try {
        await connection.execute('ATTACH DATABASE ? AS notes_db', [notesPath]);
        return connection;
      } catch (_) {
        await connection.close();
        rethrow;
      }
    });
  }

  final Future<Database> Function() openConnection;

  @override
  Future<BackupData> export() async {
    final db = await openConnection();
    try {
      return await db.transaction((txn) async {
        final tasks = await txn.query('tasks', orderBy: 'id');
        final notes =
            await txn.rawQuery('SELECT * FROM notes_db.notes ORDER BY id');
        return BackupData.parse(jsonEncode({
          'app': 'onelife',
          'version': 1,
          'created_at_utc': DateTime.now().toUtc().toIso8601String(),
          'tasks': tasks
              .map((row) => {...row, 'completed': row['completed'] == 1})
              .toList(),
          'notes': notes,
        }));
      });
    } finally {
      await db.close();
    }
  }

  @override
  Future<RestoreResult> restore(BackupData backup) async {
    final db = await openConnection();
    try {
      return await db.transaction((txn) async {
        var tasksAdded = 0;
        var notesAdded = 0;
        for (final row in backup.tasks) {
          await txn.rawInsert(
            'INSERT INTO tasks (id,title,completed,due_at_utc,created_at_utc) '
            'SELECT ?,?,?,?,? WHERE NOT EXISTS (SELECT 1 FROM tasks WHERE id=?)',
            [
              row['id'],
              row['title'],
              row['completed'],
              row['due_at_utc'],
              row['created_at_utc'],
              row['id']
            ],
          );
          tasksAdded +=
              Sqflite.firstIntValue(await txn.rawQuery('SELECT changes()'))!;
        }
        for (final row in backup.notes) {
          await txn.rawInsert(
            'INSERT INTO notes_db.notes (id,title,body,updated_at) '
            'SELECT ?,?,?,? WHERE NOT EXISTS (SELECT 1 FROM notes_db.notes WHERE id=?)',
            [
              row['id'],
              row['title'],
              row['body'],
              row['updated_at'],
              row['id']
            ],
          );
          notesAdded +=
              Sqflite.firstIntValue(await txn.rawQuery('SELECT changes()'))!;
        }
        return RestoreResult(
            tasksAdded,
            notesAdded,
            backup.tasks.length +
                backup.notes.length -
                tasksAdded -
                notesAdded);
      });
    } finally {
      await db.close();
    }
  }
}
