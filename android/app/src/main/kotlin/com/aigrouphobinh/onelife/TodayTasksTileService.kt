package com.aigrouphobinh.onelife

import android.app.PendingIntent
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

/**
 * OneLife V3.4 native Quick Settings "Việc hôm nay".
 *
 * Shows ONLY a real aggregate count of unfinished tasks. Task titles,
 * deadlines and user content never appear in the system shade/lock screen.
 *
 * Matches the Flutter "Hôm nay" filter: incomplete, with no deadline, overdue,
 * or scheduled before the user's next local midnight.
 */
class TodayTasksTileService : TileService() {
    private fun nextLocalMidnightUtc(): String {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            add(Calendar.DAY_OF_MONTH, 1)
        }
        val format = SimpleDateFormat(
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            Locale.US,
        ).apply { timeZone = TimeZone.getTimeZone("UTC") }
        return format.format(calendar.time)
    }

    private fun pendingCount(): Int? {
        val file = getDatabasePath("onelife_ui.db")
        if (!file.exists()) return 0 // No user data yet, never invent demo tasks.
        val db = SQLiteDatabase.openDatabase(
            file.path,
            null,
            SQLiteDatabase.OPEN_READONLY,
        )
        try {
            db.rawQuery(
                "SELECT COUNT(*) FROM tasks " +
                    "WHERE completed = 0 AND (due_at_utc IS NULL OR due_at_utc < ?)",
                arrayOf(nextLocalMidnightUtc()),
            ).use { cursor ->
                if (!cursor.moveToFirst()) return 0
                return cursor.getInt(0)
            }
        } finally {
            db.close()
        }
    }

    override fun onStartListening() {
        super.onStartListening()
        val tile = qsTile ?: return
        tile.icon = Icon.createWithResource(this, R.drawable.ic_onelife_today)
        tile.label = "Việc hôm nay"
        tile.contentDescription = "Việc hôm nay trong OneLife"
        // Don't expose even an aggregate count in the shade before unlock.
        if (isLocked) {
            tile.state = Tile.STATE_INACTIVE
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                tile.subtitle = "Mở khóa để xem"
            }
            tile.updateTile()
            return
        }
        try {
            val count = pendingCount() ?: 0
            // Android 7–9 have no QS subtitle, so expose the count in the
            // label instead; Android 10+ uses the system-managed subtitle.
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                tile.label = "Việc hôm nay ($count)"
            }
            tile.state = if (count > 0) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                tile.subtitle = if (count == 0) {
                    "Không có việc đang chờ"
                } else {
                    "$count việc chưa xong"
                }
            }
        } catch (_: Exception) {
            tile.state = Tile.STATE_UNAVAILABLE
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                tile.subtitle = "Mở OneLife để thử lại"
            }
        }
        tile.updateTile()
    }

    override fun onClick() {
        super.onClick()
        // Open the actual Tasks screen. Never display task titles on lockscreen.
        if (isLocked) {
            unlockAndRun { openTasks() }
        } else {
            openTasks()
        }
    }

    private fun openTasks() {
        val intent = Intent(this, MainActivity::class.java).apply {
            putExtra(MainActivity.EXTRA_TODAY_TASKS, true)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pendingIntent = PendingIntent.getActivity(
                this,
                3402,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            startActivityAndCollapse(pendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}
