import 'dart:async';

import 'package:flutter/material.dart';

import 'onelife_store.dart';

/// A live view of saved deadlines. Notification scheduling stays in the shell.
class SchedulePage extends StatefulWidget {
  const SchedulePage({
    super.key,
    required this.store,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
    required this.onReminderSettings,
    this.now = DateTime.now,
  });

  final OneLifeStore store;
  final Future<void> Function() onAdd;
  final Future<void> Function(OneLifeTask) onEdit;
  final Future<void> Function(OneLifeTask) onDelete;
  final Future<void> Function(OneLifeTask) onComplete;
  final Future<void> Function() onReminderSettings;
  final DateTime Function() now;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with WidgetsBindingObserver {
  List<OneLifeTask> _tasks = [];
  String _filter = 'today';
  DateTime? _selectedDate;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  int _request = 0;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final tasks = await widget.store.loadTasks();
      if (!mounted || request != _request) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được lịch. Hãy thử lại.';
      });
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lưu thay đổi. Hãy thử lại.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _pickDate() async {
    final today = widget.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: DateTime(1900),
      lastDate: DateTime(9999, 12, 31),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedDate = selected;
      _filter = 'date';
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.now();
    final day = _filter == 'date' ? _selectedDate! : now;
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);
    final items = _tasks.where((task) {
      final due = task.dueAt?.toLocal();
      if (due == null || task.completed) return false;
      if (_filter == 'all') return true;
      if (_filter == 'overdue') return due.isBefore(now);
      return !due.isBefore(start) && due.isBefore(end);
    }).toList()
      ..sort((a, b) {
        final order = a.dueAt!.compareTo(b.dueAt!);
        return order == 0 ? a.id.compareTo(b.id) : order;
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch & Báo thức')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final entry in const {
                  'today': 'Hôm nay',
                  'overdue': 'Quá hạn',
                  'all': 'Tất cả',
                }.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _filter == entry.key,
                    onSelected: (_) => setState(() => _filter = entry.key),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.calendar_month, size: 18),
                  label: Text(
                    _filter == 'date' ? _date(_selectedDate!) : 'Chọn ngày',
                  ),
                  onPressed: _pickDate,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Column(
                children: [
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              )
            else ...[
              Text('${items.length} công việc có hạn'),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Không có công việc trong khoảng này.'),
                ),
              for (final task in items)
                Card(
                  child: ListTile(
                    title: Text(task.title),
                    subtitle: Text(
                      '${_date(task.dueAt!.toLocal())} '
                      '${TimeOfDay.fromDateTime(task.dueAt!.toLocal()).format(context)}'
                      '${task.dueAt!.isBefore(now) ? ' · Quá hạn' : ''}',
                    ),
                    onTap: _busy ? null : () => _act(() => widget.onEdit(task)),
                    trailing: PopupMenuButton<String>(
                      enabled: !_busy,
                      tooltip: 'Thao tác lịch',
                      onSelected: (action) => _act(
                        () => switch (action) {
                          'complete' => widget.onComplete(task),
                          'delete' => widget.onDelete(task),
                          _ => widget.onEdit(task),
                        },
                      ),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'complete',
                          child: Text('Hoàn thành'),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Sửa công việc'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Xóa công việc'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : () => _act(widget.onAdd),
              icon: const Icon(Icons.add),
              label: const Text('Thêm việc'),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Thiết lập nhắc việc'),
              subtitle: const Text(
                'Nhắc việc native hiện có trên Android và có thể đến muộn '
                'do tiết kiệm pin. Đây không phải báo thức chính xác.',
              ),
              onTap: _busy ? null : widget.onReminderSettings,
            ),
          ],
        ),
      ),
    );
  }
}
