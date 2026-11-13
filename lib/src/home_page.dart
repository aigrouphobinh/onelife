import 'package:flutter/material.dart';
import 'note_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repository});
  final NoteRepository repository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();
  List<Note> _notes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final result = await widget.repository.search(_search.text);
      if (mounted) setState(() { _notes = result; _loading = false; _error = null; });
    } catch (error) {
      if (mounted) setState(() { _loading = false; _error = 'Không thể đọc ghi chú. Vui lòng thử lại.'; });
    }
  }

  Future<void> _addNote() async {
    final title = TextEditingController();
    final body = TextEditingController();
    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ghi chú mới'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'Tiêu đề')),
            TextField(controller: body, maxLines: 4, decoration: const InputDecoration(labelText: 'Nội dung')),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
          ],
        ),
      );
      if (shouldSave == true) {
        await widget.repository.save(title: title.text, body: body.text);
        await _reload();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không lưu được ghi chú.')));
    } finally {
      title.dispose();
      body.dispose();
    }
  }

  Future<void> _delete(Note note) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Xóa ghi chú?'),
      content: Text('Xóa “${note.title}”? Hành động này chưa thể hoàn tác.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa'))],
    ));
    if (confirmed == true) {
      await widget.repository.delete(note.id);
      await _reload();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('OneLife')),
    body: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Một nơi để nhớ, tìm và hoàn thành việc', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 16),
      TextField(controller: _search, onChanged: (_) => _reload(),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm ghi chú...', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) :
        _notes.isEmpty ? const Center(child: Text('Chưa có ghi chú. Nhấn + để bắt đầu.')) :
        ListView.builder(itemCount: _notes.length, itemBuilder: (context, index) {
          final note = _notes[index];
          return Card(child: ListTile(
            title: Text(note.title.isEmpty ? '(Không tiêu đề)' : note.title),
            subtitle: Text(note.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: IconButton(tooltip: 'Xóa ghi chú', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(note)),
          ));
        })),
    ])),
    floatingActionButton: FloatingActionButton(onPressed: _addNote, tooltip: 'Thêm ghi chú', child: const Icon(Icons.add)),
  );
}
