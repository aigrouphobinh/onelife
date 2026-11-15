import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Tasks and visual preferences are local-only. No demo task is inserted.
class OneLifeTask {
  const OneLifeTask({
    required this.id,
    required this.title,
    required this.completed,
    this.dueAt,
  });

  final String id;
  final String title;
  final bool completed;
  final DateTime? dueAt;

  factory OneLifeTask.fromMap(Map<String, Object?> row) {
    final due = row['due_at_utc'] as String?;
    return OneLifeTask(
      id: row['id'] as String,
      title: row['title'] as String,
      completed: row['completed'] == 1,
      dueAt: due == null ? null : DateTime.parse(due).toLocal(),
    );
  }
}

abstract class OneLifeStore {
  Future<List<OneLifeTask>> loadTasks();
  Future<void> addTask({required String title, DateTime? dueAt});
  Future<void> setTaskCompleted(String id, bool completed);
  Future<void> updateTask(String id, {required String title, DateTime? dueAt});
  Future<void> deleteTask(String id);
  Future<String> selectedCharacter();
  Future<void> selectCharacter(String id);
}

/// Separate database preserves the existing notes DB schema and old users' notes.
class SqliteOneLifeStore implements OneLifeStore {
  Future<Database>? _opening;

  Future<Database> get _database => _opening ??= _open();

  /// Used by the backup repository to open an independent transaction.
  Future<Database> get database => _database;

  Future<Database> _open() async {
    final directory = await getDatabasesPath();
    return openDatabase(
      p.join(directory, 'onelife_ui.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE tasks ('
          'id TEXT PRIMARY KEY, title TEXT NOT NULL, '
          'due_at_utc TEXT, completed INTEGER NOT NULL DEFAULT 0, '
          'created_at_utc TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE preferences (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
      },
    );
  }

  @override
  Future<List<OneLifeTask>> loadTasks() async {
    final rows = await (await _database).query(
      'tasks',
      orderBy: 'completed ASC, due_at_utc ASC, created_at_utc DESC',
    );
    return rows.map(OneLifeTask.fromMap).toList();
  }

  @override
  Future<void> addTask({required String title, DateTime? dueAt}) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Tên công việc không được để trống.');
    }
    await (await _database).insert('tasks', {
      'id': const Uuid().v4(),
      'title': trimmed,
      'due_at_utc': dueAt?.toUtc().toIso8601String(),
      'completed': 0,
      'created_at_utc': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> setTaskCompleted(String id, bool completed) async {
    await (await _database).update(
      'tasks',
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateTask(
    String id, {
    required String title,
    DateTime? dueAt,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Tên công việc không được để trống.');
    }
    final count = await (await _database).update(
      'tasks',
      {
        'title': trimmed,
        'due_at_utc': dueAt?.toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count != 1) {
      throw StateError('Công việc không còn tồn tại.');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    final count = await (await _database).delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count != 1) {
      throw StateError('Công việc không còn tồn tại.');
    }
  }

  @override
  Future<String> selectedCharacter() async {
    final row = await (await _database).query(
      'preferences',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['selected_character'],
      limit: 1,
    );
    return row.isEmpty ? 'brain' : row.first['value']! as String;
  }

  @override
  Future<void> selectCharacter(String id) async {
    if (!const {'brain', 'cat', 'dog', 'robot', 'sprout'}.contains(id)) {
      throw ArgumentError('Nhân vật không hợp lệ.');
    }
    await (await _database).insert(
        'preferences',
        {
          'key': 'selected_character',
          'value': id,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() async {
    final opening = _opening;
    _opening = null;
    if (opening != null) await (await opening).close();
  }
}
