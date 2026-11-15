import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Android UsageEvents summary only. Never replace absent readings with zero.
class PhoneUsagePage extends StatefulWidget {
  const PhoneUsagePage({super.key});

  @override
  State<PhoneUsagePage> createState() => _PhoneUsagePageState();
}

class _PhoneUsagePageState extends State<PhoneUsagePage>
    with WidgetsBindingObserver {
  static const bridge = MethodChannel('onelife/quick_capture');
  static const ink = Color(0xFF21183C);
  static const purple = Color(0xFF8054E6);
  bool android = false, started = false, loading = true;
  bool granted = false, available = false;
  bool savingGoal = false;
  int? minutes;
  int? goalMinutes;
  String tier = 'unknown';
  String? notice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    android = Theme.of(context).platform == TargetPlatform.android;
    if (!started) {
      started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) refresh();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> refresh() async {
    if (!android) {
      if (mounted) setState(() => loading = false);
      return;
    }
    if (mounted) setState(() => loading = true);
    try {
      final data =
          await bridge.invokeMapMethod<String, dynamic>('usageSnapshot');
      if (!mounted) return;
      setState(() {
        granted = data?['granted'] == true;
        available = data?['available'] == true;
        minutes = available && data?['minutes'] is int
            ? data!['minutes'] as int
            : null;
        goalMinutes = data?['goalMinutes'] is int
            ? data!['goalMinutes'] as int
            : null;
        tier = available ? (data?['tier'] as String? ?? 'unknown') : 'unknown';
        loading = false;
      });
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          available = false;
          granted = false;
          loading = false;
          notice = 'Phiên bản này chưa có tích hợp Usage Access Android.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          available = false;
          loading = false;
          notice = 'Không đọc được dữ liệu của Android.';
        });
      }
    }
  }

  Future<void> requestAccess() async {
    if (!android) return;
    try {
      final answer =
          await bridge.invokeMethod<String>('openUsageAccessSettings');
      if (!mounted) return;
      setState(() {
        notice = answer == 'opened'
            ? 'Đã mở Cài đặt. Bạn cần tự cấp quyền rồi trở lại OneLife.'
            : 'Không mở được Cài đặt quyền trên thiết bị này.';
      });
      // Opening Settings is not proof that the user granted access.
    } catch (_) {
      if (mounted) setState(() => notice = 'Không mở được mục quyền sử dụng.');
    }
  }

  Future<void> saveDailyGoal(int? chosen) async {
    if (!android || savingGoal) return;
    setState(() => savingGoal = true);
    try {
      final saved = await bridge.invokeMethod<bool>(
        'setUsageDailyGoal',
        <String, Object?>{'minutes': chosen},
      );
      if (!mounted) return;
      if (saved == true) {
        setState(() {
          goalMinutes = chosen;
          notice = chosen == null
              ? 'Đã tắt mục tiêu. Brain sẽ hiển thị trạng thái trung tính.'
              : 'Đã lưu mục tiêu hằng ngày trên thiết bị.';
        });
        await refresh();
      } else {
        setState(() => notice = 'Android chưa lưu được mục tiêu.');
      }
    } on MissingPluginException {
      if (mounted) setState(() => notice = 'APK chưa có chức năng lưu mục tiêu.');
    } catch (_) {
      if (mounted) setState(() => notice = 'Không thể lưu mục tiêu.');
    } finally {
      if (mounted) setState(() => savingGoal = false);
    }
  }

  Widget card(Widget child) => Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(23),
        child: Padding(padding: const EdgeInsets.all(18), child: child),
      );

  @override
  Widget build(BuildContext context) {
    final stateLabel = switch (tier) {
      'balanced' => 'Nhịp sử dụng nhẹ',
      'strained' => 'Gần đến mục tiêu — có thể nghỉ mắt',
      'overloaded' => 'Đã đạt mục tiêu bạn chọn — cân nhắc nghỉ',
      _ => 'Chưa đánh giá',
    };
    final color = switch (tier) {
      'balanced' => const Color(0xFF4FB58E),
      'strained' => const Color(0xFFF6A040),
      'overloaded' => const Color(0xFFE75568),
      _ => const Color(0xFFA995C6),
    };
    final reading = minutes == null
        ? 'Chưa có dữ liệu'
        : minutes == 0
            ? 'Dưới 1 phút quan sát được'
            : '${minutes! ~/ 60} giờ ${minutes! % 60} phút';
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FF),
      appBar: AppBar(
        title: const Text('Thói quen dùng điện thoại'),
        backgroundColor: const Color(0xFFF8F3FF),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Brain nhìn theo nhịp sử dụng',
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 12),
              if (loading)
                const LinearProgressIndicator(color: purple)
              else if (!android)
                const Text(
                    'Tính năng cần Android Usage Access. iOS yêu cầu tích hợp Screen Time riêng.')
              else if (!granted) ...[
                const Text('Chưa cấp quyền Truy cập dữ liệu sử dụng. '
                    'OneLife không tự đoán thời gian sử dụng.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: requestAccess,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Mở Cài đặt quyền sử dụng'),
                ),
              ] else if (!available || minutes == null)
                const Text('Android chưa cung cấp đủ sự kiện. '
                    'Thiếu dữ liệu không có nghĩa là dùng 0 phút.')
              else ...[
                const Text('Ước tính ứng dụng foreground hôm nay',
                    style: TextStyle(color: Color(0xFF796D8B))),
                const SizedBox(height: 7),
                Text(reading,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900, color: ink)),
                const SizedBox(height: 10),
                if (goalMinutes == null)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Chưa đặt mục tiêu riêng — Brain sẽ giữ trạng thái trung tính.',
                      style: TextStyle(color: Color(0xFF796D8B)),
                    ),
                  ),
                Row(children: [
                  Icon(Icons.circle, size: 14, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(stateLabel,
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: color))),
                ]),
              ],
              if (notice != null) ...[
                const SizedBox(height: 12),
                Text(notice!, style: const TextStyle(color: ink)),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: loading ? null : refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Đọc lại dữ liệu'),
              ),
            ],
          )),
          const SizedBox(height: 14),
          card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mục tiêu phản ánh hằng ngày',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 9),
              const Text('Tùy chọn của bạn, không phải giới hạn y tế. '
                  'Nếu không chọn, Brain không tự gắn nhãn quá tải.'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: <int>[60, 120, 180, 240, 360].map((value) {
                  return ChoiceChip(
                    label: Text('${value ~/ 60} giờ'),
                    selected: goalMinutes == value,
                    onSelected: android && !savingGoal
                        ? (_) => saveDailyGoal(value)
                        : null,
                  );
                }).toList(),
              ),
              if (goalMinutes != null) ...[
                const SizedBox(height: 8),
                Text('Mục tiêu hiện tại: ${goalMinutes! ~/ 60} giờ '
                    '${goalMinutes! % 60} phút',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: ink)),
                TextButton.icon(
                  onPressed: android && !savingGoal
                      ? () => saveDailyGoal(null)
                      : null,
                  icon: const Icon(Icons.close),
                  label: const Text('Tắt mục tiêu'),
                ),
              ],
              if (savingGoal)
                const LinearProgressIndicator(color: purple),
            ],
          )),
          const SizedBox(height: 14),
          card(const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hoạt ảnh Brain theo mục tiêu tự chọn',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              SizedBox(height: 10),
              Text('Dưới 80% mục tiêu: Balanced (8 khung).'),
              Text('Từ 80% đến dưới 100%: Strained (10 khung).'),
              Text('Từ 100% trở lên: Overloaded (12 khung).'),
              SizedBox(height: 10),
              Text('Focus luôn ưu tiên hoạt ảnh Focus có sẵn. '
                  'Không có quyền, dữ liệu hay mục tiêu: Brain ở Idle trung tính.',
                  style: TextStyle(color: Color(0xFF796D8B))),
              SizedBox(height: 8),
              Text('Các atlas biểu cảm hiện là bản ứng viên cần duyệt hình '
                  'và chạy trên điện thoại thật, không phải artwork final.',
                  style: TextStyle(color: Color(0xFF796D8B))),
            ],
          )),
          const SizedBox(height: 14),
          card(const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Riêng tư và giới hạn',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              SizedBox(height: 10),
              Text('Chỉ dùng dữ liệu Android cấp sau khi bạn cho phép. '
                  'Không lưu danh sách ứng dụng hay lịch sử sự kiện '
                  'và không gửi dữ liệu lên máy chủ.'),
              SizedBox(height: 10),
              Text(
                  'Số phút chỉ xấp xỉ, có thể thiếu thời gian khi sự kiện '
                  'bị mất hoặc phiên dùng bắt đầu trước 00:00. '
                  'Đây không phải kết quả sức khỏe hay chẩn đoán tổn thương não.',
                  style: TextStyle(color: Color(0xFF796D8B))),
              SizedBox(height: 10),
              Text(
                  'Có thể thu hồi quyền trong Cài đặt Android → '
                  'Truy cập dữ liệu sử dụng.',
                  style: TextStyle(color: Color(0xFF796D8B))),
            ],
          )),
        ],
      ),
    );
  }
}
