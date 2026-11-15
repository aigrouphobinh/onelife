import 'dart:async';

import 'package:flutter/material.dart';

import 'focus_session.dart';
import 'glossy_sprite.dart';

const _violet = Color(0xFF8054E6);
const _deepPurple = Color(0xFF261844);
const _softPurple = Color(0xFFF8F3FF);

/// First V3.4 working surface. Android/iOS system controls are NOT simulated.
class FocusPage extends StatefulWidget {
  const FocusPage({super.key, this.controller});

  /// An injectable controller makes timing and persistence testable.
  final FocusSessionController? controller;

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with WidgetsBindingObserver {
  late final FocusSessionController _controller =
      widget.controller ?? FocusSessionController(SqliteFocusSessionStorage());

  Timer? _ticker;
  FocusSession _session = FocusSession.empty;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  static const _brainFocus = GlossySpriteSpec(
    assetPath: 'assets/characters-v2/brain/focus/sheet.png',
    frames: 8,
    columns: 4,
    frameWidth: 256,
    frameHeight: 256,
    frameDurationMs: 160,
    loop: true,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    try {
      final result = await _controller.load();
      if (!mounted) return;
      setState(() {
        _session = result;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không thể đọc phiên tập trung trên thiết bị.';
      });
    }
  }

  void _tick() {
    if (!mounted || _busy || _loading || _error != null) return;
    if (_session.phase != FocusPhase.running) return;
    final updated = _session.resolvedAt(DateTime.now());
    if (updated.phase == FocusPhase.completed) {
      _refresh(); // expiry must be committed before the success state
    } else if (updated.remainingSeconds != _session.remainingSeconds) {
      setState(() => _session = updated);
    }
  }

  Future<void> _run(Future<FocusSession> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() => _session = updated);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không lưu được trạng thái. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String get _time {
    final seconds = _session.remainingSeconds;
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }

  String get _stateLabel => switch (_session.phase) {
        FocusPhase.idle => 'Sẵn sàng',
        FocusPhase.running => 'Đang tập trung',
        FocusPhase.paused => 'Đã tạm dừng',
        FocusPhase.completed => 'Đã hoàn thành 25 phút tập trung',
      };

  @override
  Widget build(BuildContext context) {
    final running = _session.phase == FocusPhase.running;
    final paused = _session.phase == FocusPhase.paused;
    final inactive = !running && !paused;
    final progress = _session.totalSeconds == 0
        ? 0.0
        : 1 - (_session.remainingSeconds / _session.totalSeconds);

    return Scaffold(
      backgroundColor: _softPurple,
      appBar: AppBar(
        backgroundColor: const Color(0xFF312353),
        foregroundColor: Colors.white,
        title: const Text('Tập trung · OneLife'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF312353),
                    Color(0xFF7151B2),
                    Color(0xFF957AE1),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Một việc nhỏ, một khoảng thời gian yên tĩnh',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFF1E6FF), fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const GlossySprite(
                    spec: _brainFocus,
                    size: 174,
                    semanticLabel: 'Bộ Não OneLife đang tập trung',
                  ),
                  Text(
                    _stateLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Semantics(
                    label: 'Thời gian còn lại $_time',
                    liveRegion: false,
                    child: Text(
                      _time,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 60,
                        height: 1,
                        fontFeatures: [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    color: const Color(0xFFEDD8FF),
                    backgroundColor: const Color(0x55FFFFFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '25 phút · không tự bật chế độ Không làm phiền',
                    style: TextStyle(color: Color(0xFFECE0FF), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFC9304A)),
                        ),
                      ),
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              if (inactive)
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() => _controller.start(minutes: 25)),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    _session.phase == FocusPhase.completed
                        ? 'Bắt đầu phiên mới'
                        : 'Bắt đầu 25 phút',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _violet,
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
              if (running || paused) ...[
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(
                            running ? _controller.pause : _controller.resume,
                          ),
                  icon: Icon(
                    running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(running ? 'Tạm dừng' : 'Tiếp tục'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _violet,
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run(_controller.stop),
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Kết thúc sớm'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _deepPurple,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Tập trung nhẹ nhàng',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: _deepPurple,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Bộ đếm sử dụng thời gian thực và lưu phiên '
                      'trên thiết bị. Nếu rời ứng dụng rồi quay lại, '
                      'thời gian còn lại được tính từ mốc đã lưu.',
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Thông báo nền, Quick Settings và Live Activity '
                      'chưa được kết nối; không có lời hứa về báo thức '
                      'khi ứng dụng bị đóng.',
                      style: TextStyle(color: Color(0xFF766C8A), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
