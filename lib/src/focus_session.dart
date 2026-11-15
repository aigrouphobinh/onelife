import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// V3.4 Focus rules. The deadline, not an in-memory countdown, is authoritative.
/// This keeps time accurate after Flutter backgrounding or process restart.
enum FocusPhase { idle, running, paused, completed }

class FocusSession {
  const FocusSession({
    required this.phase,
    required this.totalSeconds,
    required this.remainingSeconds,
    this.deadlineUtc,
  });

  final FocusPhase phase;
  final int totalSeconds;
  final int remainingSeconds;
  final DateTime? deadlineUtc;

  static const empty = FocusSession(
    phase: FocusPhase.idle,
    totalSeconds: 25 * 60,
    remainingSeconds: 25 * 60,
  );

  FocusSession resolvedAt(DateTime now) {
    if (phase != FocusPhase.running || deadlineUtc == null) return this;
    final milliseconds = deadlineUtc!.difference(now.toUtc()).inMilliseconds;
    if (milliseconds <= 0) {
      return FocusSession(
        phase: FocusPhase.completed,
        totalSeconds: totalSeconds,
        remainingSeconds: 0,
      );
    }
    return FocusSession(
      phase: FocusPhase.running,
      totalSeconds: totalSeconds,
      remainingSeconds: (milliseconds + 999) ~/ 1000,
      deadlineUtc: deadlineUtc,
    );
  }

  bool get isActive =>
      phase == FocusPhase.running || phase == FocusPhase.paused;

  Map<String, Object?> toMap() => {
        'id': 1,
        'phase': phase.name,
        'total_seconds': totalSeconds,
        'remaining_seconds': remainingSeconds,
        'deadline_utc': deadlineUtc?.toUtc().toIso8601String(),
      };

  factory FocusSession.fromMap(Map<String, Object?> values) {
    final raw = values['phase'] as String?;
    final phase = FocusPhase.values.firstWhere(
      (candidate) => candidate.name == raw,
      orElse: () => FocusPhase.idle,
    );
    final rawDeadline = values['deadline_utc'] as String?;
    return FocusSession(
      phase: phase,
      totalSeconds: values['total_seconds'] as int,
      remainingSeconds: values['remaining_seconds'] as int,
      deadlineUtc: rawDeadline == null
          ? null
          : DateTime.tryParse(rawDeadline)?.toUtc(),
    );
  }
}

abstract class FocusSessionStorage {
  Future<FocusSession?> read();
  Future<void> write(FocusSession session);
}

/// Only the current session is persisted. No analytics or device-usage access.
class SqliteFocusSessionStorage implements FocusSessionStorage {
  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    final directory = await getDatabasesPath();
    return openDatabase(
      p.join(directory, 'onelife_focus.db'),
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE focus_session ('
        'id INTEGER PRIMARY KEY CHECK (id = 1), '
        'phase TEXT NOT NULL, total_seconds INTEGER NOT NULL, '
        'remaining_seconds INTEGER NOT NULL, deadline_utc TEXT)',
      ),
    );
  }

  @override
  Future<FocusSession?> read() async {
    final rows = await (await database).query(
      'focus_session',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    return rows.isEmpty ? null : FocusSession.fromMap(rows.single);
  }

  @override
  Future<void> write(FocusSession session) async {
    await (await database).insert(
      'focus_session',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

class FocusSessionController {
  FocusSessionController(
    this.storage, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final FocusSessionStorage storage;
  final DateTime Function() _now;

  Future<FocusSession> load() async {
    final original = await storage.read() ?? FocusSession.empty;
    final resolved = original.resolvedAt(_now());
    // Publish completion only after the persisted record is updated.
    if (original.phase == FocusPhase.running &&
        resolved.phase == FocusPhase.completed) {
      await storage.write(resolved);
    }
    return resolved;
  }

  Future<FocusSession> start({int minutes = 25}) async {
    if (minutes < 1 || minutes > 120) {
      throw ArgumentError.value(minutes, 'minutes', 'Must be 1..120');
    }
    final previous = await load();
    if (previous.isActive) {
      throw StateError('A Focus session is already active.');
    }
    final seconds = minutes * 60;
    final session = FocusSession(
      phase: FocusPhase.running,
      totalSeconds: seconds,
      remainingSeconds: seconds,
      deadlineUtc: _now().toUtc().add(Duration(seconds: seconds)),
    );
    await storage.write(session);
    return session;
  }

  Future<FocusSession> pause() async {
    final current = await load();
    if (current.phase != FocusPhase.running) {
      throw StateError('Focus session is not running.');
    }
    final paused = FocusSession(
      phase: FocusPhase.paused,
      totalSeconds: current.totalSeconds,
      remainingSeconds: current.remainingSeconds,
    );
    await storage.write(paused);
    return paused;
  }

  Future<FocusSession> resume() async {
    final current = await load();
    if (current.phase != FocusPhase.paused) {
      throw StateError('Focus session is not paused.');
    }
    final running = FocusSession(
      phase: FocusPhase.running,
      totalSeconds: current.totalSeconds,
      remainingSeconds: current.remainingSeconds,
      deadlineUtc: _now().toUtc().add(
        Duration(seconds: current.remainingSeconds),
      ),
    );
    await storage.write(running);
    return running;
  }

  /// "Kết thúc" is cancellation, NOT a successfully completed interval.
  Future<FocusSession> stop() async {
    final current = await load();
    if (!current.isActive) {
      throw StateError('There is no active Focus session.');
    }
    await storage.write(FocusSession.empty);
    return FocusSession.empty;
  }
}
