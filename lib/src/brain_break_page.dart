import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glossy_sprite.dart';

/// User-started break, reconciled from Android's persisted deadline.
class BrainBreakPage extends StatefulWidget {
  const BrainBreakPage({super.key});

  @override
  State<BrainBreakPage> createState() => _BrainBreakPageState();
}

class _BrainBreakPageState extends State<BrainBreakPage>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('onelife/quick_capture');
  static const _purple = Color(0xFF8054E6);
  static const _ink = Color(0xFF21183C);
  static const _background = Color(0xFFF8F3FF);

  static const _resting = GlossySpriteSpec(
    assetPath: 'assets/characters-v2/brain/resting/sheet.png',
    frames: 10,
    columns: 4,
    frameWidth: 256,
    frameHeight: 256,
    frameDurationMs: 205,
    loop: true,
  );
  static const _recovering = GlossySpriteSpec(
    assetPath: 'assets/characters-v2/brain/recovering/sheet.png',
    frames: 12,
    columns: 4,
    frameWidth: 256,
    frameHeight: 256,
    frameDurationMs: 125,
    loop: false,
  );
  static const _idle = GlossySpriteSpec(
    assetPath: 'assets/characters-v2/brain/idle/sheet.png',
    frames: 8,
    columns: 4,
    frameWidth: 256,
    frameHeight: 256,
    frameDurationMs: 140,
    loop: true,
  );

  Timer? _ticker;
  bool _android = false;
  bool _checked = false;
  bool _loading = true;
  bool _busy = false;
  bool _observed = false;
  int _selected = 5;
  int _duration = 0;
  int _deadlineMs = 0;
  int _recoveryStartMs = 0;
  int _recoveryDurationMs = 1500;
  int _sequence = 0;
  String _phase = 'idle';
  String? _notice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _android = Theme.of(context).platform == TargetPlatform.android;
    if (!_checked) {
      _checked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _read();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _read();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  int get _secondsRemaining {
    if (_phase != 'resting' || _deadlineMs <= 0) return 0;
    return ((_deadlineMs - DateTime.now().millisecondsSinceEpoch + 999) ~/ 1000)
        .clamp(0, _duration * 60)
        .toInt();
  }

  String get _clock {
    final seconds = _secondsRemaining;
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
  }

  void _accept(Map<String, dynamic> data) {
    final error = data['error'] as String?;
    if (error != null) {
      setState(() {
        _notice = switch (error) {
          'already_active' => 'Một phiên nghỉ đã được bắt đầu.',
          'not_resting' => 'Không có phiên nghỉ nào đang chạy.',
          'unsupported_duration' => 'Chỉ hỗ trợ 5, 10 hoặc 15 phút.',
          _ => 'Không thể lưu phiên nghỉ. Hãy thử lại.',
        };
      });
      return;
    }
    setState(() {
      _phase = data['phase'] as String? ?? 'idle';
      _duration = data['durationMinutes'] as int? ?? 0;
      _deadlineMs = data['deadlineMs'] as int? ?? 0;
      _recoveryStartMs = data['recoveryStartMs'] as int? ?? 0;
      _recoveryDurationMs = data['recoveryDurationMs'] as int? ?? 1500;
      _sequence = data['sequence'] as int? ?? 0;
      _observed = true;
      _loading = false;
      _notice = null;
    });
  }

  Future<void> _read() async {
    if (!_android) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (_busy) return;
    try {
      final data =
          await _channel.invokeMapMethod<String, dynamic>('breakSnapshot');
      if (!mounted) return;
      if (data == null) {
        setState(() => _notice = 'Android chưa trả trạng thái phiên nghỉ.');
        return;
      }
      _accept(data);
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          _loading = false;
          _notice = 'Phiên bản Android chưa có bộ hẹn giờ nghỉ native.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _notice = 'Không đọc được phiên nghỉ đã lưu.';
        });
      }
    }
  }

  void _tick() {
    if (!mounted || _busy || !_observed) return;
    if (_phase == 'resting') {
      if (_secondsRemaining <= 0) {
        _read();
      } else {
        setState(() {});
      }
    } else if (_phase == 'recovering' &&
        _recoveryStartMs > 0 &&
        DateTime.now().millisecondsSinceEpoch >=
            _recoveryStartMs + _recoveryDurationMs) {
      _read();
    }
  }

  Future<void> _run(String method, {int? minutes}) async {
    if (!_android || _busy) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final data = await _channel.invokeMapMethod<String, dynamic>(
        method,
        minutes == null ? null : <String, Object>{'minutes': minutes},
      );
      if (!mounted) return;
      if (data != null) {
        _accept(data);
      } else {
        setState(() => _notice = 'Android không xác nhận được thao tác.');
      }
    } on MissingPluginException {
      if (mounted) setState(() => _notice = 'APK chưa có phiên nghỉ native.');
    } catch (_) {
      if (mounted) {
        setState(() => _notice = 'Không lưu được thao tác. Thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _surface(Widget child) => Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x164F366D),
        borderRadius: BorderRadius.circular(24),
        child: Padding(padding: const EdgeInsets.all(18), child: child),
      );

  @override
  Widget build(BuildContext context) {
    final current = _phase == 'resting'
        ? _resting
        : _phase == 'recovering'
            ? _recovering
            : _idle;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Nghỉ cùng Brain'),
        backgroundColor: _background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _surface(Column(
            children: [
              GlossySprite(
                key: ValueKey('brain-break-$_phase-$_sequence'),
                spec: current,
                size: 160,
                semanticLabel: switch (_phase) {
                  'resting' => 'Brain đang nghỉ theo yêu cầu của bạn',
                  'recovering' => 'Brain kết thúc nghỉ, hoạt ảnh một lần',
                  _ => 'Brain OneLife sẵn sàng khi bạn muốn nghỉ',
                },
              ),
              const SizedBox(height: 10),
              Text(
                switch (_phase) {
                  'resting' => 'Brain đang thư giãn',
                  'recovering' => 'Nghỉ xong — trở lại nhịp của bạn',
                  _ => 'Một chút nghỉ ngơi khi bạn muốn',
                },
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const CircularProgressIndicator()
              else if (!_android)
                const Text(
                  'Phiên nghỉ native hiện hỗ trợ Android; iOS chưa được tích hợp.',
                  textAlign: TextAlign.center,
                )
              else if (!_observed)
                const Text('Chưa đọc được trạng thái phiên nghỉ từ Android.')
              else if (_phase == 'resting')
                Text(
                  _clock,
                  style: const TextStyle(
                    color: _purple,
                    fontSize: 45,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                )
              else if (_phase == 'recovering')
                const Text('Hoạt ảnh Recovering phát đúng một lần.',
                    textAlign: TextAlign.center)
              else
                const Text('Chọn thời gian nghỉ phù hợp. '
                    'Không cần quyền theo dõi điện thoại.'),
              if (_notice != null) ...[
                const SizedBox(height: 12),
                Text(_notice!,
                    style: const TextStyle(color: Color(0xFFC9304A))),
              ],
            ],
          )),
          const SizedBox(height: 14),
          _surface(Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_phase == 'idle' && _android && _observed) ...[
                const Text('Bạn muốn nghỉ bao lâu?',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 9,
                  children: [5, 10, 15].map((value) {
                    return ChoiceChip(
                      label: Text('$value phút'),
                      selected: _selected == value,
                      onSelected: _busy
                          ? null
                          : (_) => setState(() => _selected = value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run('startBrainBreak', minutes: _selected),
                  icon: const Icon(Icons.nights_stay_outlined),
                  label: Text('Bắt đầu nghỉ $_selected phút'),
                ),
              ] else if (_phase == 'resting' && _android) ...[
                FilledButton.icon(
                  onPressed: _busy ? null : () => _run('finishBrainBreak'),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Kết thúc nghỉ'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run('cancelBrainBreak'),
                  icon: const Icon(Icons.close),
                  label: const Text('Hủy phiên nghỉ'),
                ),
              ] else if (_phase == 'recovering')
                const Text('Brain đang phát hoạt ảnh Recovering một lần, '
                    'không lặp lại và không tự ghi dữ liệu sức khỏe.'),
              if (_busy) const LinearProgressIndicator(color: _purple),
              const SizedBox(height: 10),
              const Text(
                'Bắt đầu là thao tác chủ động. Đóng màn hình không hủy giờ nghỉ. '
                'Kết thúc nghỉ phát Recovering; Hủy nghỉ trở về trạng thái '
                'bình thường ngay, không ghi nhận là nghỉ hoàn thành.',
                style: TextStyle(fontSize: 12, color: Color(0xFF796D8B)),
              ),
            ],
          )),
          const SizedBox(height: 14),
          _surface(const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Riêng tư & giới hạn',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text('Phiên nghỉ chỉ lưu thời hạn và trạng thái trên thiết bị. '
                  'Không yêu cầu Usage Access, quyền overlay hay mạng. '
                  'Không tự bật Không làm phiền hoặc khóa ứng dụng.'),
              SizedBox(height: 8),
              Text(
                  'Nếu ứng dụng bị đóng, thời hạn vẫn được lưu. Khi mở lại '
                  'sau thời hạn, trạng thái được đối chiếu lại; hoạt ảnh '
                  'Recovering có thể không phát nếu đã trễ quá lâu.',
                  style: TextStyle(color: Color(0xFF796D8B))),
            ],
          )),
        ],
      ),
    );
  }
}
