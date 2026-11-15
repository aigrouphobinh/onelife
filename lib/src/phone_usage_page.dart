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
  int? minutes;
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
      final data = await bridge.invokeMapMethod<String, dynamic>('usageSnapshot');
      if (!mounted) return;
      setState(() {
        granted = data?['granted'] == true;
        available = data?['available'] == true;
        minutes = available && data?['minutes'] is int
            ? data!['minutes'] as int : null;
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
      final answer = await bridge.invokeMethod<String>('openUsageAccessSettings');
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
      'break' => 'Có thể nghỉ mắt một chút',
      'high' => 'Đã dùng nhiều — cân nhắc nghỉ',
      _ => 'Chưa đánh giá',
    };
    final color = switch (tier) {
      'balanced' => const Color(0xFF4FB58E),
      'break' => const Color(0xFFF6A040),
      'high' => const Color(0xFFE75568),
      _ => const Color(0xFFA995C6),
    };
    final reading = minutes == null
        ? 'Chưa có dữ liệu'
        : minutes == 0
            ? 'Dưới 1 phút quan sát được'
            : '\${minutes! ~/ 60} giờ \${minutes! % 60} phút';
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
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 12),
              if (loading)
                const LinearProgressIndicator(color: purple)
              else if (!android)
                const Text('Tính năng cần Android Usage Access. iOS yêu cầu tích hợp Screen Time riêng.')
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
                Text(reading, style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: ink)),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.circle, size: 14, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(stateLabel,
                      style: TextStyle(fontWeight: FontWeight.w700, color: color))),
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
          card(const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Brain phản ứng ra sao?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              SizedBox(height: 10),
              Text('Dưới 90 phút: dấu trạng thái xanh.'),
              Text('90 đến dưới 180 phút: gợi ý nghỉ, màu hổ phách.'),
              Text('Từ 180 phút: gợi ý tạm nghỉ, màu hồng.'),
              SizedBox(height: 10),
              Text('Khi Focus đang chạy, Brain ưu tiên hoạt ảnh Focus có sẵn. '
                  'Chưa có quyền hoặc chưa đủ dữ liệu: giữ trạng thái trung tính.',
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
              Text('Số phút chỉ xấp xỉ, có thể thiếu thời gian khi sự kiện '
                  'bị mất hoặc phiên dùng bắt đầu trước 00:00. '
                  'Đây không phải kết quả sức khỏe hay chẩn đoán tổn thương não.',
                  style: TextStyle(color: Color(0xFF796D8B))),
              SizedBox(height: 10),
              Text('Có thể thu hồi quyền trong Cài đặt Android → '
                  'Truy cập dữ liệu sử dụng.',
                  style: TextStyle(color: Color(0xFF796D8B))),
            ],
          )),
        ],
      ),
    );
  }
}
