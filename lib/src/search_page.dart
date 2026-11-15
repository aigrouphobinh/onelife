import 'dart:async';

import 'package:flutter/material.dart';

import 'local_search.dart';
import 'note_repository.dart';
import 'onelife_store.dart';

class SearchPage extends StatefulWidget {
  const SearchPage(
      {super.key,
      required this.source,
      required this.onEditTask,
      required this.onDeleteTask,
      required this.onToggleTask,
      required this.onEditNote,
      required this.onDeleteNote,
      required this.onCreateTask});
  final SearchSource source;
  final Future<void> Function(OneLifeTask) onEditTask;
  final Future<void> Function(OneLifeTask) onDeleteTask;
  final Future<void> Function(OneLifeTask) onToggleTask;
  final Future<void> Function(Note) onEditNote;
  final Future<void> Function(Note) onDeleteNote;
  final Future<void> Function(Note) onCreateTask;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with WidgetsBindingObserver {
  final _query = TextEditingController();
  Timer? _debounce;
  int _request = 0;
  String _filter = 'all';
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<SearchResult> _results = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  void _changed(String _) {
    _debounce?.cancel();
    ++_request; // Invalidate immediately, before the debounce starts a new read.
    setState(() {
      _loading = true;
      _results = [];
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 250), _refresh);
  }

  Future<void> _refresh() async {
    _debounce?.cancel();
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.source.search(_query.text);
      if (!mounted || request != _request) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _results = [];
        _loading = false;
        _error = 'Không tải được dữ liệu tìm kiếm. Hãy thử lại.';
      });
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Không thể hoàn tất thao tác. Hãy thử lại.')),
        );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _refresh();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _action(SearchResult result, String action) => _act(() {
        final task = result.task;
        if (task != null) {
          return switch (action) {
            'delete' => widget.onDeleteTask(task),
            'toggle' => widget.onToggleTask(task),
            _ => widget.onEditTask(task),
          };
        }
        final note = result.note!;
        return switch (action) {
          'delete' => widget.onDeleteNote(note),
          'task' => widget.onCreateTask(note),
          _ => widget.onEditNote(note),
        };
      });

  @override
  Widget build(BuildContext context) {
    final results = _results
        .where((r) =>
            _filter == 'all' ||
            (_filter == 'tasks' ? r.task != null : r.note != null))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm ghi chú & công việc')),
      body: SafeArea(
          child: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _query,
              onChanged: _changed,
              onSubmitted: (_) => _refresh(),
              decoration: InputDecoration(
                labelText: 'Tìm trên thiết bị',
                hintText: 'Tiêu đề hoặc nội dung, có dấu hay không dấu',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa từ khóa',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _query.clear();
                          _changed('');
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
            )),
        Wrap(spacing: 8, children: [
          for (final entry in const {
            'all': 'Tất cả',
            'tasks': 'Công việc',
            'notes': 'Ghi chú'
          }.entries)
            ChoiceChip(
                label: Text(entry.value),
                selected: _filter == entry.key,
                onSelected: (_) => setState(() => _filter = entry.key)),
        ]),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_error!),
                      TextButton(
                          onPressed: _refresh, child: const Text('Thử lại')),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: results.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0)
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(results.isEmpty
                                  ? 'Không có kết quả phù hợp.'
                                  : '${results.length} kết quả · chỉ dữ liệu trên máy'),
                            );
                          final result = results[index - 1];
                          final task = result.task;
                          final due = task?.dueAt
                              ?.toLocal()
                              .toString()
                              .substring(0, 16);
                          return Card(
                              key: ValueKey(result.key),
                              child: ListTile(
                                leading: Icon(task == null
                                    ? Icons.note_alt_outlined
                                    : task.completed
                                        ? Icons.task_alt
                                        : Icons.radio_button_unchecked),
                                title: Text(result.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                    task == null
                                        ? 'Ghi chú · ${result.note!.body}'
                                        : '${task.completed ? 'Đã xong' : 'Chưa xong'} · ${due ?? 'Chưa chọn hạn'}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                onTap: _busy
                                    ? null
                                    : () => _action(result, 'edit'),
                                trailing: PopupMenuButton<String>(
                                  tooltip: 'Thao tác kết quả',
                                  enabled: !_busy,
                                  onSelected: (action) =>
                                      _action(result, action),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Mở và sửa')),
                                    if (task != null)
                                      PopupMenuItem(
                                          value: 'toggle',
                                          child: Text(task.completed
                                              ? 'Đánh dấu chưa xong'
                                              : 'Hoàn thành')),
                                    if (task == null)
                                      const PopupMenuItem(
                                          value: 'task',
                                          child: Text('Tạo việc từ ghi chú')),
                                    const PopupMenuItem(
                                        value: 'delete', child: Text('Xóa')),
                                  ],
                                ),
                              ));
                        },
                      )),
        ),
      ])),
    );
  }
}
