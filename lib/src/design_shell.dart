import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodCall, MethodChannel, MissingPluginException;

import 'glossy_sprite.dart';
import 'focus_page.dart';
import 'onelife_store.dart';
import 'note_repository.dart';
import 'home_page.dart';
import 'dog_animation_gallery.dart';
import 'robot_animation_gallery.dart';

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

class _OneLifeDesignShellState extends State<OneLifeDesignShell> {
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

  @override
  void initState() {
    super.initState();
    _captureChannel.setMethodCallHandler(_handleNativeAction);
    reload();
    _consumeLaunchAction();
  }

  Future<void> _handleNativeAction(MethodCall call) async {
    if (call.method == 'openCapture') {
      _queueQuickCapture();
    }
  }

  Future<void> _consumeLaunchAction() async {
    try {
      final action =
          await _captureChannel.invokeMethod<String>('consumeLaunchAction');
      if (action == 'capture') {
        _queueQuickCapture();
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
  void dispose() {
    _captureChannel.setMethodCallHandler(null);
    super.dispose();
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

  Future<void> addTask() async {
    String title = '';
    DateTime? dueAt;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: const Text('Thêm việc mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Tên công việc'),
                  onChanged: (value) => update(() => title = value),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: now,
                      firstDate: DateTime(now.year, now.month, now.day),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (date == null || !dialogContext.mounted) return;
                    final time = await showTimePicker(
                      context: dialogContext,
                      initialTime: TimeOfDay.now(),
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
                const SizedBox(height: 8),
                const Text(
                  'Lưu trên thiết bị; chưa tự cài báo thức.',
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
      await store.addTask(title: title, dueAt: dueAt);
      await reload();
      notify('Đã lưu công việc trên thiết bị');
    } catch (_) {
      notify('Không thể lưu công việc');
    }
  }

  Future<void> toggle(OneLifeTask task, bool done) async {
    try {
      await store.setTaskCompleted(task.id, done);
      await reload();
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
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF837695)),
                ),
              ],
            ),
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
              !t.dueAt!.isAfter(DateTime(now.year, now.month, now.day + 1)),
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
            t.dueAt!.isAfter(DateTime(now.year, now.month, now.day + 1));
      }
      return t.dueAt == null ||
          !t.dueAt!.isAfter(DateTime(now.year, now.month, now.day + 1));
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
            const ListTile(
              leading: Icon(
                Icons.notifications_paused_outlined,
                color: designPurple,
              ),
              title: Text('Báo thức chưa được kích hoạt'),
              subtitle: Text(
                'Chưa tích hợp quyền và lịch thông báo Android/iOS.',
              ),
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
                  leading:
                      const Icon(Icons.note_alt_outlined, color: designPurple),
                  title: const Text('Ghi chú hiện có'),
                  onTap: () => open(HomePage(repository: NoteRepository())),
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

  Widget overlayPage() => Scaffold(
        appBar: AppBar(title: const Text('Trợ lý nổi')),
        backgroundColor: designBackground,
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            card(
              Column(
                children: [
                  mascot('brain', size: 130),
                  const Text(
                    'Bản xem trước, chưa bật overlay',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Android cần quyền hiển thị trên ứng dụng khác. '
                    'iOS không cho phép overlay nổi tự do. '
                    'Màn hình này không yêu cầu quyền hoặc tạo lớp phủ giả.',
                  ),
                ],
              ),
            ),
          ],
        ),
      );

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
