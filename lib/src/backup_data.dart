import 'dart:convert';

/// Portable, versioned notes/tasks only. No device permissions or active timers.
class BackupData {
  BackupData._(this.createdAt, this.tasks, this.notes);

  static const maxBytes = 5 * 1024 * 1024;
  static const maxRecords = 10000;
  final String createdAt;
  final List<Map<String, Object?>> tasks;
  final List<Map<String, Object?>> notes;

  static Never _invalid() =>
      throw const FormatException('File sao lưu OneLife không hợp lệ.');

  static String _text(Object? value, int max, {bool empty = false}) {
    if (value is! String ||
        value.length > max ||
        (!empty && value.trim().isEmpty) ||
        value.contains('\u0000')) {
      _invalid();
    }
    return value;
  }

  static String _utc(Object? value) {
    final text = _text(value, 32);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?Z$')
        .hasMatch(text)) {
      _invalid();
    }
    final date = DateTime.tryParse(text);
    // DateTime.parse alone accepts invalid overflowing days/months.
    if (date == null ||
        date.toIso8601String().substring(0, 19) != text.substring(0, 19)) {
      _invalid();
    }
    return date.toIso8601String();
  }

  factory BackupData.parse(String text) {
    if (text.length > maxBytes || utf8.encode(text).length > maxBytes) {
      throw const FormatException('File vượt quá giới hạn 5 MB.');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      _invalid();
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['app'] != 'onelife' ||
        decoded['version'] is! int ||
        decoded['version'] != 1) {
      _invalid();
    }
    final createdAt = _utc(decoded['created_at_utc']);
    final rawTasks = decoded['tasks'];
    final rawNotes = decoded['notes'];
    if (rawTasks is! List ||
        rawNotes is! List ||
        rawTasks.length + rawNotes.length > maxRecords) {
      _invalid();
    }
    final taskIds = <String>{};
    final noteIds = <String>{};
    final tasks = <Map<String, Object?>>[];
    final notes = <Map<String, Object?>>[];
    for (final row in rawTasks) {
      if (row is! Map<String, dynamic>) _invalid();
      final id = _text(row['id'], 128);
      if (!taskIds.add(id) || row['completed'] is! bool) _invalid();
      tasks.add(Map.unmodifiable({
        'id': id,
        'title': _text(row['title'], 10000),
        'completed': row['completed'] == true ? 1 : 0,
        'due_at_utc':
            row['due_at_utc'] == null ? null : _utc(row['due_at_utc']),
        'created_at_utc': _utc(row['created_at_utc']),
      }));
    }
    for (final row in rawNotes) {
      if (row is! Map<String, dynamic>) _invalid();
      final id = _text(row['id'], 128);
      final title = _text(row['title'], 100000, empty: true);
      final body = _text(row['body'], maxBytes, empty: true);
      if (!noteIds.add(id) || (title.trim().isEmpty && body.trim().isEmpty)) {
        _invalid();
      }
      notes.add(Map.unmodifiable({
        'id': id,
        'title': title,
        'body': body,
        'updated_at': _utc(row['updated_at']),
      }));
    }
    return BackupData._(
        createdAt, List.unmodifiable(tasks), List.unmodifiable(notes));
  }

  String encode() => jsonEncode({
        'app': 'onelife',
        'version': 1,
        'created_at_utc': createdAt,
        'tasks': tasks
            .map((row) => {...row, 'completed': row['completed'] == 1})
            .toList(),
        'notes': notes,
      });
}
