import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelife/src/focus_page.dart';
import 'package:onelife/src/focus_session.dart';

class MemoryFocusStorage implements FocusSessionStorage {
  FocusSession? value;

  @override
  Future<FocusSession?> read() async => value;

  @override
  Future<void> write(FocusSession session) async {
    value = session;
  }
}

void main() {
  test('Start 25 minutes and persist the actual deadline', () async {
    final storage = MemoryFocusStorage();
    var now = DateTime.utc(2026, 11, 15, 9);
    final controller = FocusSessionController(storage, now: () => now);

    final active = await controller.start();
    expect(active.phase, FocusPhase.running);
    expect(active.totalSeconds, 1500);
    expect(active.remainingSeconds, 1500);
    expect(storage.value?.deadlineUtc, now.add(const Duration(minutes: 25)));

    now = now.add(const Duration(minutes: 9, seconds: 12));
    final loaded = await controller.load();
    expect(loaded.remainingSeconds, 948);
    expect(loaded.phase, FocusPhase.running);
  });

  test(
    'Pause freezes elapsed time and resume uses remaining seconds',
    () async {
      final storage = MemoryFocusStorage();
      var now = DateTime.utc(2026, 11, 15, 9);
      final controller = FocusSessionController(storage, now: () => now);

      await controller.start();
      now = now.add(const Duration(minutes: 10));
      final paused = await controller.pause();
      expect(paused.phase, FocusPhase.paused);
      expect(paused.remainingSeconds, 900);
      expect(paused.deadlineUtc, isNull);

      now = now.add(const Duration(hours: 3));
      expect((await controller.load()).remainingSeconds, 900);
      final resumed = await controller.resume();
      expect(resumed.deadlineUtc, now.add(const Duration(minutes: 15)));
      expect((await controller.load()).phase, FocusPhase.running);
    },
  );

  test('Recover after process restart and store completed session', () async {
    final storage = MemoryFocusStorage();
    var now = DateTime.utc(2026, 11, 15, 9);
    final firstProcess = FocusSessionController(storage, now: () => now);
    await firstProcess.start();

    now = now.add(const Duration(minutes: 30));
    final secondProcess = FocusSessionController(storage, now: () => now);
    final restored = await secondProcess.load();
    expect(restored.phase, FocusPhase.completed);
    expect(restored.remainingSeconds, 0);
    expect(storage.value?.phase, FocusPhase.completed);
  });

  test('Stopping early is not reported as completed', () async {
    final storage = MemoryFocusStorage();
    final controller = FocusSessionController(storage);
    await controller.start();
    final stopped = await controller.stop();
    expect(stopped.phase, FocusPhase.idle);
    expect(storage.value?.phase, FocusPhase.idle);
    await expectLater(controller.pause(), throwsStateError);
  });

  test('Starting an active Focus never silently resets progress', () async {
    final storage = MemoryFocusStorage();
    final controller = FocusSessionController(storage);
    await controller.start();
    await expectLater(controller.start(), throwsStateError);
    await expectLater(controller.start(minutes: 0), throwsArgumentError);
  });

  testWidgets('V3.4 Focus presents real start pause and resume controls', (
    tester,
  ) async {
    final storage = MemoryFocusStorage();
    final controller = FocusSessionController(storage);
    await tester.pumpWidget(
      MaterialApp(home: FocusPage(controller: controller)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Bắt đầu 25 phút'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);

    await tester.tap(find.text('Bắt đầu 25 phút'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(storage.value?.phase, FocusPhase.running);
    expect(find.text('Tạm dừng'), findsOneWidget);

    await tester.tap(find.text('Tạm dừng'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(storage.value?.phase, FocusPhase.paused);
    expect(find.text('Tiếp tục'), findsOneWidget);

    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(storage.value?.phase, FocusPhase.running);
    expect(find.text('Kết thúc sớm'), findsOneWidget);
  });
}
