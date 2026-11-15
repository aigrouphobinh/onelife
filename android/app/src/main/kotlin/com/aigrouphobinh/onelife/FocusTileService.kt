package com.aigrouphobinh.onelife

import android.content.ContentValues
import android.database.sqlite.SQLiteDatabase
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.math.max

/**
 * A real Android Quick Settings tile for the V3.4 25-minute Focus session.
 *
 * This service operates on the SAME private SQLite row used by Flutter:
 * onelife_focus.db / focus_session / id=1. It does not simulate a tile in
 * Flutter, request Usage Access, or turn on system Do Not Disturb.
 *
 * Tap while inactive: start; running: pause; paused: resume.
 * The Android panel owns the tile's position, size, and color.
 */
class FocusTileService : TileService() {
    private data class FocusRow(
        val phase: String = "idle",
        val totalSeconds: Int = 1500,
        val remainingSeconds: Int = 1500,
        val deadlineUtc: String? = null,
    )

    private fun dateFormat() = SimpleDateFormat(
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US
    ).apply { timeZone = TimeZone.getTimeZone("UTC") }

    private fun utcDeadline(remainingSeconds: Int): String =
        dateFormat().format(Date(System.currentTimeMillis() + remainingSeconds * 1000L))

    private fun calculateRemaining(deadline: String?): Int {
        if (deadline == null) return 0
        val end = dateFormat().parse(deadline)?.time ?: return 0
        return max(0L, (end - System.currentTimeMillis() + 999L) / 1000L).toInt()
    }

    private fun read(db: SQLiteDatabase): FocusRow {
        db.query(
            "focus_session",
            arrayOf("phase", "total_seconds", "remaining_seconds", "deadline_utc"),
            "id = ?", arrayOf("1"), null, null, null, "1"
        ).use { cursor ->
            if (!cursor.moveToFirst()) return FocusRow()
            return FocusRow(
                phase = cursor.getString(0),
                totalSeconds = cursor.getInt(1),
                remainingSeconds = cursor.getInt(2),
                deadlineUtc = if (cursor.isNull(3)) null else cursor.getString(3),
            )
        }
    }

    private fun write(db: SQLiteDatabase, state: FocusRow) {
        val values = ContentValues().apply {
            put("id", 1)
            put("phase", state.phase)
            put("total_seconds", state.totalSeconds)
            put("remaining_seconds", state.remainingSeconds)
            if (state.deadlineUtc == null) putNull("deadline_utc")
            else put("deadline_utc", state.deadlineUtc)
        }
        db.insertWithOnConflict(
            "focus_session", null, values, SQLiteDatabase.CONFLICT_REPLACE
        )
    }

    private fun current(db: SQLiteDatabase): FocusRow {
        val value = read(db)
        if (value.phase != "running") return value
        val remaining = calculateRemaining(value.deadlineUtc)
        if (remaining > 0) return value.copy(remainingSeconds = remaining)
        val completed = value.copy(
            phase = "completed", remainingSeconds = 0, deadlineUtc = null
        )
        write(db, completed)
        return completed
    }

    private fun withDatabase(block: (SQLiteDatabase) -> FocusRow): FocusRow {
        val file = getDatabasePath("onelife_focus.db")
        file.parentFile?.mkdirs()
        val db = SQLiteDatabase.openOrCreateDatabase(file, null)
        try {
            db.execSQL(
                "CREATE TABLE IF NOT EXISTS focus_session (" +
                "id INTEGER PRIMARY KEY CHECK(id = 1), " +
                "phase TEXT NOT NULL, total_seconds INTEGER NOT NULL, " +
                "remaining_seconds INTEGER NOT NULL, deadline_utc TEXT)"
            )
            db.beginTransaction()
            try {
                val result = block(db)
                db.setTransactionSuccessful()
                return result
            } finally {
                db.endTransaction()
            }
        } finally {
            db.close()
        }
    }

    private fun updateUi(value: FocusRow) {
        val tile = qsTile ?: return
        tile.icon = Icon.createWithResource(this, R.drawable.ic_onelife_focus)
        tile.label = "Tập trung"
        tile.state = if (value.phase == "running") Tile.STATE_ACTIVE
            else Tile.STATE_INACTIVE
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = when (value.phase) {
                "running" -> "Đang chạy"
                "paused" -> "Tạm dừng"
                "completed" -> "Đã xong"
                else -> "Bắt đầu 25 phút"
            }
        }
        tile.updateTile()
    }

    private fun showUnavailable() {
        qsTile?.also {
            it.state = Tile.STATE_UNAVAILABLE
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                it.subtitle = "Mở OneLife để thử lại"
            }
            it.updateTile()
        }
    }

    override fun onStartListening() {
        super.onStartListening()
        try {
            updateUi(withDatabase { db -> current(db) })
        } catch (_: Exception) {
            showUnavailable()
        }
    }

    override fun onClick() {
        super.onClick()
        try {
            val updated = withDatabase { db ->
                val previous = current(db)
                val next = when (previous.phase) {
                    "running" -> previous.copy(
                        phase = "paused",
                        deadlineUtc = null,
                    )
                    "paused" -> previous.copy(
                        phase = "running",
                        deadlineUtc = utcDeadline(previous.remainingSeconds),
                    )
                    else -> FocusRow(
                        phase = "running",
                        totalSeconds = 1500,
                        remainingSeconds = 1500,
                        deadlineUtc = utcDeadline(1500),
                    )
                }
                write(db, next)
                next
            }
            updateUi(updated)
        } catch (_: Exception) {
            showUnavailable()
        }
    }
}
