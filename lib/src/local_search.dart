import 'note_repository.dart';
import 'onelife_store.dart';

/// Vietnamese-friendly literal matching, including decomposed accent marks.
String normalizeSearch(String text) {
  var result = text.toLowerCase();
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final group in groups.entries) {
    result = result.replaceAll(RegExp('[${group.value}]'), group.key);
  }
  return result
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class SearchResult {
  const SearchResult.task(OneLifeTask value)
      : task = value,
        note = null;
  const SearchResult.note(Note value)
      : note = value,
        task = null;
  final OneLifeTask? task;
  final Note? note;
  String get key => task != null ? 'task:${task!.id}' : 'note:${note!.id}';
  String get title =>
      task?.title ?? (note!.title.isEmpty ? '(Không tiêu đề)' : note!.title);
}

abstract class SearchSource {
  Future<List<SearchResult>> search(String query);
}

class LocalSearch implements SearchSource {
  LocalSearch({required this.store, required this.notes});
  final OneLifeStore store;
  final NoteRepository notes;

  @override
  Future<List<SearchResult>> search(String query) async {
    // Read both sources on refresh; no cached copy survives edits or restore.
    final data =
        await Future.wait<Object>([store.loadTasks(), notes.search('')]);
    final tasks = data[0] as List<OneLifeTask>;
    final savedNotes = data[1] as List<Note>;
    final words =
        normalizeSearch(query).split(' ').where((word) => word.isNotEmpty);
    bool matches(String text) {
      final normalized = normalizeSearch(text);
      return words.every(normalized.contains);
    }

    final matchingTasks = tasks.where((task) => matches(task.title)).toList()
      ..sort((a, b) {
        if (a.completed != b.completed) return a.completed ? 1 : -1;
        final due = (a.dueAt?.millisecondsSinceEpoch ?? 8640000000000000)
            .compareTo(b.dueAt?.millisecondsSinceEpoch ?? 8640000000000000);
        return due == 0 ? a.id.compareTo(b.id) : due;
      });
    final matchingNotes = savedNotes
        .where((note) => matches('${note.title}\n${note.body}'))
        .toList()
      ..sort((a, b) {
        final updated = b.updatedAt.compareTo(a.updatedAt);
        return updated == 0 ? a.id.compareTo(b.id) : updated;
      });
    return [
      ...matchingTasks.map(SearchResult.task),
      ...matchingNotes.map(SearchResult.note),
    ];
  }
}
