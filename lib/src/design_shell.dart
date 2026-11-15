import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show MethodCall, MethodChannel, MissingPluginException;

import 'glossy_sprite.dart';
import 'focus_page.dart';
import 'onelife_store.dart';
import 'note_repository.dart';
import 'home_page.dart';
import 'dog_animation_gallery.dart';
import 'robot_animation_gallery.dart';
import 'brain_overlay_setup_page.dart';

const designPurple = Color(0xFF8054E6);
const designInk = Color(0xFF21183C);
const designBackground = Color(0xFFF8F3FF);
const brainIdle = GlossySpriteSpec(
  assetPath: 'assets/characters-v2/brain/idle/sheet.png',
  frames: 8,
  columns: 4,
  frameWidth: 256,
  frameHeight: 256,
  frameDurationMs: 140,
  loop: true,
);
const characterOptions = <String, String>{
  'brain': 'Bộ Não',
  'cat': 'Mèo Trợ Lý',
  'dog': 'Cún Năng Động',
  'robot': 'Robot Thông Minh',
  'sprout': 'Mầm Xanh',
};

class OneLifeDesignShell extends StatefulWidget {
  const OneLifeDesignShell({super.key, this.store});
  final OneLifeStore? store;
  @override
  State<OneLifeDesignShell> createState() => _OneLifeDesignShellState();
}

class _OneLifeDesignShellState extends State<OneLifeDesignShell>
    with WidgetsBindingObserver {
  late final OneLifeStore store = widget.store ?? SqliteOneLifeStore();
  List<OneLifeTask> tasks = [];
  String character = 'brain';
  String? error;
  bool loading = true;
  int tab = 0;
  int taskFilter = 0;
  int habitPeriod = 0;
  static const MethodChannel _captureChannel =
      MethodChannel('onelife/quick_capture');
  bool _quickCaptureQueued = false;
  bool _remindersEnabled = false;
  bool _remindersBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _captureChannel.setMethodCallHandler(_handleNativeAction);
    reload();
    _loadReminderStatus();
    _consumeLaunchAction();
  }

  Future<void> _handleNativeAction(MethodCall call) async {
    if (call.method == 'openCapture') {
      _queueQuickCapture();
    } else if (call.method == 'openTasks') {
      _openTodayTasks();
    } else if (call.method == 'openFocus') {
      _openFocus();
    }
  }

  void _openFocus() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      open(const FocusPage());
    });
  }

  void _openTodayTasks() {
    if (!mounted) return;
    setState(() {
      tab = 1;
      taskFilter = 0;
    });
    // If Focus, Settings or a dialog was previously open, return to the
    // actual root Tasks tab rather than changing an invisible underlying tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
    // Tasks can have changed while Flutter was paused or another tile ran.
    reload();
  }

  Future<void> _consumeLaunchAction() async {
    try {
      final action =
          await _captureChannel.invokeMethod<String>('consumeLaunchAction');
      if (action == 'capture') {
        _queueQuickCapture();
      } else if (action == 'tasks') {
        _openTodayTasks();
      } else if (action == 'focus') {
        _openFocus();
      }
    } on MissingPluginException {
      // iOS and Flutter widget tests have no Android Quick Capture channel.
    } catch (_) {
      // Native channel unavailable: the normal Flutter UI remains usable.
    }
  }

  void _queueQuickCapture() {
    // Double tapping the tile must not open two text-entry dialogs.
    if (!mounted || _quickCaptureQueued) return;
    _quickCaptureQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _quickCaptureQueued = false;
        return;
      }
      try {
        await addTask();
      } finally {
        _quickCaptureQueued = false;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Native notification "Hoàn thành" can update SQLite while app is away.
      reload();
      _loadReminderStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captureChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _requestQuickSettingsTile(String tile) async {
    if (Theme.of(context).platform != TargetPlatform.android) {
      notify('Điều khiển nhanh Android không có trên thiết bị này.');
      return;
    }
    try {
      final status = await _captureChannel.invokeMethod<String>(
        'requestAddTile',
        {'tile': tile},
      );
      if (!mounted) return;
      if (status == 'added') {
        notify('OneLife đã được thêm vào điều khiển nhanh.');
      } else if (status == 'declined') {
        notify('Chưa thêm ô. Bạn có thể thêm thủ công trong Quick Settings.');
      } else {
        notify('Vuốt từ trên xuống hai lần, chọn Sửa rồi thêm ô OneLife.');
      }
    } on MissingPluginException {
      notify('Tính năng cần bản OneLife Android có tích hợp native.');
    } catch (_) {
      notify('Không mở được lời mời thêm ô. Hãy thêm thủ công.');
    }
  }

  Future<void> _loadReminderStatus() async {
    try {
      final enabled =
          await _captureChannel.invokeMethod<bool>('remindersStatus') ?? false;
      if (mounted) setState(() => _remindersEnabled = enabled);
    } on MissingPluginException {
      // iOS does not yet have the native OneLife reminder receiver.
    } catch (_) {
      // Permission state can be re-checked on returning to Settings.
    }
  }

  Future<void> _syncNativeReminders() async {
    try {
      await _captureChannel.invokeMethod<bool>('syncReminders');
    } catch (_) {
      // Saving/completing tasks must not depend on OS notification support.
    }
  }

  Future<void> _changeReminders(bool enabled) async {
    if (_remindersBusy) return;
    if (Theme.of(context).platform != TargetPlatform.android) {
      notify('Nhắc việc native hiện chỉ có trên Android.');
      return;
    }
    setState(() => _remindersBusy = true);
    try {
      final activated = await _captureChannel.invokeMethod<bool>(
            enabled ? 'enableReminders' : 'disableReminders',
          ) ??
          false;
      if (!mounted) return;
      setState(() => _remindersEnabled = activated);
      if (enabled && !activated) {
        notify('Chưa được cấp quyền thông báo. Kiểm tra Cài đặt Android.');
      } else if (!enabled) {
        notify('Đã tắt lịch nhắc việc, dữ liệu công việc vẫn được giữ.');
      } else {
        notify('Đã bật thông báo cho các công việc có hạn sắp tới.');
      }
    } on MissingPluginException {
      notify('Ứng dụng chưa tích hợp thông báo native trên thiết bị này.');
    } catch (_) {
      notify('Không thể thay đổi quyền nhắc việc.');
    } finally {
      if (mounted) setState(() => _remindersBusy = false);
    }
  }

  Future<void> _refreshNativeWidget() async {
    try {
      await _captureChannel.invokeMethod<bool>('refreshWidgets');
    } on MissingPluginException {
      // No Android launcher widget on iOS or in widget tests.
    } catch (_) {
      // App task management works independently from system widgets.
    }
  }

  Future<void> _requestPinWidget() async {
    if (Theme.of(context).platform != TargetPlatform.android) {
      notify('Widget này hiện chỉ có trên Android.');
      return;
    }
    try {
      final status =
          await _captureChannel.invokeMethod<String>('requestPinWidget');
      if (!mounted) return;
      if (status == 'requested') {
        notify('Đã gửi yêu cầu. Xác nhận với màn hình chính để thêm widget.');
      } else {
        notify('Giữ chạm màn hình chính → Widget → chọn OneLife.');
      }
    } on MissingPluginException {
      notify('Cần bản OneLife Android có tích hợp widget native.');
    } catch (_) {
      notify('Không gửi được yêu cầu. Hãy thêm widget thủ công.');
    }
  }

  Future<void> reload() async {
    try {
      final result = await store.loadTasks();
      final selected = await store.selectedCharacter();
      if (!mounted) {
        return;
      }
      setState(() {
        tasks = result;
        character = characterOptions.containsKey(selected) ? selected : 'brain';
        error = null;
        loading = false;
      });
      _refreshNativeWidget();
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Không tải được dữ liệu cục bộ';
          loading = false;
        });
      }
    }
  }

  void notify(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> addTask() => _saveTask();

  Future<void> editTask(OneLifeTask task) => _saveTask(task: task);

  Future<void> _saveTask({OneLifeTask? task, String? suggestedTitle}) async {
    String title = task?.title ?? suggestedTitle ?? '';
    DateTime? dueAt = task?.dueAt;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: Text(task == null ? 'Thêm việc mới' : 'Sửa công việc'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: title,
                  autofocus: true,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Tên công việc'),
                  onChanged: (value) => update(() => title = value),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final initialDate =
                        dueAt != null && dueAt!.isAfter(now) ? dueAt! : now;
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: initialDate,
                      firstDate: DateTime(now.year, now.month, now.day),
                      lastDate: DateTime(now.year + 5, now.month, now.day),
                    );
                    if (date == null || !dialogContext.mounted) return;
                    final time = await showTimePicker(
                      context: dialogContext,
                      initialTime: dueAt == null
                          ? TimeOfDay.now()
                          : TimeOfDay.fromDateTime(dueAt!),
                    );
                    if (time == null || !dialogContext.mounted) return;
                    update(
                      () => dueAt = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      ),
                    );
                  },
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    dueAt == null
                        ? 'Chọn ngày giờ'
                        : dueAt.toString().substring(0, 16),
                  ),
                ),
                if (dueAt != null)
                  TextButton.icon(
                    onPressed: () => update(() => dueAt = null),
                    icon: const Icon(Icons.event_busy_outlined),
                    label: const Text('Bỏ lịch hẹn'),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Nếu bật Nhắc việc trong Cài đặt Android, hệ thống '
                  'sẽ lên lịch thông báo (có thể đến muộn).',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: title.trim().isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    try {
      if (task == null) {
        await store.addTask(title: title, dueAt: dueAt);
      } else {
        await store.updateTask(task.id, title: title, dueAt: dueAt);
      }
      await reload();
      await _syncNativeReminders();
      notify(
          task == null ? 'Đã lưu công việc trên thiết bị' : 'Đã sửa công việc');
    } catch (_) {
      notify('Không thể lưu công việc');
    }
  }

  Future<void> deleteTask(OneLifeTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa công việc?'),
        content: Text('Xóa “${task.title}”? Dữ liệu sẽ không thể khôi phục.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await store.deleteTask(task.id);
      await reload();
      await _syncNativeReminders();
      notify('Đã xóa công việc');
    } catch (_) {
      notify('Không thể xóa công việc');
    }
  }

  Future<void> toggle(OneLifeTask task, bool done) async {
    try {
      await store.setTaskCompleted(task.id, done);
      await reload();
      await _syncNativeReminders();
    } catch (_) {
      notify('Không thể cập nhật công việc');
    }
  }

  Future<void> selectCharacter(String id) async {
    try {
      await store.selectCharacter(id);
      await reload();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      notify('Không thể lưu lựa chọn nhân vật');
    }
  }

  void open(Widget page) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));

  void openNotes() => open(
        HomePage(
          repository: NoteRepository(),
          onCreateTask: (note) async {
            final source = note.title.trim().isNotEmpty
                ? note.title.trim()
                : note.body.trim();
            final normalized = source.replaceAll(RegExp(r'\s+'), ' ');
            await _saveTask(
              suggestedTitle: normalized.length > 120
                  ? normalized.substring(0, 120)
                  : normalized,
            );
          },
        ),
      );

  Widget mascot(String id, {double size = 88}) => id == 'brain'
      ? GlossySprite(
          spec: brainIdle,
          size: size,
          semanticLabel: 'Bộ Não OneLife Glossy Kawaii',
        )
      : Image.asset(
          'assets/characters-v2/$id/master.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          semanticLabel: characterOptions[id],
        );

  // Material is the nearest ink surface: ListTile ripples and focus highlights
  // must paint *inside* the rounded V3.4 card, not behind a DecoratedBox.
  Widget card(Widget child) => Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x164F366D),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      );

  Widget heading(String title, String description) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                color: designInk,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(description, style: const TextStyle(color: Color(0xFF796D8B))),
          ],
        ),
      );

  Widget taskRow(OneLifeTask task) => Row(
        children: [
          Checkbox(
            value: task.completed,
            activeColor: designPurple,
            onChanged: (value) => toggle(task, value ?? false),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: designInk,
                    fontWeight: FontWeight.w600,
                    decoration:
                        task.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  task.dueAt == null
                      ? 'Chưa chọn hạn'
                      : task.dueAt.toString().substring(0, 16),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF837695),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Tùy chọn công việc',
            onSelected: (action) {
              if (action == 'edit') {
                editTask(task);
              } else if (action == 'delete') {
                deleteTask(task);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Sửa công việc')),
              PopupMenuItem(value: 'delete', child: Text('Xóa công việc')),
            ],
          ),
        ],
      );

  Widget homePage() {
    final pending = tasks.where((t) => !t.completed).toList();
    final now = DateTime.now();
    final today = pending
        .where(
          (t) =>
              t.dueAt == null ||
              t.dueAt!.isBefore(DateTime(now.year, now.month, now.day + 1)),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF302847), Color(0xFF765FB3), Color(0xFF9B88CD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chào bạn 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hôm nay có ${pending.length} việc cần làm',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ngày ${now.day}/${now.month}/${now.year}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => tab = 4),
                child: mascot(character, size: 98),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: designPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Công việc hôm nay (${today.length})',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => tab = 1),
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              if (today.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có công việc. Nhấn Thêm việc để bắt đầu.'),
                )
              else
                for (final task in today.take(4)) ...[
                  const Divider(),
                  taskRow(task),
                ],
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: addTask,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm việc'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thói quen',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text('Chưa có dữ liệu thời gian sử dụng điện thoại.'),
              TextButton.icon(
                onPressed: () => setState(() => tab = 3),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Tìm hiểu quyền truy cập'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        card(
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.alarm_outlined),
                label: const Text('Lịch & Báo thức'),
                onPressed: () => open(schedulePage()),
              ),
              ActionChip(
                avatar: const Icon(Icons.note_alt_outlined),
                label: const Text('Ghi chú'),
                onPressed: openNotes,
              ),
              ActionChip(
                avatar: const Icon(Icons.timer_outlined),
                label: const Text('Tập trung 25 phút'),
                onPressed: () => open(const FocusPage()),
              ),
              ActionChip(
                avatar: const Icon(Icons.auto_awesome),
                label: const Text('Trợ lý'),
                onPressed: () => open(assistantPage()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget tasksPage() {
    final now = DateTime.now();
    final items = tasks.where((t) {
      if (taskFilter == 2) return t.completed;
      if (t.completed) return false;
      if (taskFilter == 1) {
        return t.dueAt != null &&
            !t.dueAt!.isBefore(DateTime(now.year, now.month, now.day + 1));
      }
      return t.dueAt == null ||
          t.dueAt!.isBefore(DateTime(now.year, now.month, now.day + 1));
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        heading('Việc cần làm', 'Quản lý việc và theo dõi tiến độ'),
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ChoiceChip(
                    selected: taskFilter == i,
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(
                        ['Hôm nay', 'Sắp tới', 'Đã xong'][i],
                        textAlign: TextAlign.center,
                      ),
                    ),
                    onSelected: (_) => setState(() => taskFilter = i),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Danh sách (${items.length})',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Chưa có công việc trong mục này.'),
                )
              else
                for (final task in items) ...[taskRow(task), const Divider()],
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: addTask,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm việc'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        card(
          ListTile(
            leading: const Icon(Icons.event_note, color: designPurple),
            title: const Text('Lịch & Báo thức'),
            subtitle: const Text('Xem công việc đã hẹn giờ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => open(schedulePage()),
          ),
        ),
      ],
    );
  }

  Widget schedulePage() {
    final items = tasks.where((t) => t.dueAt != null && !t.completed).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch & Báo thức')),
      backgroundColor: designBackground,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heading('Lịch của bạn', 'Dữ liệu lưu trên điện thoại'),
          card(
            Column(
              children: [
                if (items.isEmpty)
                  const Text('Chưa có công việc được hẹn giờ.'),
                for (final task in items)
                  ListTile(
                    title: Text(task.title),
                    subtitle: Text(task.dueAt.toString()),
                    leading: const Icon(Icons.event, color: designPurple),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          card(
            ListTile(
              leading: const Icon(
                Icons.notifications_active_outlined,
                color: designPurple,
              ),
              title: Text(_remindersEnabled
                  ? 'Nhắc việc Android đã bật'
                  : 'Thông báo nhắc việc đang tắt'),
              subtitle: const Text(
                'Nhắc việc theo hạn đã chọn, có thể trễ do tiết kiệm pin. '
                'Chạm để thiết lập quyền và thao tác thông báo.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => open(reminderSetupPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget habitsPage() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heading('Thói quen', 'Hiểu nhịp dùng điện thoại của bạn'),
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ChoiceChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(
                          ['Hôm nay', '7 ngày', '30 ngày'][i],
                          textAlign: TextAlign.center,
                        ),
                      ),
                      selected: habitPeriod == i,
                      onSelected: (_) => setState(() => habitPeriod = i),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          card(
            const ListTile(
              leading: Icon(Icons.lock_outline, color: designPurple),
              title: Text('Thời gian sử dụng: chưa có dữ liệu'),
              subtitle: Text(
                'Không hiển thị số giờ hoặc biểu đồ giả. '
                'Android cần Usage Access; iOS cần quyền Screen Time.',
              ),
            ),
          ),
          const SizedBox(height: 14),
          card(
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thói quen nhận diện',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                ListTile(
                  leading: Icon(Icons.smartphone_outlined, color: designPurple),
                  title: Text('Mạng xã hội'),
                  subtitle: Text('Chưa có dữ liệu'),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.menu_book_outlined, color: designPurple),
                  title: Text('Học tập / làm việc'),
                  subtitle: Text('Chưa có dữ liệu'),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.bedtime_outlined, color: designPurple),
                  title: Text('Giờ nghỉ ngơi'),
                  subtitle: Text('Chưa có dữ liệu'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          card(
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gợi ý cho bạn',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Nghỉ mắt vài phút khi bạn muốn. '
                        'Không suy đoán tổn thương não.',
                      ),
                    ],
                  ),
                ),
                mascot('brain', size: 82),
              ],
            ),
          ),
        ],
      );

  Widget settingsPage() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heading('Cài đặt', 'Tùy chỉnh trợ lý theo sở thích'),
          card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhân vật trợ lý',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                ListTile(
                  leading: mascot(character, size: 60),
                  title: Text(characterOptions[character] ?? 'Bộ Não'),
                  subtitle: const Text('Chạm để đổi nhân vật'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(charactersPage()),
                ),
                SizedBox(
                  height: 68,
                  child: Row(
                    children: [
                      for (final id in characterOptions.keys)
                        Expanded(
                          child: InkWell(
                            onTap: () => open(charactersPage()),
                            child: mascot(id, size: 52),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          card(
            const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.volume_up_outlined, color: designPurple),
                  title: Text('Giọng nói & phản hồi'),
                  subtitle: Text('Chưa hỗ trợ giọng nói'),
                ),
                Divider(),
                ListTile(
                  leading:
                      Icon(Icons.psychology_alt_outlined, color: designPurple),
                  title: Text('Hành vi & tính cách'),
                  subtitle: Text('Nhắc nhở nhẹ nhàng'),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.auto_awesome, color: designPurple),
                  title: Text('Kết nối Google Gemini'),
                  subtitle:
                      Text('Chưa kết nối; cần đồng ý trước khi gửi dữ liệu'),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.devices_outlined, color: designPurple),
                  title: Text('Đồng bộ nhiều thiết bị'),
                  subtitle: Text('Chưa hỗ trợ — dữ liệu cục bộ'),
                ),
                Divider(),
                ListTile(
                  leading:
                      Icon(Icons.privacy_tip_outlined, color: designPurple),
                  title: Text('Dữ liệu & Quyền riêng tư'),
                  subtitle: Text('Chưa đọc thông tin thiết bị'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          card(
            Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.notifications_active_outlined,
                    color: designPurple,
                  ),
                  title: const Text('Nhắc việc & Thông báo'),
                  subtitle: Text(_remindersEnabled
                      ? 'Đã bật nhắc việc theo hạn trên Android'
                      : 'Tắt mặc định · yêu cầu quyền khi bật'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(reminderSetupPage()),
                ),
                const Divider(),
                ListTile(
                  leading:
                      const Icon(Icons.widgets_outlined, color: designPurple),
                  title: const Text('Widget màn hình chính'),
                  subtitle: const Text(
                      'Brain, công việc và Tập trung ngoài ứng dụng'),
                  onTap: () => open(homeWidgetSetupPage()),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.tune_rounded, color: designPurple),
                  title: const Text('Điều khiển nhanh Android'),
                  subtitle:
                      const Text('Thêm ô Tập trung, Việc hôm nay và Ghi nhanh'),
                  onTap: () => open(quickSettingsSetupPage()),
                ),
                const Divider(),
                ListTile(
                  leading:
                      const Icon(Icons.note_alt_outlined, color: designPurple),
                  title: const Text('Ghi chú hiện có'),
                  onTap: openNotes,
                ),
                ListTile(
                  leading: const Icon(Icons.open_in_new, color: designPurple),
                  title: const Text('Trợ lý nổi Android'),
                  onTap: () => open(overlayPage()),
                ),
                ListTile(
                  leading: const Icon(Icons.pets_outlined, color: designPurple),
                  title: const Text('Thư viện animation Cún'),
                  onTap: () => open(const DogAnimationGalleryPage()),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.smart_toy_outlined,
                    color: designPurple,
                  ),
                  title: const Text('Thư viện animation Robot'),
                  onTap: () => open(const RobotAnimationGalleryPage()),
                ),
              ],
            ),
          ),
        ],
      );

  // This route has its own rebuild scope: the parent shell's setState does
  // not automatically rebuild a Widget already pushed onto Navigator.
  Widget reminderSetupPage() => StatefulBuilder(
        builder: (sheetContext, refreshSheet) {
          final android =
              Theme.of(sheetContext).platform == TargetPlatform.android;
          return Scaffold(
            backgroundColor: designBackground,
            appBar: AppBar(title: const Text('Nhắc việc & Thông báo')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                heading('Brain nhắc đúng lúc', 'Chỉ thông báo khi bạn đồng ý'),
                card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.notifications_active_outlined,
                          color: designPurple),
                      title: const Text('Nhắc việc theo thời hạn'),
                      subtitle: Text(android
                          ? (_remindersEnabled
                              ? 'Đã cho phép và bật nhắc việc trên thiết bị'
                              : 'Đang tắt · bật để xin quyền thông báo')
                          : 'Chưa triển khai trên iOS'),
                      value: android && _remindersEnabled,
                      onChanged: android && !_remindersBusy
                          ? (value) async {
                              final update = _changeReminders(value);
                              refreshSheet(
                                  () {}); // show busy while OS asks permission
                              await update;
                              if (sheetContext.mounted) refreshSheet(() {});
                            }
                          : null,
                    ),
                    const Divider(),
                    const Text(
                      'Khi đến hạn, OneLife gửi thông báo hệ thống với hai nút '
                      'Hoàn thành và Nhắc lại 10 phút. Bạn không phải mở app '
                      'để thực hiện hai thao tác này.',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Chỉ công việc có thời hạn trong tương lai được lên lịch. '
                      'Android có thể trì hoãn thông báo khi tiết kiệm pin hoặc '
                      'trong Doze; đây không phải báo thức chính xác từng phút.',
                      style: TextStyle(color: Color(0xFF796D8B)),
                    ),
                  ],
                )),
                const SizedBox(height: 14),
                card(const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Riêng tư & quyền kiểm soát',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 10),
                    Text('Android 13 trở lên sẽ yêu cầu quyền thông báo.'),
                    Text('Màn hình khóa chỉ hiển thị lời nhắc chung, '
                        'không hiện tên công việc.'),
                    Text('Tắt nhắc việc sẽ hủy các lịch đã tạo nhưng '
                        'không xóa công việc trong SQLite.'),
                    Text('Nhắc lại 10 phút được lưu trên thiết bị để tiếp tục '
                        'sau khi điện thoại khởi động lại.'),
                    SizedBox(height: 12),
                    Text(
                        'Nếu trước đó bạn đã từ chối quyền, '
                        'hãy mở Cài đặt hệ thống → Ứng dụng → OneLife → Thông báo.',
                        style:
                            TextStyle(color: Color(0xFF796D8B), fontSize: 12)),
                  ],
                )),
              ],
            ),
          );
        },
      );

  Widget homeWidgetSetupPage() {
    final android = Theme.of(context).platform == TargetPlatform.android;
    return Scaffold(
      backgroundColor: designBackground,
      appBar: AppBar(title: const Text('Widget màn hình chính')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heading('OneLife bên cạnh bạn', 'Widget thật do Android hiển thị'),
          card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                mascot('brain', size: 88),
                const SizedBox(width: 12),
                const Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bộ Não · OneLife',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18)),
                    SizedBox(height: 5),
                    Text('Xem số việc chưa xong và trạng thái tập trung.',
                        style: TextStyle(color: Color(0xFF796D8B))),
                  ],
                )),
              ]),
              const SizedBox(height: 14),
              const Text('Các nút: Công việc · Ghi nhanh · Tập trung',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              const Text(
                  'Dữ liệu lấy từ SQLite trên thiết bị. Không hiện '
                  'tên công việc trên widget; số việc được ẩn khi máy khóa. '
                  'Widget không tự tạo báo thức hay gửi dữ liệu ra ngoài.',
                  style: TextStyle(color: Color(0xFF796D8B))),
              const SizedBox(height: 14),
              if (android)
                FilledButton.icon(
                  onPressed: _requestPinWidget,
                  icon: const Icon(Icons.add_to_home_screen),
                  label: const Text('Thêm widget vào màn hình chính'),
                )
              else
                const Text('iOS cần widget WidgetKit riêng; '
                    'bản Android không hoạt động trong iOS.'),
            ],
          )),
          const SizedBox(height: 14),
          card(const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cách thêm thủ công',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(height: 10),
              Text('1. Giữ chạm một vùng trống trên màn hình chính.'),
              Text('2. Chọn Widget → OneLife.'),
              Text('3. Kéo widget lên màn hình chính.'),
              SizedBox(height: 10),
              Text(
                  'Android 8 trở lên có thể hiện lời mời ghim widget '
                  'nếu launcher hỗ trợ. Màu sắc và kích thước còn phụ thuộc '
                  'launcher của điện thoại.',
                  style: TextStyle(color: Color(0xFF796D8B), fontSize: 12)),
            ],
          )),
        ],
      ),
    );
  }

  Widget quickSettingsSetupPage() {
    final android = Theme.of(context).platform == TargetPlatform.android;
    return Scaffold(
      backgroundColor: designBackground,
      appBar: AppBar(title: const Text('Điều khiển nhanh')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heading(
              'OneLife ngoài ứng dụng', 'Thêm lối tắt vào thanh vuốt xuống'),
          card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Android Quick Settings',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.center_focus_strong, color: designPurple),
                title: const Text('Tập trung · 25 phút'),
                subtitle: const Text('Chạm để bắt đầu, tạm dừng hoặc tiếp tục'),
                trailing: android
                    ? OutlinedButton(
                        onPressed: () => _requestQuickSettingsTile('focus'),
                        child: const Text('Thêm'),
                      )
                    : null,
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.fact_check_outlined, color: designPurple),
                title: const Text('Việc hôm nay'),
                subtitle: const Text(
                  'Xem số việc chưa xong và mở danh sách công việc',
                ),
                trailing: android
                    ? OutlinedButton(
                        onPressed: () => _requestQuickSettingsTile('today'),
                        child: const Text('Thêm'),
                      )
                    : null,
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.edit_note_rounded, color: designPurple),
                title: const Text('Ghi nhanh'),
                subtitle:
                    const Text('Mở giao diện tạo công việc trên điện thoại'),
                trailing: android
                    ? OutlinedButton(
                        onPressed: () => _requestQuickSettingsTile('capture'),
                        child: const Text('Thêm'),
                      )
                    : null,
              ),
              if (!android)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Thiết bị này không có Android Quick Settings. '
                    'iOS Control Center cần phần tích hợp native riêng.',
                    style: TextStyle(color: Color(0xFF796D8B)),
                  ),
                ),
            ],
          )),
          const SizedBox(height: 14),
          card(const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nếu không xuất hiện lời mời thêm ô',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(height: 9),
              Text('1. Vuốt từ cạnh trên màn hình xuống hai lần.'),
              Text('2. Chọn Sửa hoặc biểu tượng bút chì (tùy hãng máy).'),
              Text(
                  '3. Thêm Tập trung / Việc hôm nay / Ghi nhanh vào Quick Settings.'),
              SizedBox(height: 12),
              Text(
                'Android 13 trở lên có thể hiện hộp thoại thêm ô của hệ thống; '
                'bạn quyết định có thêm hay không. Màu và vị trí tile '
                'do hệ điều hành quản lý.',
                style: TextStyle(color: Color(0xFF796D8B), fontSize: 12),
              ),
              SizedBox(height: 8),
              Text(
                'Ghi nhanh yêu cầu mở khóa trước khi nhập công việc. '
                'Không hiển thị nội dung riêng tư trong thanh trạng thái.',
                style: TextStyle(color: Color(0xFF796D8B), fontSize: 12),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget charactersPage() => Scaffold(
        appBar: AppBar(title: const Text('Chọn nhân vật')),
        backgroundColor: designBackground,
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            heading('Bạn đồng hành', '5 nhân vật Glossy Kawaii'),
            const Text(
              'Brain dùng animation V2; nhân vật khác '
              'đang hiển thị ảnh master khi chưa tích hợp đầy đủ animation.',
            ),
            const SizedBox(height: 14),
            for (final entry in characterOptions.entries) ...[
              card(
                ListTile(
                  leading: mascot(entry.key, size: 62),
                  title: Text(entry.value),
                  subtitle: Text(
                    entry.key == character ? 'Đang sử dụng' : 'Chọn làm trợ lý',
                  ),
                  trailing: Icon(
                    entry.key == character
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: designPurple,
                  ),
                  onTap: () => selectCharacter(entry.key),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      );

  Widget assistantPage() => Scaffold(
        appBar: AppBar(title: const Text('Trợ lý OneLife')),
        backgroundColor: designBackground,
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            card(
              Column(
                children: [
                  mascot('brain', size: 150),
                  const Text(
                    'Mình giúp bạn nhớ từng việc nhỏ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Trợ lý AI hội thoại chưa được kết nối. '
                    'Không gửi dữ liệu cá nhân lên mạng.',
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: addTask,
                    icon: const Icon(Icons.add_task),
                    label: const Text('Thêm việc cục bộ'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget overlayPage() => const BrainOverlaySetupPage();

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!),
            FilledButton(onPressed: reload, child: const Text('Thử lại')),
          ],
        ),
      );
    } else {
      body = switch (tab) {
        1 => tasksPage(),
        3 => habitsPage(),
        4 => settingsPage(),
        _ => homePage(),
      };
    }
    return Scaffold(
      backgroundColor: designBackground,
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          height: 72,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFECE2FF),
          selectedIndex: tab,
          onDestinationSelected: (index) {
            if (index == 2) {
              addTask();
            } else {
              setState(() => tab = index);
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: Icon(Icons.check_box_outlined),
              label: 'Việc cần làm',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline, size: 30),
              label: 'Thêm',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              label: 'Thói quen',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Tôi',
            ),
          ],
        ),
      ),
    );
  }
}
