import 'package:flutter/material.dart';

import 'note_repository.dart';

Future<bool> showNoteEditor(BuildContext context, NoteRepository repository,
        {Note? note}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NoteEditor(repository: repository, note: note),
    ) ??
    false;

Future<bool> confirmDeleteNote(
    BuildContext context, NoteRepository repository, Note note) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xóa ghi chú?'),
      content: Text('Xóa “${note.title}”? Hành động này chưa thể hoàn tác.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy')),
        FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa')),
      ],
    ),
  );
  if (confirmed != true) return false;
  await repository.delete(note.id);
  return true;
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({required this.repository, this.note});
  final NoteRepository repository;
  final Note? note;
  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final _title = TextEditingController(text: widget.note?.title ?? '');
  late final _body = TextEditingController(text: widget.note?.body ?? '');
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving) return;
    if (_title.text.trim().isEmpty && _body.text.trim().isEmpty) {
      setState(() => _error = 'Nhập tiêu đề hoặc nội dung ghi chú.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final note = widget.note;
      if (note == null) {
        await widget.repository.save(title: _title.text, body: _body.text);
      } else {
        await widget.repository
            .update(id: note.id, title: _title.text, body: _body.text);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'Không lưu được ghi chú. Nội dung vẫn được giữ để thử lại.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: AlertDialog(
          title: Text(widget.note == null ? 'Ghi chú mới' : 'Sửa ghi chú'),
          content: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _title,
                  autofocus: true,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Tiêu đề')),
              TextField(
                  controller: _body,
                  maxLines: 6,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Nội dung')),
              if (_error != null)
                Semantics(liveRegion: true, child: Text(_error!)),
            ],
          )),
          actions: [
            TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context, false),
                child: const Text('Hủy')),
            FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Đang lưu…' : 'Lưu')),
          ],
        ),
      );
}
