import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glossy_sprite.dart';

/// V3.4 real Android special-access setup; no fake floating Flutter preview.
/// Android alone owns the TYPE_APPLICATION_OVERLAY window and permission.
class BrainOverlaySetupPage extends StatefulWidget {
  const BrainOverlaySetupPage({super.key});

  @override
  State<BrainOverlaySetupPage> createState() => _BrainOverlaySetupPageState();
}

class _BrainOverlaySetupPageState extends State<BrainOverlaySetupPage>
    with WidgetsBindingObserver {
  static const MethodChannel _bridge = MethodChannel('onelife/quick_capture');
  static const Color _purple = Color(0xFF8054E6);
  static const Color _ink = Color(0xFF21183C);
  static const Color _background = Color(0xFFF8F3FF);
  static const GlossySpriteSpec _brain = GlossySpriteSpec(
    assetPath: 'assets/characters-v2/brain/idle/sheet.png',
    frames: 8,
    columns: 4,
    frameWidth: 256,
    frameHeight: 256,
    frameDurationMs: 140,
    loop: true,
  );

  bool _android = false;
  bool _hasChecked = false;
  bool _supported = false;
  bool _granted = false;
  bool _running = false;
  bool _busy = false;
  bool _checking = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _android = Theme.of(context).platform == TargetPlatform.android;
    if (!_hasChecked) {
      _hasChecked = true;
      _checkStatus();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The user may have returned from Android special-access settings
      // without granting anything. Never infer permission from the intent.
      _checkStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (!_android) {
      if (mounted) {
        setState(() {
          _supported = false;
          _granted = false;
          _running = false;
          _checking = false;
        });
      }
      return;
    }
    try {
      final status =
          await _bridge.invokeMapMethod<String, dynamic>('overlayStatus');
      if (!mounted) return;
      setState(() {
        _supported = status?['supported'] == true;
        _granted = status?['permissionGranted'] == true;
        _running = status?['running'] == true;
        _checking = false;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _supported = false;
        _granted = false;
        _running = false;
        _checking = false;
        _message = 'Bản Android này chưa có dịch vụ Brain nổi native.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _message = 'Không đọc được trạng thái quyền overlay.';
      });
    }
  }

  Future<void> _run(String method) async {
    if (_busy || !_android) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final reply = await _bridge.invokeMethod<String>(method);
      if (!mounted) return;
      switch (method) {
        case 'requestOverlayPermission':
          _message = reply == 'opened'
              ? 'Đã mở Cài đặt Android. Chỉ bật Brain sau khi bạn cấp quyền.'
              : reply == 'granted'
                  ? 'Quyền hiển thị đã được cấp.'
                  : 'Không mở được mục quyền. Hãy cấp quyền từ Cài đặt ứng dụng.';
        case 'startBrainOverlay':
          _message = reply == 'permission_required'
              ? 'Bạn cần cho phép hiển thị trên ứng dụng khác trước.'
              : reply == 'unavailable'
                  ? 'Android không thể khởi chạy lớp phủ.'
                  : 'Đã yêu cầu hiển thị Brain; đang kiểm tra cửa sổ thật.';
        case 'stopBrainOverlay':
          _message = 'Đã yêu cầu ẩn Brain nổi.';
      }
      if (method == 'startBrainOverlay' || method == 'stopBrainOverlay') {
        // Android returns "requested" before Service adds/removes its window.
        // Never present requested state as confirmed window visibility.
        await Future<void>.delayed(const Duration(milliseconds: 180));
      }
      await _checkStatus();
    } on MissingPluginException {
      if (mounted) _message = 'Thiếu phần tích hợp native Android.';
    } catch (_) {
      if (mounted) _message = 'Thao tác không thành công. Hãy thử lại.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _panel(Widget child) => Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x174E356E),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final usable = _android && _supported;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Brain nổi Android'),
        backgroundColor: _background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7650CC), Color(0xFFB08AEF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                const GlossySprite(
                  spec: _brain,
                  size: 116,
                  semanticLabel: 'Brain OneLife Glossy Kawaii động',
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Brain ở cạnh bạn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          )),
                      SizedBox(height: 8),
                      Text(
                          'Kéo đến vị trí bạn thích. '
                          'Chạm Brain để mở thao tác nhanh.',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quyền hiển thị trên ứng dụng khác',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _granted
                          ? Icons.verified_user_outlined
                          : Icons.shield_outlined,
                      color: _purple,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _checking
                            ? 'Đang kiểm tra quyền...'
                            : !usable
                                ? 'Không hỗ trợ trên thiết bị hoặc phiên bản này'
                                : _granted
                                    ? 'Đã được Android cho phép'
                                    : 'Chưa được cho phép',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (usable && !_granted)
                  FilledButton.icon(
                    onPressed:
                        _busy ? null : () => _run('requestOverlayPermission'),
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Mở cài đặt cấp quyền'),
                  ),
                if (usable && _granted && !_running)
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _run('startBrainOverlay'),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Hiện Brain nổi'),
                  ),
                if (usable && _granted && _running)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run('stopBrainOverlay'),
                    icon: const Icon(Icons.visibility_off_outlined),
                    label: const Text('Ẩn Brain nổi'),
                  ),
                if (!_android)
                  const Text('iOS không cho phép kiểu lớp phủ nổi tự do '
                      'như Android. Không tạo overlay giả trong ứng dụng.'),
                if (_android && !_supported && !_checking)
                  const Text('Brain nổi yêu cầu Android 8 trở lên và '
                      'dịch vụ overlay được đóng gói trong APK.'),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!, style: const TextStyle(color: _ink)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _panel(
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thao tác nhanh thật',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                SizedBox(height: 10),
                Text('✓ Việc hôm nay · + Ghi nhanh · ◷ Tập trung · × Ẩn Brain'),
                SizedBox(height: 10),
                Text('Bong bóng nhỏ chỉ nhận thao tác trong vùng Brain. '
                    'Có thể kéo thả và ghi nhớ vị trí trên màn hình. '
                    'Không đọc nội dung của ứng dụng khác.'),
                SizedBox(height: 10),
                Text(
                    'Chỉ xuất hiện khi bạn nhấn Hiện Brain nổi. '
                    'Android có thể dừng dịch vụ để tiết kiệm bộ nhớ; '
                    'Brain không tự khởi động sau khi khởi động lại điện thoại.',
                    style: TextStyle(color: Color(0xFF786B89))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
