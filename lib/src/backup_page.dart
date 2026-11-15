import 'package:flutter/material.dart';

import 'backup_data.dart';
import 'backup_files.dart';
import 'backup_repository.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({
    super.key,
    required this.repository,
    required this.files,
    required this.onRestored,
  });
  final BackupRepository repository;
  final BackupFiles files;
  final Future<void> Function() onRestored;

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _busy = false;
  String? _message;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } on FormatException {
      if (mounted) {
        setState(() => _message =
            'File không hợp lệ hoặc vượt giới hạn 5 MB / 10.000 mục. '
                'Dữ liệu hiện có không thay đổi.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Không thể hoàn tất. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _run(() async {
        final backup = await widget.repository.export();
        if (!mounted) return;
        final saved = await widget.files.save(backup.encode());
        if (!mounted) return;
        setState(() => _message = saved
            ? 'Đã lưu ${backup.tasks.length} công việc và '
                '${backup.notes.length} ghi chú.'
            : 'Đã hủy lưu file.');
      });

  Future<void> _restore() => _run(() async {
        final text = await widget.files.pick();
        if (text == null || !mounted) return;
        final backup = BackupData.parse(text);
        final accepted = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Nhập bản sao lưu?'),
            content: Text(
              '${backup.tasks.length} công việc · ${backup.notes.length} ghi chú.\n\n'
              'Chỉ thêm mục chưa có. Mục trùng ID sẽ được bỏ qua; '
              'không ghi đè hoặc xóa dữ liệu trên máy. '
              'Nhắc việc được cập nhật theo quyền hiện tại.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Nhập dữ liệu'),
              ),
            ],
          ),
        );
        if (accepted != true || !mounted) return;
        final result = await widget.repository.restore(backup);
        // Commit has already succeeded: report sync failure separately, never
        // pretend the import failed and encourage an unnecessary repeat.
        var syncFailed = false;
        try {
          await widget.onRestored();
        } catch (_) {
          syncFailed = true;
        }
        if (!mounted) return;
        setState(() => _message =
            'Đã thêm ${result.tasksAdded} công việc, ${result.notesAdded} ghi chú; '
                'bỏ qua ${result.skipped} mục trùng.'
                '${syncFailed ? ' Dữ liệu đã lưu, nhưng chưa đồng bộ được nhắc việc. Mở lại ứng dụng để thử lại.' : ''}');
      });

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: Scaffold(
          appBar: AppBar(title: const Text('Sao lưu & Khôi phục')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Lưu ghi chú và công việc thành file JSON để chuyển máy hoặc '
                'giữ một bản dự phòng.',
              ),
              const SizedBox(height: 12),
              const Text(
                'File chưa mã hóa, chứa nội dung cá nhân. Chọn nơi lưu bạn tin cậy. '
                'Không gồm thống kê sử dụng máy, phiên tập trung, nhân vật và quyền thiết bị.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _busy ? null : _export,
                icon: const Icon(Icons.save_alt),
                label: const Text('Lưu bản sao lưu'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _restore,
                icon: const Icon(Icons.restore),
                label: const Text('Chọn file khôi phục'),
              ),
              const SizedBox(height: 16),
              if (_busy) const LinearProgressIndicator(),
              if (_message != null)
                Semantics(liveRegion: true, child: Text(_message!)),
            ],
          ),
        ),
      );
}
