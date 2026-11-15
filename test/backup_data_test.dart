import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/backup_data.dart';

Map<String, Object?> backupFixture() => {
      'app': 'onelife',
      'version': 1,
      'created_at_utc': '2030-01-02T03:04:05Z',
      'tasks': [
        {
          'id': 'task-one',
          'title': 'Nhớ việc tiếng Việt 🌱',
          'completed': false,
          'due_at_utc': '2030-01-03T09:00:00Z',
          'created_at_utc': '2030-01-01T00:00:00Z',
        },
      ],
      'notes': [
        {
          'id': 'note-one',
          'title': 'Ghi chú',
          'body': 'Nội dung\nhttps://example.com',
          'updated_at': '2030-01-01T00:00:00Z',
        },
      ],
    };

void main() {
  test('portable roundtrip preserves unicode, IDs, status and UTC dates', () {
    final data = BackupData.parse(jsonEncode(backupFixture()));
    final restored = BackupData.parse(data.encode());
    expect(restored.tasks, data.tasks);
    expect(restored.notes, data.notes);
    expect(restored.tasks.single['completed'], 0);
    expect(() => restored.tasks.single['id'] = 'other', throwsUnsupportedError);
  });

  test('reject foreign files, future versions, wrong fields and duplicate IDs',
      () {
    for (final mutate in <void Function(Map<String, Object?>)>[
      (m) => m['app'] = 'other',
      (m) => m['version'] = 2,
      (m) => m['version'] = 1.0,
      (m) => m['notes'] = {},
      (m) => (m['tasks'] as List).add((m['tasks'] as List).first),
      (m) => ((m['tasks'] as List).first as Map)['completed'] = 0,
      (m) => ((m['tasks'] as List).first as Map)['title'] = ' ',
      (m) => ((m['tasks'] as List).first as Map)['id'] = null,
      (m) => ((m['notes'] as List).first as Map)['body'] = 1,
    ]) {
      final map =
          jsonDecode(jsonEncode(backupFixture())) as Map<String, dynamic>;
      mutate(map);
      expect(() => BackupData.parse(jsonEncode(map)), throwsFormatException);
    }
    expect(() => BackupData.parse('{broken'), throwsFormatException);
    expect(() => BackupData.parse('[]'), throwsFormatException);
  });

  test('reject impossible dates, local timestamps and oversized payload', () {
    for (final date in [
      '2030-02-30T00:00:00Z',
      '2030-01-01T25:00:00Z',
      '2030-01-01T00:00:00',
      '2030-01-01T00:00:00+07:00',
    ]) {
      final map = backupFixture()..['created_at_utc'] = date;
      expect(() => BackupData.parse(jsonEncode(map)), throwsFormatException);
    }
    expect(() => BackupData.parse('x' * (BackupData.maxBytes + 1)),
        throwsFormatException);
  });
}
