import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'phone_usage_page.dart';

/// Real, consent-gated Android UsageEvents only; absent days stay unknown.
/// This is a panel inside the existing Thói quen tab, not another demo page.
class UsageHistoryPanel extends StatefulWidget {
  const UsageHistoryPanel({super.key});

  @override
  State<UsageHistoryPanel> createState() => _UsageHistoryPanelState();
}

class _UsageHistoryPanelState extends State<UsageHistoryPanel>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('onelife/quick_capture');
  static const _purple = Color(0xFF8054E6);
  static const _ink = Color(0xFF21183C);

  int days = 1;
  int observedDays = 0;
  int _requestVersion = 0;
  bool initialized = false;
  bool android = false;
  bool loading = true;
  bool granted = false;
  bool available = false;
  String? notice;
  List<_UsageDay> readings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    android = Theme.of(context).platform == TargetPlatform.android;
    if (!initialized) {
      initialized = true;
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
    _requestVersion++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> refresh() async {
    final version = ++_requestVersion;
    if (!android) {
      if (mounted) setState(() => loading = false);
      return;
    }
    setState(() {
      loading = true;
      notice = null;
    });
    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'usageHistory',
        <String, Object>{'days': days},
      );
      if (!mounted || version != _requestVersion) return;
      final rawDays = response?['days'];
      final parsed = <_UsageDay>[];
      if (rawDays is List) {
        for (final value in rawDays) {
          if (value is! Map) continue;
          final date = value['date'];
          final minutes = value['minutes'];
          if (date is! String ||
              !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
            continue;
          }
          parsed.add(
            _UsageDay(
              date,
              minutes is int && minutes >= 0 ? minutes : null,
            ),
          );
        }
      }
      setState(() {
        granted = response?['granted'] == true;
        available = response?['available'] == true &&
            parsed.any((day) => day.minutes != null);
        readings = granted ? parsed : [];
        observedDays = readings.where((day) => day.minutes != null).length;
        loading = false;
      });
    } on MissingPluginException {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        loading = false;
        available = false;
        granted = false;
        readings = [];
        notice = 'APK chưa tích hợp lịch sử sử dụng điện thoại.';
      });
    } catch (_) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        loading = false;
        available = false;
        readings = [];
        notice = 'Không thể đọc dữ liệu sử dụng từ Android.';
      });
    }
  }

  Future<void> requestUsageAccess() async {
    if (!android) return;
    try {
      final response =
          await _channel.invokeMethod<String>('openUsageAccessSettings');
      if (!mounted) return;
      setState(() => notice = response == 'opened'
          ? 'Hãy cấp quyền trong Cài đặt Android rồi quay lại OneLife.'
          : 'Không mở được Cài đặt quyền trên thiết bị này.');
    } catch (_) {
      if (mounted) {
        setState(() => notice = 'Không mở được Cài đặt quyền.');
      }
    }
  }

  static String formatMinutes(int minutes) {
    if (minutes == 0) return 'Dưới 1 phút quan sát được';
    if (minutes < 60) return '$minutes phút';
    return '${minutes ~/ 60} giờ ${minutes % 60} phút';
  }

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

  @override
  Widget build(BuildContext context) {
    final validMinutes = readings
        .where((day) => day.minutes != null)
        .fold<int>(0, (sum, day) => sum + day.minutes!);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Thói quen',
          style:
              TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _ink),
        ),
        const SizedBox(height: 5),
        const Text(
          'Theo dữ liệu Android quan sát được, không suy đoán sức khỏe',
          style: TextStyle(color: Color(0xFF796D8B)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final option in [1, 7, 30])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ChoiceChip(
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(
                        option == 1 ? 'Hôm nay' : '$option ngày',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    selected: days == option,
                    onSelected: (_) {
                      if (days == option) return;
                      setState(() => days = option);
                      refresh();
                    },
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        card(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thời gian sử dụng quan sát được',
              style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
            ),
            const SizedBox(height: 12),
            if (loading)
              const LinearProgressIndicator(color: _purple)
            else if (!android)
              const Text(
                'iOS cần tích hợp Screen Time và quyền tương ứng; '
                'chưa có dữ liệu để hiển thị.',
              )
            else if (!granted) ...[
              const Text(
                'Chưa cấp quyền Truy cập dữ liệu sử dụng. '
                'OneLife không tự tạo số giờ hoặc biểu đồ.',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: requestUsageAccess,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Mở Cài đặt quyền sử dụng'),
              ),
            ] else if (!available || observedDays == 0)
              const Text(
                'Android chưa cung cấp đủ sự kiện trong khoảng đã chọn. '
                'Không có dữ liệu không đồng nghĩa 0 phút.',
              )
            else ...[
              Text(
                formatMinutes(validMinutes),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                days == 1
                    ? 'Ước tính trong hôm nay'
                    : 'Tổng ước tính trên $observedDays/$days ngày có dữ liệu',
                style: const TextStyle(color: Color(0xFF796D8B)),
              ),
              if (days > 1) ...[
                const SizedBox(height: 8),
                Text(
                  'Trung bình ngày có dữ liệu: '
                  '${formatMinutes(validMinutes ~/ observedDays)}',
                ),
              ],
            ],
            if (notice != null) ...[
              const SizedBox(height: 12),
              Text(notice!, style: const TextStyle(color: _ink)),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: loading ? null : refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Đọc lại dữ liệu'),
            ),
          ],
        )),
        if (!loading && android && granted && readings.isNotEmpty) ...[
          const SizedBox(height: 14),
          card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Theo ngày',
                style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
              ),
              const SizedBox(height: 8),
              for (final day in readings.reversed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    '${day.date.substring(8, 10)}/'
                    '${day.date.substring(5, 7)}/'
                    '${day.date.substring(0, 4)}',
                  ),
                  trailing: Text(
                    day.minutes == null
                        ? 'Chưa có dữ liệu'
                        : formatMinutes(day.minutes!),
                  ),
                ),
            ],
          )),
        ],
        const SizedBox(height: 14),
        card(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mục tiêu & Nghỉ cùng Brain',
              style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
            ),
            const SizedBox(height: 6),
            const Text(
              'Đặt mục tiêu riêng hoặc mở hẹn giờ nghỉ. '
              'Có thể nghỉ mà không cấp quyền sử dụng.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.psychology_outlined),
              label: const Text('Mở mục tiêu và nghỉ'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PhoneUsagePage(),
                ),
              ),
            ),
          ],
        )),
        const SizedBox(height: 14),
        const Text(
          'Chỉ đọc sự kiện foreground khi bạn cấp quyền. '
          'Số phút có thể thiếu hoặc chồng lấp; '
          'không lưu lịch sử ứng dụng, không gửi lên máy chủ. '
          'Ngày thiếu sự kiện sẽ không được tính là 0 phút.',
          style: TextStyle(color: Color(0xFF796D8B), fontSize: 12),
        ),
      ],
    );
  }
}

class _UsageDay {
  const _UsageDay(this.date, this.minutes);
  final String date;
  final int? minutes;
}
