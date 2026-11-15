import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/backup_data.dart';
import 'package:onelife/src/backup_files.dart';
import 'package:onelife/src/backup_page.dart';
import 'package:onelife/src/backup_repository.dart';

import 'backup_data_test.dart' show backupFixture;

class MemoryBackup extends BackupRepository {
  int imports = 0;
  @override
  Future<BackupData> export() async =>
      BackupData.parse(jsonEncode(backupFixture()));
  @override
  Future<RestoreResult> restore(BackupData backup) async {
    imports++;
    return const RestoreResult(1, 1, 0);
  }
}

class MemoryFiles extends BackupFiles {
  String? content = jsonEncode(backupFixture());
  bool saved = true;
  @override
  Future<String?> pick() async => content;
  @override
  Future<bool> save(String text) async => saved;
}

void main() {
  testWidgets('cancel confirmation and invalid input do not import or sync',
      (tester) async {
    final repository = MemoryBackup();
    final files = MemoryFiles();
    var synced = 0;
    await tester.pumpWidget(MaterialApp(
        home: BackupPage(
      repository: repository,
      files: files,
      onRestored: () async {
        synced++;
      },
    )));
    await tester.tap(find.text('Chọn file khôi phục'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập bản sao lưu?'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(repository.imports, 0);
    expect(synced, 0);
    files.content = 'invalid';
    await tester.tap(find.text('Chọn file khôi phục'));
    await tester.pumpAndSettle();
    expect(repository.imports, 0);
    expect(find.textContaining('File không hợp lệ'), findsOneWidget);
  });

  testWidgets('successful import reports counts and separate sync failure',
      (tester) async {
    final repository = MemoryBackup();
    await tester.pumpWidget(MaterialApp(
        home: BackupPage(
      repository: repository,
      files: MemoryFiles(),
      onRestored: () async {
        throw StateError('native unavailable');
      },
    )));
    await tester.tap(find.text('Chọn file khôi phục'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhập dữ liệu'));
    await tester.pumpAndSettle();
    expect(repository.imports, 1);
    expect(
        find.textContaining('Đã thêm 1 công việc, 1 ghi chú'), findsOneWidget);
    expect(find.textContaining('Dữ liệu đã lưu, nhưng chưa đồng bộ'),
        findsOneWidget);
  });

  testWidgets('cancelled file save does not claim export success',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: BackupPage(
      repository: MemoryBackup(),
      files: MemoryFiles()..saved = false,
      onRestored: () async {},
    )));
    await tester.tap(find.text('Lưu bản sao lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Đã hủy lưu file.'), findsOneWidget);
    expect(find.textContaining('Đã lưu 1'), findsNothing);
  });
}
