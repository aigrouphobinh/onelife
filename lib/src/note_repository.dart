import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class Note {
  const Note({required this.id, required this.title, required this.body, required this.updatedAt});
  final String id;
  final String title;
  final String body;
  final String updatedAt;

  factory Note.fromMap(Map<String, Object?> map) => Note(
        id: map['id'] as String,
        title: map['title'] as String,
        body: map['body'] as String,
        updatedAt: map['updated_at'] as String,
      );
}

class NoteRepository {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final directory = await getDatabasesPath();
    _database = await openDatabase(
      p.join(directory, 'onelife.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE notes (id TEXT PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL, updated_at TEXT NOT NULL)');
        await db.execute('CREATE INDEX idx_notes_updated ON notes(updated_at)');
      },
    );
    return _database!;
  }

  Future<List<Note>> search(String query) async {
    final db = await database;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return (await db.query('notes', orderBy: 'updated_at DESC'))
          .map(Note.fromMap).toList();
    }
    // Escape LIKE wildcards so a search is treated as literal text.
    final pattern = '%${trimmed.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_')}%';
    return (await db.query('notes',
            where: "title LIKE ? ESCAPE '\\' OR body LIKE ? ESCAPE '\\'",
            whereArgs: [pattern, pattern], orderBy: 'updated_at DESC'))
        .map(Note.fromMap).toList();
  }

  Future<void> save({required String title, required String body}) async {
    if (title.trim().isEmpty && body.trim().isEmpty) {
      throw ArgumentError('Note must not be empty');
    }
    final db = await database;
    await db.insert('notes', {
      'id': const Uuid().v4(),
      'title': title.trim(),
      'body': body.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> delete(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
