import 'package:flutter/material.dart';
import 'note_repository.dart';
import 'glossy_sprite.dart';

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
  int _mascotReplay = 0;
  String _dogState = 'recovering';

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
      const SizedBox(height: 12),
      Card(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                GlossySprite(
                  key: ValueKey('dog-$_dogState-$_mascotReplay'),
                  spec: _dogState == 'thinking'
                      ? GlossySpriteSpec.dogThinking
                      : _dogState == 'done'
                      ? GlossySpriteSpec.dogDone
                      : _dogState == 'study'
                          ? GlossySpriteSpec.dogStudy
                      : _dogState == 'focus'
                          ? GlossySpriteSpec.dogFocus
                          : GlossySpriteSpec.dogRecovering,
                  size: 104,
                  semanticLabel: _dogState == 'thinking'
                      ? 'Chú chó màu cam đang suy nghĩ về một ý tưởng'
                      : _dogState == 'done'
                      ? 'Chú chó màu cam đang ăn mừng hoàn thành nhiệm vụ'
                      : _dogState == 'study'
                          ? 'Chú chó màu cam đang đọc sách và học tập'
                      : _dogState == 'focus'
                          ? 'Chú chó màu cam đang tập trung'
                          : 'Chú chó màu cam đang thức dậy và vươn vai',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_dogState == 'thinking'
                              ? 'Một ý tưởng mới?'
                              : _dogState == 'done'
                              ? 'Hoàn thành một việc nhỏ!'
                              : _dogState == 'study'
                                  ? 'Một trang sách mới'
                              : _dogState == 'focus'
                                  ? 'Giữ nhịp tập trung'
                                  : 'Một nhịp nghỉ dịu dàng',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(_dogState == 'thinking'
                          ? 'Nhẹ nhàng suy nghĩ và thử một cách khác.'
                          : _dogState == 'done'
                          ? 'Chúc mừng bạn đã hoàn thành!'
                          : _dogState == 'study'
                              ? 'Hãy khám phá điều thú vị tiếp theo.'
                          : _dogState == 'focus'
                              ? 'Chọn một việc nhỏ và bắt đầu.'
                              : 'Nghỉ ngơi rồi trở lại nhẹ nhàng.',
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                      TextButton.icon(
                        onPressed: () => setState(() => _mascotReplay++),
                        icon: const Icon(Icons.replay, size: 18),
                        label: const Text('Xem lại'),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('Hồi phục'),
                    selected: _dogState == 'recovering',
                    onSelected: (selected) {
                      if (selected && _dogState != 'recovering') {
                        setState(() {
                          _dogState = 'recovering';
                          _mascotReplay++;
                        });
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Tập trung'),
                    selected: _dogState == 'focus',
                    onSelected: (selected) {
                      if (selected && _dogState != 'focus') {
                        setState(() {
                          _dogState = 'focus';
                          _mascotReplay++;
                        });
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Học tập'),
                    selected: _dogState == 'study',
                    onSelected: (selected) {
                      if (selected && _dogState != 'study') {
                        setState(() {
                          _dogState = 'study';
                          _mascotReplay++;
                        });
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Hoàn thành'),
                    selected: _dogState == 'done',
                    onSelected: (selected) {
                      if (selected && _dogState != 'done') {
                        setState(() {
                          _dogState = 'done';
                          _mascotReplay++;
                        });
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Suy nghĩ'),
                    selected: _dogState == 'thinking',
                    onSelected: (selected) {
                      if (selected && _dogState != 'thinking') {
                        setState(() {
                          _dogState = 'thinking';
                          _mascotReplay++;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
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
