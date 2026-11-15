#!/usr/bin/env python3
"""SQLite contract tests for Android V3.4 Today Tasks aggregate.

The same query is in TodayTasksTileService.kt. The reference instant is
15 Nov 2026 in Asia/Ho_Chi_Minh, whose next local midnight is
2026-11-15T17:00:00.000Z. No personal task titles ever leave the DB.
"""
import sqlite3


QUERY = (
    "SELECT COUNT(*) FROM tasks WHERE completed = 0 "
    "AND (due_at_utc IS NULL OR due_at_utc < ?)"
)
CUTOFF = "2026-11-15T17:00:00.000Z"


def main() -> None:
    with sqlite3.connect(":memory:") as conn:
        conn.execute(
            "CREATE TABLE tasks (id TEXT PRIMARY KEY, title TEXT NOT NULL, "
            "due_at_utc TEXT, completed INTEGER NOT NULL, "
            "created_at_utc TEXT NOT NULL)"
        )
        rows = [
            ("undated", None, 0),  # user has not chosen a due date
            ("overdue", "2026-11-12T04:00:00.000Z", 0),
            ("today", "2026-11-15T16:59:59.999Z", 0),
            ("next-midnight", CUTOFF, 0),
            ("future", "2026-11-17T00:00:00.000Z", 0),
            ("done", None, 1),
            ("done-today", "2026-11-15T10:00:00.000Z", 1),
        ]
        conn.executemany(
            "INSERT INTO tasks VALUES (?, ?, ?, ?, ?)",
            [
                (name, "private task", due, done, "2026-11-15T00:00:00.000Z")
                for name, due, done in rows
            ],
        )
        result = conn.execute(QUERY, (CUTOFF,)).fetchone()[0]
        assert result == 3, f"Expected 3 pending today, got {result}"
        conn.execute("UPDATE tasks SET completed = 1 WHERE id = ?", ("today",))
        assert conn.execute(QUERY, (CUTOFF,)).fetchone()[0] == 2
        conn.execute("DELETE FROM tasks")
        assert conn.execute(QUERY, (CUTOFF,)).fetchone()[0] == 0

    print("PASS: Today Tasks SQLite query handles undated, overdue, midnight, done and empty")


if __name__ == "__main__":
    main()
