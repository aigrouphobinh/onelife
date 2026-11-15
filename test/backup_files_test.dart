import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/backup_data.dart';
import 'package:onelife/src/backup_files.dart';

class TestPicker extends FilePicker {
  FilePickerResult? selection;
  Uint8List? saved;
  String? destination = '/test/backup.json';

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    expect(withData, isFalse);
    expect(withReadStream, isTrue);
    expect(allowMultiple, isFalse);
    return selection;
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    saved = bytes;
    expect(fileName, endsWith('.json'));
    return destination;
  }
}

void main() {
  late TestPicker picker;
  final files = DeviceBackupFiles();
  setUp(() {
    picker = TestPicker();
    FilePicker.platform = picker;
  });

  test('UTF-8 file bytes roundtrip and cancellation remain distinct', () async {
    const text = '{"nội dung":"🌱"}';
    expect(await files.save(text), isTrue);
    expect(utf8.decode(picker.saved!), text);
    picker.selection = FilePickerResult([
      PlatformFile(
          name: 'backup.json',
          size: picker.saved!.length,
          readStream: Stream.value(picker.saved!)),
    ]);
    expect(await files.pick(), text);
    picker.selection = null;
    expect(await files.pick(), isNull);
    picker.destination = null;
    expect(await files.save(text), isFalse);
  });

  test('bounded stream rejects oversized data despite false size metadata',
      () async {
    picker.selection = FilePickerResult([
      PlatformFile(
          name: 'backup.json',
          size: 0,
          readStream: Stream.value(Uint8List(BackupData.maxBytes + 1))),
    ]);
    await expectLater(files.pick(), throwsFormatException);
  });
}
