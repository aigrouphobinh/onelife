#!/usr/bin/env python3
"""Match real Flutter SQLite due timestamps to both native Android surfaces.

Dart's DateTime.toUtc().toIso8601String() may use 3 OR 6 decimal digits.
A string query against a 3-decimal midnight cutoff can misclassify a task
due exactly at the next day's midnight. Compare whole UTC seconds instead.
"""
import sqlite3

QUERY = (
    "SELECT COUNT(*) FROM tasks WHERE completed = 0 AND "
    "(due_at_utc IS NULL OR substr(due_at_utc, 1, 19) < ?)"
)


def main():
    # Midnight local in Asia/Ho_Chi_Minh is 17:00:00 UTC the previous day.
    cutoff = "2026-11-15T17:00:00"
    rows = [
        ("no-deadline", None, 0),
        ("overdue", "2026-11-14T23:00:00.000000Z", 0),
        ("before-midnight", "2026-11-15T16:59:59.999999Z", 0),
        ("midnight-dart-micro", "2026-11-15T17:00:00.000000Z", 0),
        ("midnight-dart-milli", "2026-11-15T17:00:00.000Z", 0),
        ("later", "2026-11-17T00:00:00.000Z", 0),
        ("done", None, 1),
    ]
    with sqlite3.connect(":memory:") as db:
        db.execute(
            "CREATE TABLE tasks (id TEXT PRIMARY KEY, due_at_utc TEXT, "
            "completed INTEGER NOT NULL)"
        )
        db.executemany("INSERT INTO tasks VALUES (?,?,?)", rows)
        assert db.execute(QUERY, (cutoff,)).fetchone()[0] == 3
        db.execute("UPDATE tasks SET completed=1 WHERE id='overdue'")
        assert db.execute(QUERY, (cutoff,)).fetchone()[0] == 2
        db.execute("DELETE FROM tasks")
        assert db.execute(QUERY, (cutoff,)).fetchone()[0] == 0
    print("PASS: Widget/Quick Settings pending count, UTC microseconds and local midnight")


if __name__ == "__main__":
    main()
