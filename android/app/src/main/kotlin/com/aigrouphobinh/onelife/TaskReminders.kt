package com.aigrouphobinh.onelife

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.sqlite.SQLiteDatabase
import android.net.Uri
import android.os.Build
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

/**
 * Opt-in, device-local reminders. setAndAllowWhileIdle is deliberately INEXACT;
 * the OS may defer delivery during Doze or OEM battery restrictions.
 */
internal object TaskReminders {
    const val ACTION_ALARM = "com.aigrouphobinh.onelife.reminder.ALARM"
    const val ACTION_DONE = "com.aigrouphobinh.onelife.reminder.DONE"
    const val ACTION_SNOOZE = "com.aigrouphobinh.onelife.reminder.SNOOZE"
    const val EXTRA_ID = "task_id"
    const val CHANNEL_ID = "onelife_task_reminders_v34"
    const val NOTICE_ID = 1
    private const val PREF = "onelife_task_reminders"
    private const val ENABLED = "enabled"
    private const val SNOOZE_PREFIX = "snooze:"
    private const val TEN_MINUTES = 600_000L

    data class Task(val id: String, val title: String, val deadline: String?, val done: Boolean)
    private fun prefs(c: Context) = c.getSharedPreferences(PREF, Context.MODE_PRIVATE)
    private fun manager(c: Context) = c.getSystemService(NotificationManager::class.java)
    fun optedIn(c: Context) = prefs(c).getBoolean(ENABLED, false)
    fun permitted(c: Context) = (manager(c)?.areNotificationsEnabled() == true) &&
        (Build.VERSION.SDK_INT < 33 ||
            c.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED)
    fun enabled(c: Context) = optedIn(c) && permitted(c)

    fun enable(c: Context): Boolean {
        if (!permitted(c)) return false
        channel(c)
        prefs(c).edit().putBoolean(ENABLED, true).apply()
        setBootReceiver(c, true)
        sync(c)
        return true
    }

    fun disable(c: Context) {
        prefs(c).edit().putBoolean(ENABLED, false).apply()
        setBootReceiver(c, false)
        for (task in tasks(c)) {
            cancel(c, task.id)
            manager(c)?.cancel(task.id, NOTICE_ID)
        }
        val keys = prefs(c).all.keys.filter { it.startsWith(SNOOZE_PREFIX) }
        prefs(c).edit().apply { keys.forEach { remove(it) } }.apply()
    }

    private fun setBootReceiver(c: Context, on: Boolean) {
        c.packageManager.setComponentEnabledSetting(
            ComponentName(c, TaskReminderRestoreReceiver::class.java),
            if (on) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP,
        )
    }

    fun channel(c: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager(c)?.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID, "Nhắc công việc OneLife",
                    NotificationManager.IMPORTANCE_DEFAULT,
                ).apply {
                    description = "Thông báo cho công việc bạn đã hẹn giờ"
                    lockscreenVisibility = Notification.VISIBILITY_PRIVATE
                },
            )
        }
    }

    private fun <T> read(c: Context, empty: T, fn: (SQLiteDatabase) -> T): T {
        val file = c.getDatabasePath("onelife_ui.db")
        if (!file.exists()) return empty
        return try {
            SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READONLY).use(fn)
        } catch (_: Exception) {
            empty
        }
    }

    private fun fromCursor(cur: android.database.Cursor) = Task(
        cur.getString(0), cur.getString(1),
        if (cur.isNull(2)) null else cur.getString(2), cur.getInt(3) != 0,
    )

    private fun tasks(c: Context): List<Task> = read(c, emptyList<Task>()) { db ->
        db.query("tasks", arrayOf("id", "title", "due_at_utc", "completed"),
            null, null, null, null, null).use { cur ->
            buildList { while (cur.moveToNext()) add(fromCursor(cur)) }
        }
    }

    fun task(c: Context, id: String): Task? = read(c, null as Task?) { db ->
        db.query("tasks", arrayOf("id", "title", "due_at_utc", "completed"),
            "id=?", arrayOf(id), null, null, null, "1").use { cur ->
            if (cur.moveToFirst()) fromCursor(cur) else null
        }
    }

    fun utcMillis(value: String?): Long? {
        if (value == null) return null
        val normalized = if (!value.contains('.')) value.dropLast(1) + ".000Z"
        else value.replace(Regex("\\.(\\d{3})\\d+Z$"), ".$1Z")
        return try {
            SimpleDateFormat(
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US,
            ).apply { timeZone = TimeZone.getTimeZone("UTC"); isLenient = false }
                .parse(normalized)?.time
        } catch (_: Exception) { null }
    }

    private fun pending(c: Context, id: String, create: Boolean): PendingIntent? {
        val intent = Intent(c, TaskReminderReceiver::class.java).apply {
            action = ACTION_ALARM
            data = Uri.parse("onelife://reminder/alarm/" + Uri.encode(id))
            putExtra(EXTRA_ID, id)
        }
        return PendingIntent.getBroadcast(
            c, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or
                (if (create) PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_NO_CREATE),
        )
    }

    private fun cancel(c: Context, id: String) {
        val p = pending(c, id, false) ?: return
        (c.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(p)
        p.cancel()
    }

    private fun schedule(c: Context, id: String, deadline: Long) {
        if (deadline <= System.currentTimeMillis()) return
        val p = pending(c, id, true) ?: return
        (c.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
            .setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, deadline, p)
    }

    /** Called after Flutter saves/tasks, Android action buttons, or reboot. */
    fun sync(c: Context) {
        if (!enabled(c)) return
        val now = System.currentTimeMillis()
        for (task in tasks(c)) {
            val key = SNOOZE_PREFIX + task.id
            if (task.done) {
                cancel(c, task.id)
                prefs(c).edit().remove(key).apply()
                manager(c)?.cancel(task.id, NOTICE_ID)
                continue
            }
            val snooze = prefs(c).getLong(key, 0L)
            val time = if (snooze > now) snooze else utcMillis(task.deadline)
            when {
                time == null -> cancel(c, task.id)
                time > now -> schedule(c, task.id, time)
                // Keep a past-due pending alarm: Android may be delivering it
                // late under Doze. Resync must not discard a valid reminder.
                else -> Unit
            }
        }
    }

    fun deliver(c: Context, id: String) {
        if (!enabled(c)) return
        val t = task(c, id) ?: return
        if (t.done) return
        val snooze = prefs(c).getLong(SNOOZE_PREFIX + id, 0L)
        val target = if (snooze > 0L) snooze else utcMillis(t.deadline)
        if (target == null || target > System.currentTimeMillis()) return
        prefs(c).edit().remove(SNOOZE_PREFIX + id).apply()
        TaskReminderReceiver.show(c, t)
    }

    fun complete(c: Context, id: String) {
        val file = c.getDatabasePath("onelife_ui.db")
        if (!file.exists()) return
        try {
            SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READWRITE).use { db ->
                db.update("tasks", ContentValues().apply { put("completed", 1) },
                    "id=? AND completed=0", arrayOf(id))
            }
            cancel(c, id)
            prefs(c).edit().remove(SNOOZE_PREFIX + id).apply()
            manager(c)?.cancel(id, NOTICE_ID)
            OneLifeHomeWidgetProvider.refresh(c)
        } catch (_: Exception) {
            // Leave the notification visible if persistence failed.
        }
    }

    fun snooze(c: Context, id: String) {
        if (!enabled(c)) return
        val task = task(c, id) ?: return
        if (task.done) return
        val key = SNOOZE_PREFIX + id
        val old = prefs(c).getLong(key, 0L)
        val deadline = if (old > System.currentTimeMillis()) old
            else System.currentTimeMillis() + TEN_MINUTES
        prefs(c).edit().putLong(key, deadline).apply()
        schedule(c, id, deadline)
        manager(c)?.cancel(id, NOTICE_ID)
    }
}
