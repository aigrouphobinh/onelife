import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'backup_data.dart';

abstract class BackupFiles {
  Future<String?> pick();
  Future<bool> save(String text);
}

class DeviceBackupFiles implements BackupFiles {
  @override
  Future<String?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
      withData: false,
      withReadStream: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    if (file.size > BackupData.maxBytes) {
      throw const FormatException('File vượt quá giới hạn 5 MB.');
    }
    final stream = file.readStream ??
        (file.path == null ? null : File(file.path!).openRead());
    if (stream == null) throw const FormatException('Không đọc được file.');
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      if (bytes.length + chunk.length > BackupData.maxBytes) {
        throw const FormatException('File vượt quá giới hạn 5 MB.');
      }
      bytes.add(chunk);
    }
    return utf8.decode(bytes.takeBytes());
  }

  @override
  Future<bool> save(String text) async {
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final path = await FilePicker.platform.saveFile(
      fileName: 'onelife-$stamp.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Uint8List.fromList(utf8.encode(text)),
    );
    return path != null;
  }
}
